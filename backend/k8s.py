from kubernetes import client, config
import base64

def get_secret_value(
    secret_name: str,
    key: str,
    namespace: str,
    default_value: str = None
) -> str:
    try:
        # Load kube config (local or in-cluster)
        config.load_kube_config()
        
        v1 = client.CoreV1Api()
        
        # Read the secret
        secret = v1.read_namespaced_secret(secret_name, namespace)
        
        # Check if key exists
        if key in secret.data:
            # Kubernetes stores secret data as base64
            encoded_value = secret.data[key]
            decoded_value = base64.b64decode(encoded_value).decode("utf-8")
            return decoded_value
        
        return default_value

    except client.exceptions.ApiException:
        return default_value
    except Exception:
        return default_value