import cluster
import app
import attacks
import repository
import events
import minioapi
import dataset

COMMANDS = {
    "add_cluster": cluster.add_cluster,
    "get_clusters": cluster.get_clusters,
    "delete_cluster": cluster.delete_cluster,
    "check_cluster_connection": cluster.check_cluster_connection,
    "get_namespaces_by_cluster": app.get_namespaces_by_cluster,
    "get_resources_by_app": app.get_resources_by_app,
    "add_app": app.add_app,
    "get_apps": app.get_apps,
    "delete_app": app.delete_app,
    "add_web_app": app.add_web_app,
    "get_web_apps": app.get_web_apps,
    "delete_web_app": app.delete_web_app,
    "dos_slowloris": attacks.dos_slowloris,
    "create_repository": repository.create_repository,
    "get_repositories": repository.get_repositories,
    "delete_repository": repository.delete_repository,
    "create_collector": events.create_collector,
    "create_event_filter": events.create_event_filter,
    "get_event_filters": events.get_event_filters,
    "update_event_filter": events.update_event_filter,
    "get_collectors": events.get_collectors,
    "get_actif_collectors": events.get_actif_collectors,
    "stop_collector": events.stop_collector,
    "start_collector": events.start_collector,
    "delete_collector": events.delete_collector,
    "check_minio_connection": minioapi.check_minio_connection,
    "get_event_files": repository.get_event_files,
    "get_metric_files": repository.get_metric_files,
    "create_dataset": dataset.create_dataset,
    "get_datasets": dataset.get_datasets,
    "delete_dataset": dataset.delete_dataset,
    'execute_dataset_graph': dataset.execute_dataset_graph,
    'download_dataset': dataset.download_dataset,
    'update_dataset': dataset.update_dataset,
}

async def dispatch(command, args={}):
    if command not in COMMANDS:
        return {"request_id": args['request_id'], "status": "error", "message": f"Unknown command: {command}"}

    try:
        result = await COMMANDS[command](args or {})
        return {"request_id": args['request_id'], "status": "ok", "data": result}
    except Exception as e:
        return {"request_id": args['request_id'], "status": "error", "message": str(e)}
