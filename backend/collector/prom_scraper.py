"""Prometheus scraper and forwarder.

This script runs in a container and periodically queries a Prometheus server.
It reads the following environment variables:

- PROMETHEUS_URL: base URL of Prometheus, e.g. http://prometheus:9090 (required)
- PROM_METRIC: Python list of metric names (required)
  Format: '[metric1, metric2, metric3]' (e.g., '[container_cpu_load_average_10s, container_memory_rss]')
- INTERVAL_SECONDS: polling interval in seconds (default: 60)
- WEBHOOK_URL: URL to POST successful query results to (required)
- REQUEST_TIMEOUT: HTTP timeout seconds for requests (default: 10)

Behavior:
- For each interval the script executes every configured metric query against the
  Prometheus server using prometheus-api-client. If the query returns a non-empty
  result, it POSTs a JSON payload to the configured webhook with the query,
  timestamp and the returned data.

This is intentionally lightweight and uses prometheus-api-client for reliable
querying and requests for webhook posting.
"""

from __future__ import annotations

import os
import sys
import time
import json
import signal
import logging
import ast
from typing import List, Any, Dict, Optional
from datetime import datetime, timedelta

import requests
from prometheus_api_client import PrometheusConnect

LOG = logging.getLogger("prom_scraper")


def read_env_queries() -> List[str]:
    raw = os.environ.get("PROM_METRICS", "")
    if not raw:
        return []
    
    raw = raw.strip()
    LOG.debug("Raw PROM_METRICS: %s", raw[:100])
    
    # Parse list format: [metric1, metric2, metric3]
    # Simple string parsing: remove brackets and split by comma
    if raw.startswith('[') and raw.endswith(']'):
        raw = raw[1:-1]  # Remove [ and ]
    
    # Split by comma and clean up each metric
    metrics = [m.strip() for m in raw.split(',') if m.strip()]
    
    if metrics:
        LOG.info("Successfully parsed %d metrics: %s", len(metrics), metrics)
        return metrics
    
    return []


def fetch_query(prom_client: PrometheusConnect, query: str, start_time: datetime, end_time: datetime) -> Dict[str, Any]:
	"""Execute a PromQL range query using prometheus-api-client.

	Queries data between start_time and end_time to get only new values since last poll.

	Args:
		prom_client: Prometheus API client
		query: PromQL query string
		start_time: Start of time window (datetime)
		end_time: End of time window (datetime)

	Returns the raw response list (typically containing time series data).
	Raises on query error.
	"""
	# Use custom_query_range to query specific time windows
	# This returns only data points within [start_time, end_time]
	result = prom_client.custom_query_range(query=query, start_time=start_time, end_time=end_time, step=2)
	return result


def post_webhook(webhook: str, payload: Dict[str, Any], timeout: int = 10) -> None:
	headers = {"Content-Type": "application/json"}
	try:
		r = requests.post(webhook, json=payload, headers=headers, timeout=timeout)
		r.raise_for_status()
		LOG.info("Forwarded query result to webhook: %s (status=%s)", webhook, r.status_code)
	except Exception as e:
		LOG.exception("Failed sending webhook for query %s: %s", payload.get('query'), e)


stop_requested = False


def handle_signal(signum, frame):
	global stop_requested
	LOG.info("Received signal %s, stopping...", signum)
	stop_requested = True


def main() -> int:
	logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"))

	prom_url = os.environ.get("PROMETHEUS_URL")
	if not prom_url:
		LOG.error("PROMETHEUS_URL not set")
		return 2

	webhook = os.environ.get("WEBHOOK_URL")
	if not webhook:
		LOG.error("WEBHOOK_URL not set")
		return 2

	queries = read_env_queries()
	if not queries:
		LOG.error("PROM_METRIC not set or empty")
		return 2

	try:
		interval = int(os.environ.get("INTERVAL_SECONDS", "60"))
	except Exception:
		interval = 60

	try:
		timeout = int(os.environ.get("REQUEST_TIMEOUT", "10"))
	except Exception:
		timeout = 10

	LOG.info("Starting prom_scraper: prometheus=%s webhook=%s queries=%d interval=%s", prom_url, webhook, len(queries), interval)

	# Initialize Prometheus API client
	try:
		prom_client = PrometheusConnect(url=prom_url, disable_ssl=False)
	except Exception as e:
		LOG.error("Failed to initialize Prometheus client: %s", e)
		return 2

	signal.signal(signal.SIGTERM, handle_signal)
	signal.signal(signal.SIGINT, handle_signal)

	# Track the last query time to create a sliding window
	last_query_time = datetime.utcnow()

	while not stop_requested:
		start = time.time()
		
		# Define the time window: from last query to now
		# This ensures we only get NEW data since the last interval
		query_start_time = last_query_time
		query_end_time = datetime.utcnow()
		last_query_time = query_end_time
		
		LOG.debug("Querying Prometheus for time window: %s to %s", query_start_time, query_end_time)
		
		for q in queries:
			if stop_requested:
				break
			try:
				LOG.debug("Querying Prometheus: %s", q)
				result = fetch_query(prom_client, q, query_start_time, query_end_time)
			except Exception as e:
				LOG.exception("Prometheus query failed for '%s': %s", q, e)
				continue

			# prometheus-api-client returns a list of metric results directly (or raises on error)
			# Each result is a dict like: {'metric': {...}, 'values': [[timestamp, value_string], ...]}
			if not result:
				LOG.debug("Query returned empty result, skipping webhook: %s", q)
				continue

			payload = {
				'query': q,
				'timestamp': time.time(),
				'time_window': {
					'start': query_start_time.isoformat(),
					'end': query_end_time.isoformat(),
				},
				'prometheus_url': prom_url,
				'result': result,
			}

			post_webhook(webhook, payload, timeout=timeout)

		# Sleep until next interval (account for loop time)
		elapsed = time.time() - start
		to_sleep = interval - elapsed
		if to_sleep <= 0:
			# immediate next cycle
			continue
		# sleep in small increments to be able to handle signals faster
		slept = 0.0
		while slept < to_sleep and not stop_requested:
			step = min(1.0, to_sleep - slept)
			time.sleep(step)
			slept += step

	LOG.info("Stopping prom_scraper")
	return 0


if __name__ == '__main__':
	sys.exit(main())
