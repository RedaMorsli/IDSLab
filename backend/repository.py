import db
import minioapi
from shutil import which



async def create_repository(args={}) -> str:
    repository_name = args['repository_name']
    bucket_name = await minioapi.create_bucket(repository_name)
    db.execute("""
        INSERT INTO Repositories (repository_id, repository_name, s3_bucket)
        VALUES (nextval('seq_repository_id'), ?, ?)
        """, (repository_name, bucket_name,))
    return repository_name + " created."


async def get_repositories(args={}) -> list:
    return db.execute_fetch_all("SELECT (repository_id, repository_name, s3_bucket) FROM Repositories ORDER BY created_at DESC")


async def get_repository(repository_id: int) -> dict:
    if repository_id is None:
        raise ValueError("'repository_id' is required in args")

    rows = db.execute_fetch_all(
        "SELECT repository_id, repository_name, s3_bucket FROM Repositories WHERE repository_id = ?;",
        (repository_id,)
    )
    if not rows:
        return None

    row = rows[0]
    if len(row) == 1 and isinstance(row[0], tuple):
        row = row[0]

    return {
        'repository_id': row[0],
        'repository_name': row[1],
        's3_bucket': row[2],
    }

async def delete_repository(args={}):
    db.execute("DELETE FROM Repositories WHERE repository_id = ?", (args['repository_id'],))


async def get_event_files(args={}) -> list:
    return await _get_files(args['repository_id'], "events/")


async def get_metric_files(args={}) -> list:
    return await _get_files(args['repository_id'], "metrics/")


async def _get_files(repository_id: int, prefix: str) -> list:
    repository = await get_repository(repository_id)
    if repository is None:
        raise ValueError("Repository not found")

    bucket_name = repository['s3_bucket']

    objects = await minioapi.list_objects(bucket_name, prefix)
    events = [(obj.object_name, obj.last_modified.__str__(), obj.size) for obj in objects]
    return events
