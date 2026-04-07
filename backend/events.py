import db
from typing import List, Dict
from kubernetes.client import ApiException
import yaml
import os
from pathlib import Path
import json
from kubernetes import client as k8s_client, config as k8s_config, utils as k8s_utils
import cluster
import repository


fluent_chart = 'fluent/fluent-bit'
fluent_values_relative_path = './values/fluentbit_values.yaml'
fluent_manifest_relative_path = './collector/fluentbit.yaml'
fluent_event_port = '8888'
fluent_metric_port = '8889'
tracee_manifest_relative_path = './collector/tracee.yaml'
tracee_fluent_address_placeholder = '__FLUENT_ADDRESS__'
tracee_fluent_port_placeholder = '__FLUENT_PORT__'
prom_scraper_manifest_relative_path = './collector/prom_scraper.yaml'
prom_scraper_webhook_placeholder = '__PROM_SCRAPER_WEBHOOK_URL__'

# In-memory store of applied manifests per collector id
# Key: collector_id (int) -> value: list of k8s manifest dicts that were applied
applied_manifests: Dict[int, List[dict]] = {}


async def create_event_filter(args={}):
    filter_name: str = args['filter_name']
    scope_expressions = args['scope_expressions']
    events = args['events']
    metrics = args.get('metrics', '[]')
    db.execute("""
        INSERT INTO CollectorFilters (filter_id, filter_name, scope_expressions, events, metrics)
        VALUES (nextval('seq_filter_id'), ?, ?, ?, ?)
        """, (filter_name, scope_expressions, events, metrics,))
    return {'filter_id': db.get_seq_last_val("seq_filter_id")}


async def get_event_filters(args={}):
    return db.execute_fetch_all("SELECT (filter_id,  filter_name, scope_expressions, events, metrics) FROM CollectorFilters ORDER BY created_at DESC")


async def update_event_filter(args={}):
    filter_id = args['filter_id']
    filter_name = args['filter_name']
    scope_expressions = args['scope_expressions']
    events = args['events']
    metrics = args['metrics']
    db.execute("""
        UPDATE CollectorFilters
        SET filter_name = ?, scope_expressions = ?, events = ?, metrics = ?
        WHERE filter_id = ?
        """, (filter_name, scope_expressions, events, metrics, filter_id,))
    return "Event filter updated successfully"


def _apply_tracee_policy_configmap(
    kubeconfig: str,
    filter_obj: dict,
    collector_id: str,
    namespace: str = "default"
):
    # Load config from dict
    kubeconfig_dict = json.loads(kubeconfig)
    k8s_config.load_kube_config_from_dict(kubeconfig_dict)

    # filter_obj is expected to be a dict with keys: filter_id, filter_name, scope_expressions, events
    filter_name = filter_obj.get('filter_name', '')
    raw_scope = filter_obj.get('scope_expressions', [])
    raw_events = filter_obj.get('events', [])

    # Normalize scope_expressions and events to lists
    def _parse_field(value):
        """Normalize a stored field into a list of clean strings.

        Handles:
        - list input
        - JSON array strings like '["a", "b"]'
        - Python-style repr like "['a', 'b']"
        - single scalar strings, comma-separated values
        - values with extra quotes or bracket wrappers
        """
        def clean_item(s: str) -> str:
            if not isinstance(s, str):
                return str(s)
            s = s.strip()
            # remove outer square brackets if present
            if s.startswith('[') and s.endswith(']'):
                s = s[1:-1].strip()
            # strip surrounding quotes repeatedly (handles doubled quotes)
            while (s.startswith("'") and s.endswith("'")) or (s.startswith('"') and s.endswith('"')):
                s = s[1:-1]
                s = s.strip()
            return s

        if isinstance(value, list):
            return [clean_item(v) for v in value if (v is not None and str(v).strip() != '')]
        if value is None or value == "":
            return []
        # Try JSON first
        if isinstance(value, str):
            txt = value.strip()
            try:
                parsed = json.loads(txt)
                if isinstance(parsed, list):
                    return [clean_item(v) for v in parsed if (v is not None and str(v).strip() != '')]
            except Exception:
                # not JSON; continue
                pass

            # If it looks like a python list repr or contains commas, split on commas
            # Remove outer brackets if present, then split
            if txt.startswith('[') and txt.endswith(']'):
                inner = txt[1:-1]
                parts = [p for p in [p.strip() for p in inner.split(',')] if p != '']
                return [clean_item(p) for p in parts]

            if ',' in txt:
                parts = [p for p in [p.strip() for p in txt.split(',')] if p != '']
                return [clean_item(p) for p in parts]

            # Single value, possibly wrapped in quotes/brackets
            return [clean_item(txt)]

        # Fallback: coerce to string
        return [clean_item(str(value))]

    scope_expressions = _parse_field(raw_scope)
    if "container" not in scope_expressions:
        scope_expressions.append("container")
    events = _parse_field(raw_events)

    configmap_name = "collector" + collector_id + "-tracee-policy"

    # Build Tracee policy content
    policy = {
        "apiVersion": "tracee.aquasec.com/v1beta1",
        "kind": "Policy",
        "metadata": {
            "name": configmap_name,
            "annotations": {"description": "Generated Tracee policy"},
        },
        "spec": {
            "scope": scope_expressions,
            "rules": [{"event": e} for e in events],
        },
    }

    # Convert to YAML string for ConfigMap
    policy_yaml = yaml.safe_dump(policy, sort_keys=False)

    # Create ConfigMap object (include event-collector-id label for lifecycle tracking)
    cm_body = k8s_client.V1ConfigMap(
        metadata=k8s_client.V1ObjectMeta(
            name=configmap_name,
            namespace=namespace,
            labels={"event-collector-id": collector_id},
        ),
        data={"policy.yml": policy_yaml},
    )

    v1 = k8s_client.CoreV1Api()

    # Apply: replace if exists, create otherwise
    try:
        v1.read_namespaced_config_map(configmap_name, namespace)
        v1.replace_namespaced_config_map(configmap_name, namespace, cm_body)
        print(f"Updated ConfigMap '{configmap_name}' in namespace '{namespace}'.")
    except ApiException as e:
        if e.status == 404:
            v1.create_namespaced_config_map(namespace, cm_body)
            print(f"Created ConfigMap '{configmap_name}' in namespace '{namespace}'.")
        else:
            raise RuntimeError(
                f"Kubernetes API error ({e.status}): {e.reason}\n{e.body}"
            ) from e

    # Also return a manifest dict representing the created ConfigMap so callers can store it
    cm_doc = {
        "apiVersion": "v1",
        "kind": "ConfigMap",
        "metadata": {"name": configmap_name, "namespace": namespace, "labels": {"event-collector-id": collector_id}},
        "data": {"policy.yml": policy_yaml},
    }

    return configmap_name, cm_doc


async def get_collectors(args={}):
    # Fetch collectors from DB and append a 'state' flag indicating whether
    # the collector has applied manifests stored in-memory (1) or not (0).
    rows = db.execute_fetch_all(
        "SELECT collector_id, collector_name, cluster_id, filter_id, repository_id FROM Collectors ORDER BY created_at DESC"
    )

    result = []
    for row in rows:
        # duckdb may return a single composite column as a tuple in some metrics
        if len(row) == 1 and isinstance(row[0], tuple):
            row = row[0]

        collector_id = row[0]
        # Determine runtime state by consulting the cluster (pods) rather than in-memory applied_manifests
        try:
            state_info = await get_collector_state({'collector_id': collector_id})
            state = state_info.get('state', 0)
        except Exception:
            # If we cannot determine state (missing cluster/kubeconfig or API error), fall back to 0
            state = 0

        # Return a tuple matching the earlier shape plus the new state field
        result.append((collector_id, row[1], row[2], row[3], row[4], state))

    return result


async def get_actif_collectors(args={}):
    """Return only active collectors based on the in-memory `applied_manifests` store.

    The returned list has the same shape as `get_collectors` (collector_id, collector_name,
    cluster_id, filter_id, repository_id, state) but filtered to include only collectors
    whose id exists in `applied_manifests` (state == 1).
    """
    # If no active collectors, return empty list quickly
    active_ids = list(applied_manifests.keys())
    if not active_ids:
        return []

    # Query DB for matching collectors; build parameter placeholders
    placeholders = ",".join(["?" for _ in active_ids])
    sql = f"SELECT collector_id, collector_name, cluster_id, filter_id, repository_id FROM Collectors WHERE collector_id IN ({placeholders}) ORDER BY created_at DESC"
    rows = db.execute_fetch_all(sql, tuple(active_ids))

    result = []
    seen_ids = set()
    for row in rows:
        if len(row) == 1 and isinstance(row[0], tuple):
            row = row[0]
        cid = row[0]
        seen_ids.add(cid)
        # state is 1 because we only selected active ids
        result.append((cid, row[1], row[2], row[3], row[4], 1))

    # There is a chance some ids are present in applied_manifests but not in DB
    # (e.g., transient state). Include them with empty metadata and state=1.
    missing = [cid for cid in active_ids if cid not in seen_ids]
    for cid in missing:
        result.append((cid, None, None, None, None, 1))

    return result


async def get_event_filter(args={}):
    """Retrieve an event filter by id from the database.

    args: { 'filter_id': int }
    Returns a dict: { filter_id, filter_name, scope_expressions, events }
    """
    filter_id = args.get('filter_id')
    if filter_id is None:
        raise ValueError("'filter_id' is required in args")

    rows = db.execute_fetch_all(
        "SELECT filter_id, filter_name, scope_expressions, events, metrics FROM CollectorFilters WHERE filter_id = ?;",
        (filter_id,),
    )
    if not rows:
        return None
    # duckdb returns tuples; unpack the first row
    row = rows[0]
    # row may be a single composite column depending on SQL; handle both shapes
    if len(row) == 1 and isinstance(row[0], tuple):
        row = row[0]

    res = {
        'filter_id': row[0],
        'filter_name': row[1],
        'scope_expressions': row[2],
        'events': row[3],
        'metrics': row[4],
    }
    return res


# TODO Refactor: extract common functions
async def create_collector(args={}):
    """Create a collector row in the database.

    This function only inserts a row into the `Collectors` table and returns
    the assigned collector_id and name. If `autostart` is True the function
    will immediately attempt to deploy the collector by calling
    `start_collector` and include the start result in the response.

    Expected args: {
        'cluster_id': int,
        'filter_id': int,
        'repository_id': int,
        'collector_name': Optional[str],
        'autostart': Optional[bool]
    }
    """
    cluster_id = args.get('cluster_id')
    filter_id = args.get('filter_id')
    repository_id = args.get('repository_id')
    autostart = bool(args.get('autostart', True))
    collector_id = db.get_seq_current_val('seq_collector_id')
    collector_name = 'collector' + str(collector_id)

    # Insert row using sequence
    db.execute(
        """
        INSERT INTO Collectors (collector_id, collector_name, cluster_id, filter_id, repository_id, start_time, finish_time)
        VALUES (nextval('seq_collector_id'), ?, ?, ?, ?, NULL, NULL)
        """,
        (collector_name, cluster_id, filter_id, repository_id),
    )

    new_id = db.get_seq_last_val('seq_collector_id')

    # If name wasn't provided, assign a default and update row
    if not collector_name:
        collector_name = f"collector{new_id}"
        db.execute("UPDATE Collectors SET collector_name = ? WHERE collector_id = ?", (collector_name, new_id))

    result = {'collector_id': new_id, 'collector_name': collector_name}

    # Optionally start/deploy the collector immediately
    if autostart:
        try:
            start_res = await start_collector({'collector_id': new_id})
            result['started'] = True
            result['start_result'] = start_res
        except Exception as e:
            # Surface start error but don't treat DB insert as failed
            result['started'] = False
            result['start_error'] = str(e)

    return result

async def start_collector(args={}):
    """Start/deploy a collector by collector_id.

    args: { 'collector_id': int }

    This function looks up the collector row to find cluster_id, filter_id and repository_id,
    then retrieves the cluster kubeconfig, the event filter, and the repository S3 bucket
    using the helper functions in `cluster`, `events` and `dataset` modules. It applies
    the Fluent Bit and Tracee manifests and stores the applied manifest dicts in the
    module-level `applied_manifests` store keyed by collector_id.
    """
    collector_id = args.get('collector_id')
    if collector_id is None:
        raise ValueError("'collector_id' is required in args")

    # Before starting, check current runtime state and avoid starting if already running
    try:
        current = await get_collector_state({'collector_id': collector_id})
        if current.get('state') == 1:
            return {"collector_id": collector_id, "collector_name": collector_name, "already_running": True, "state": 1, "pods_total": current.get('pods_total', 0), "details": current.get('details', [])}
    except Exception:
        # If state cannot be determined, proceed with start and let start fail if necessary
        pass

    # Fetch collector metadata from DB
    rows = db.execute_fetch_all(
        "SELECT collector_id, collector_name, cluster_id, filter_id, repository_id FROM Collectors WHERE collector_id = ?;",
        (collector_id,)
    )
    if not rows:
        raise ValueError(f"Collector id {collector_id} not found in DB")

    row = rows[0]
    if len(row) == 1 and isinstance(row[0], tuple):
        row = row[0]

    _, collector_name, cluster_id, filter_id, repository_id = row

    # Retrieve cluster, filter and dataset using helper functions
    if cluster_id is None:
        raise ValueError("collector row missing cluster_id")
    kubeconfig_json = await cluster.get_cluster_config_json(cluster_id)
    if not kubeconfig_json:
        raise ValueError(f"Cluster {cluster_id} has no kubeconfig stored")

    if filter_id is None:
        raise ValueError("collector row missing filter_id")
    flt = await get_event_filter({'filter_id': filter_id})
    if not flt:
        raise ValueError(f"Filter {filter_id} not found")

    if repository_id is None:
        raise ValueError("collector row missing repository_id")
    repo = await repository.get_repository(repository_id)
    if not repo or not repo.get('s3_bucket'):
        raise ValueError(f"Repository {repository_id} has no s3_bucket stored")
    bucket_name = repo.get('s3_bucket')

    # Ensure collector name exists
    if not collector_name:
        collector_name = f"collector{collector_id}"
        db.execute("UPDATE Collectors SET collector_name = ? WHERE collector_id = ?", (collector_name, collector_id))

    # Load kubeconfig into client
    kubeconfig_dict = json.loads(kubeconfig_json)
    k8s_config.load_kube_config_from_dict(kubeconfig_dict)

    applied_docs: List[dict] = []

    # Apply Fluent Bit manifest (replace bucket placeholder)
    fluent_manifest_path = get_path_from_relative(fluent_manifest_relative_path)
    if not os.path.isfile(fluent_manifest_path):
        raise FileNotFoundError(f"Base manifest file not found: {fluent_manifest_path}")

    with open(fluent_manifest_path, 'r', encoding='utf-8') as f:
        content = f.read()


    replaced = content.replace("__COLLECTOR_NAME_", collector_name)
    replaced = replaced.replace('__COLLECTOR_ID__', collector_id.__str__())
    replaced = replaced.replace('__BUCKET__', bucket_name)

    try:
        api_client = k8s_client.ApiClient()
        docs = list(yaml.safe_load_all(replaced))
        for doc in docs:
            if not doc:
                continue
            k8s_utils.create_from_dict(api_client, doc)
            applied_docs.append(doc)
        print(f"Applied Fluent Bit manifest for bucket '{bucket_name}' on collector {collector_id}.")
    except Exception as e:
        raise RuntimeError(f"Failed to apply Fluent Bit manifest: {e}")

    # Create Tracee policy ConfigMap from filter and include its manifest
    configmap_name, cm_doc = _apply_tracee_policy_configmap(kubeconfig_json, flt, collector_id.__str__())
    applied_docs.append(cm_doc)

    # Prepare and apply Tracee manifest
    tracee_manifest_path = get_path_from_relative(tracee_manifest_relative_path)
    if not os.path.isfile(tracee_manifest_path):
        raise FileNotFoundError(f"Base tracee manifest not found: {tracee_manifest_path}")
    with open(tracee_manifest_path, 'r', encoding='utf-8') as f:
        tcontent = f.read()

    fluent_service = "collector" + str(collector_id) + "-flb-service"
    tcontent = tcontent.replace(tracee_fluent_address_placeholder, fluent_service)
    tcontent = tcontent.replace(tracee_fluent_port_placeholder, fluent_event_port)
    tcontent = tcontent.replace('_TRACEE_POLICY_NAME_', configmap_name)
    tcontent = tcontent.replace('__COLLECTOR_ID__', collector_id.__str__())

    try:
        api_client = k8s_client.ApiClient()
        docs = list(yaml.safe_load_all(tcontent))
        for doc in docs:
            if not doc:
                continue
            k8s_utils.create_from_dict(api_client, doc)
            applied_docs.append(doc)
        print(f"Deployed Tracee for collector {collector_id} with webhook '{fluent_service}:{fluent_event_port}'.")
    except Exception as e:
        raise RuntimeError(f"Failed to apply Tracee manifest: {e}")

    # Prepare and apply Prometheus scraper manifest
    prom_scraper_manifest_path = get_path_from_relative(prom_scraper_manifest_relative_path)
    if os.path.isfile(prom_scraper_manifest_path):
        with open(prom_scraper_manifest_path, 'r', encoding='utf-8') as f:
            prom_content = f.read()

        # Replace the webhook URL placeholder with the Fluent Bit service address
        fluent_webhook_url = f"http://{fluent_service}:{fluent_metric_port}"
        prom_content = prom_content.replace(prom_scraper_webhook_placeholder, fluent_webhook_url)
        prom_content = prom_content.replace('__COLLECTOR_ID__', collector_id.__str__())
        prom_content = prom_content.replace('__PROM_METRICS__', flt['metrics'].__str__())

        try:
            api_client = k8s_client.ApiClient()
            docs = list(yaml.safe_load_all(prom_content))
            for doc in docs:
                if not doc:
                    continue
                k8s_utils.create_from_dict(api_client, doc)
                applied_docs.append(doc)
            print(f"Deployed Prometheus scraper for collector {collector_id} with webhook '{fluent_webhook_url}'.")
        except Exception as e:
            raise RuntimeError(f"Failed to apply Prometheus scraper manifest: {e}")
    else:
        print(f"Warning: Prometheus scraper manifest not found at {prom_scraper_manifest_path}, skipping.")

    # Store applied manifests in memory keyed by collector id
    applied_manifests[collector_id] = applied_docs

    return {"collector_id": collector_id, "collector_name": collector_name, "applied": len(applied_docs)}


async def get_collector_state(args={}):
    """Check collector state by listing pods with label event-collector-id=<collector_id>.

    Returns a dict: { collector_id, state, pods_total, details }
    state: 0 = no pod found
           1 = all pods Running
           2 = at least one pod exists but not Running

    Expected args: { 'collector_id': int }
    """
    collector_id = args.get('collector_id')
    if collector_id is None:
        raise ValueError("'collector_id' is required in args")

    # Lookup collector to find the associated cluster
    rows = db.execute_fetch_all(
        "SELECT collector_id, collector_name, cluster_id FROM Collectors WHERE collector_id = ?;",
        (collector_id,)
    )
    if not rows:
        raise ValueError(f"Collector id {collector_id} not found in DB")

    row = rows[0]
    if len(row) == 1 and isinstance(row[0], tuple):
        row = row[0]

    # row shape: (collector_id, collector_name, cluster_id)
    cid = row[0]
    cluster_id = row[2] if len(row) > 2 else None

    if cluster_id is None:
        raise ValueError(f"Collector {collector_id} has no cluster_id configured")

    # Fetch cluster kubeconfig (use helper)
    kubeconfig_json = await cluster.get_cluster_config_json(cluster_id)
    if not kubeconfig_json:
        raise ValueError(f"Cluster {cluster_id} has no kubeconfig stored")

    kubeconfig_dict = json.loads(kubeconfig_json)
    k8s_config.load_kube_config_from_dict(kubeconfig_dict)

    v1 = k8s_client.CoreV1Api()

    label_selector = f"event-collector-id={collector_id}"
    try:
        pods = v1.list_pod_for_all_namespaces(label_selector=label_selector).items
    except Exception as e:
        raise RuntimeError(f"Kubernetes API error listing pods: {e}") from e

    total = len(pods)
    if total == 0:
        return {"collector_id": collector_id, "state": 0, "pods_total": 0, "details": []}

    # Determine if all pods are running
    all_running = True
    details = []
    for p in pods:
        phase = None
        try:
            phase = p.status.phase
        except Exception:
            phase = None
        details.append({
            'name': p.metadata.name,
            'namespace': p.metadata.namespace,
            'phase': phase,
        })
        if phase != 'Running':
            all_running = False

    state = 1 if all_running else 2
    return {"collector_id": collector_id, "state": state, "pods_total": total, "details": details}

    

def get_tracee_release_name(bucket_name) -> str:
    return "tracee-" + bucket_name


def get_path_from_relative(filename: str) -> str:
    """
    Returns the absolute path of a values file located next to this script.
    """
    # directory of the current script
    script_dir = Path(__file__).resolve().parent
    return str(script_dir / filename)


async def stop_collector(args={}):
    """Stop a collector by deleting all resources that were applied for it.

    Expected args:
      - collector_id: int
      - k8s_config_json: str (kubeconfig JSON) -- required to authenticate to cluster

    This function reads the module-level `applied_manifests` store, deletes the resources
    in reverse creation order using the DynamicClient, and removes the entry from the store.
    It returns a dict with details about deleted resources and any errors encountered.
    """
    collector_id = args.get('collector_id')
    if collector_id is None:
        raise ValueError("'collector_id' is required in args")

    # Try to obtain kubeconfig JSON either from args or from the Collectors DB row
    kubeconfig_json = args.get('k8s_config_json')
    if not kubeconfig_json:
        # Lookup collector to find cluster_id
        rows = db.execute_fetch_all(
            "SELECT collector_id, collector_name, cluster_id FROM Collectors WHERE collector_id = ?;",
            (collector_id,)
        )
        if not rows:
            raise ValueError(f"Collector id {collector_id} not found in DB and no kubeconfig provided")
        row = rows[0]
        if len(row) == 1 and isinstance(row[0], tuple):
            row = row[0]
        cluster_id = row[2] if len(row) > 2 else None
        if not cluster_id:
            raise ValueError(f"Collector {collector_id} has no cluster_id configured and no kubeconfig provided")
        kubeconfig_json = await cluster.get_cluster_config_json(cluster_id)
        if not kubeconfig_json:
            raise ValueError(f"Cluster {cluster_id} has no kubeconfig stored")

    # Load kubeconfig
    kubeconfig_dict = json.loads(kubeconfig_json)
    k8s_config.load_kube_config_from_dict(kubeconfig_dict)

    core = k8s_client.CoreV1Api()
    apps = k8s_client.AppsV1Api()
    deleted = []
    errors = []

    label_selector = f"event-collector-id={collector_id}"

    # Helper to delete namespaced resources
    def _delete_namespaced(list_items, delete_func):
        nonlocal deleted, errors
        for item in list_items:
            try:
                name = item.metadata.name
                ns = item.metadata.namespace or 'default'
                delete_func(name=name, namespace=ns)
                deleted.append({'name': name, 'namespace': ns})
            except Exception as e:
                errors.append(f"Failed to delete {getattr(item, 'kind', 'resource')}/{getattr(item.metadata, 'name', '<unknown>')}: {e}")

    # Delete core resources: Pods, Services, ConfigMaps, Secrets
    try:
        pods = core.list_pod_for_all_namespaces(label_selector=label_selector).items
        _delete_namespaced(pods, core.delete_namespaced_pod)
    except Exception as e:
        errors.append(f"Failed listing/deleting pods: {e}")

    try:
        svcs = core.list_service_for_all_namespaces(label_selector=label_selector).items
        _delete_namespaced(svcs, core.delete_namespaced_service)
    except Exception as e:
        errors.append(f"Failed listing/deleting services: {e}")

    try:
        cms = core.list_config_map_for_all_namespaces(label_selector=label_selector).items
        _delete_namespaced(cms, core.delete_namespaced_config_map)
    except Exception as e:
        errors.append(f"Failed listing/deleting configmaps: {e}")

    try:
        secrets = core.list_secret_for_all_namespaces(label_selector=label_selector).items
        _delete_namespaced(secrets, core.delete_namespaced_secret)
    except Exception as e:
        errors.append(f"Failed listing/deleting secrets: {e}")

    # Delete apps resources: Deployments, DaemonSets, StatefulSets
    try:
        deps = apps.list_deployment_for_all_namespaces(label_selector=label_selector).items
        _delete_namespaced(deps, apps.delete_namespaced_deployment)
    except Exception as e:
        errors.append(f"Failed listing/deleting deployments: {e}")

    try:
        dsets = apps.list_daemon_set_for_all_namespaces(label_selector=label_selector).items
        _delete_namespaced(dsets, apps.delete_namespaced_daemon_set)
    except Exception as e:
        errors.append(f"Failed listing/deleting daemonsets: {e}")

    try:
        sts = apps.list_stateful_set_for_all_namespaces(label_selector=label_selector).items
        _delete_namespaced(sts, apps.delete_namespaced_stateful_set)
    except Exception as e:
        errors.append(f"Failed listing/deleting statefulsets: {e}")

    # Best-effort: remove any stored applied_manifests entry
    applied_manifests.pop(collector_id, None)

    return {"collector_id": collector_id, "deleted": deleted, "errors": errors}


async def delete_collector(args={}):
    """Delete a collector record from the DB after ensuring it's stopped.

    Expected args:
      - collector_id: int
    """
    collector_id = args.get('collector_id')
    if collector_id is None:
        raise ValueError("'collector_id' is required in args")

    result = {'collector_id': collector_id, 'deleted': False, 'errors': []}

    state_info = await get_collector_state({'collector_id': collector_id})
    if state_info.get('state', 0) != 0:
        # attempt to stop; pass kubeconfig if provided by caller
        try:
            stop_args = {'collector_id': collector_id}
            stop_res = await stop_collector(stop_args)
        except Exception as e:
            result['errors'].append(f"Failed to stop collector before delete: {e}")

    db.execute("DELETE FROM Collectors WHERE collector_id = ?", (collector_id,))
    result['deleted'] = True

    return result
