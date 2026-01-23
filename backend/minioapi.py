from minio import Minio
from minio.error import S3Error
import re


credentials = {
    "endpoint": "minio:9000",
    "access_key": "minioadmin",
    "secret_key": "minioadmin",
}

client = Minio(
            endpoint=credentials["endpoint"],
            access_key=credentials["access_key"],
            secret_key=credentials["secret_key"],
            secure=False,
        )


async def check_minio_connection(args={}) -> bool:
    try:
        # Try a simple operation to validate the connection
        client.list_buckets()
        return True

    except S3Error as e:
        print(f"MinIO error: {e}")
        return False
    except Exception as e:
        print(f"Connection failed: {e}")
        return False


async def create_bucket(repo_name: str):
    try:     
        bucket_name = sanitize_bucket_name(repo_name)
        # Check if bucket exists
        # if not client.bucket_exists(bucket_name):
        client.make_bucket(bucket_name=bucket_name)
        return bucket_name

    except S3Error as e:
        raise RuntimeError(f"MinIO error: {e}")


async def get_object_content(bucket_name: str, object_path: str):
    response = client.get_object(bucket_name=bucket_name, object_name=object_path)
    try:
        content = response.read().decode("utf-8")
    finally:
        response.close()
        response.release_conn()
    return content


async def list_objects(bucket_name: str, prefix: str):
    return client.list_objects(bucket_name=bucket_name, recursive=True, prefix=prefix)


BUCKET_RE = re.compile(r"^(?!\d+\.\d+\.\d+\.\d+$)[a-z0-9]([a-z0-9-]{1,61})[a-z0-9]$")

def sanitize_bucket_name(desired: str) -> str:
    """Return (sanitized_name, issues). Does not guarantee validity."""
    name = desired.strip().lower()
    if "." in name:
        name = name.replace(".", "-")
    if "_" in name:
        name = name.replace("_", "-")
    name = re.sub(r"[^a-z0-9-]", "-", name)
    name = name.strip("-")
    if len(name) < 3:
        name = f"{name}-xxx"
    if len(name) > 63:
        name = name[:63]
    return name

def is_valid_bucket_name(name: str) -> bool:
    return bool(BUCKET_RE.match(name))
