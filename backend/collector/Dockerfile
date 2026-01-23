FROM python:3.11-slim

# Small image to run the prom scraper script
ENV PYTHONUNBUFFERED=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy any prom scrapper script (prom_scrapper.py or prom_scraper.py) if present
COPY prom*.py /app/
COPY requirements.txt /app/

RUN pip install --no-cache-dir -r requirements.txt

# Default command will run the prom script. The docker image expects an ENTRYPOINT
# which can be overridden by passing a different command. The script will read
# its configuration from environment variables (PROMETHEUS_URL, PROM_QUERIES, etc.).
ENTRYPOINT ["python", "/app/prom_scraper.py"]
