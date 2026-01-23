import os
import yaml
import db
from kubernetes import client, config
from kubernetes.client.rest import ApiException
import json


async def get_clusters(args={}) -> list:
    return db.execute_fetch_all("SELECT (cluster_id, cluster_name, config_json) FROM Clusters ORDER BY created_at DESC")


async def get_cluster(args={}) -> dict:
    """Return a single cluster by id.

    args: { 'cluster_id': int }
    Returns dict with keys: cluster_id, cluster_name, config_json or None if not found.
    """
    cluster_id = args.get('cluster_id')
    if cluster_id is None:
        raise ValueError("'cluster_id' is required in args")

    rows = db.execute_fetch_all(
        "SELECT cluster_id, cluster_name, config_json FROM Clusters WHERE cluster_id = ?;",
        (cluster_id,)
    )
    if not rows:
        return None

    row = rows[0]
    if len(row) == 1 and isinstance(row[0], tuple):
        row = row[0]

    return {
        'cluster_id': row[0],
        'cluster_name': row[1],
        'config_json': row[2],
    }


async def add_cluster(args={}) -> str:
    config_yaml = yaml.safe_load(args['config_yaml'])
    config_json = json.dumps(config_yaml)
    cluster_name = get_cluster_name_from_json(config_yaml)
    db.execute("""
        INSERT INTO Clusters (cluster_id, cluster_name, config_json)
        VALUES (nextval('seq_cluster_id'), ?, ?)
        """, (cluster_name, config_json,))
    return cluster_name + " added."


async def delete_cluster(args={}):
    db.execute("DELETE FROM Clusters WHERE cluster_id = ?", (args['cluster_id'],))


async def check_cluster_connection(args={}) -> bool:
    try:
        # Load kubeconfig from the provided file path
        config.load_kube_config_from_dict(json.loads(args['config_json']))
        
        # Create an API client
        v1 = client.CoreV1Api()
        
        # Attempt to list namespaces to verify connection
        v1.list_namespace()
        
        print("Kubernetes connection successful.")
        return True

    except ApiException as e:
        print(f"Kubernetes API exception: {e}")
        return False
    except Exception as e:
        print(f"Connection failed: {e}")
        return False


def extract_name_from_kubeconfig(kubeconfig_path, default_name="default"):
    """Extract cluster name from the kubeconfig file."""
    if not os.path.exists(kubeconfig_path):
        return default_name
    with open(kubeconfig_path, 'r') as f:
        kubeconfig = yaml.safe_load(f)
    # Assuming the name is in kubeconfig['clusters'][0]['name']
    try:
        return kubeconfig['clusters'][0]['name']
    except (KeyError, IndexError, TypeError):
        return default_name

def get_cluster_name_from_json(kubeconfig_dict):
    current_context_name = kubeconfig_dict.get("current-context")
    contexts = kubeconfig_dict.get("contexts", [])

    for ctx in contexts:
        if ctx["name"] == current_context_name:
            return ctx["context"]["cluster"]

    return 'Unnamed cluster'


async def get_cluster_config_json(cluster_id: int):
    """Return the stored kubeconfig JSON for a cluster id, or None if not found.

    Args:
        cluster_id: integer cluster id

    Returns:
        config_json string or None
    """
    if cluster_id is None:
        raise ValueError("'cluster_id' is required")

    # Reuse existing helper
    cluster = await get_cluster({'cluster_id': cluster_id})
    if not cluster:
        return None
    return cluster.get('config_json')