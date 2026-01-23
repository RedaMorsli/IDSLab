from kubernetes import client, config
import db


async def get_namespaces_by_cluster(args={}) -> list:
    context_name = "k3d-" + args['cluster_name']
    try:
        config.load_kube_config(context=context_name)

        v1 = client.CoreV1Api()
        ns_list = v1.list_namespace()
        return [ns.metadata.name for ns in ns_list.items]

    except Exception as e:
        raise RuntimeError(f"Failed to load context '{context_name}': {str(e)}")


async def get_resources_by_app(args={}) -> list:
    try:
        cluster_context = "k3d-" + args['cluster_name']
        namespaces = args['namespaces']
        labels = args['labels']
        config.load_kube_config(context=cluster_context)
        label_selector = ",".join(f"{k}={v}" for k, v in labels.items())

        core_v1 = client.CoreV1Api()
        apps_v1 = client.AppsV1Api()

        if len(namespaces) == 0:
            ns_response = core_v1.list_namespace()
            namespaces = [ns.metadata.name for ns in ns_response.items]

        resources = []

        for ns in namespaces:
            pods = core_v1.list_namespaced_pod(namespace=ns, label_selector=label_selector)
            for pod in pods.items:
                pod.metadata.kind = "pod"
            resources.extend(pods.items)
            deployments = apps_v1.list_namespaced_deployment(namespace=ns, label_selector=label_selector)
            for deployment in deployments.items:
                deployment.metadata.kind = "deployment"
            resources.extend(deployments.items)
            services = core_v1.list_namespaced_service(namespace=ns, label_selector=label_selector)
            for service in services.items:
                service.metadata.kind = "service"
            resources.extend(services.items)

        # return {"running_resources": len(resources)}
        return [
            {
                "name": r.metadata.name,
                "namespace": r.metadata.namespace,
                "labels": r.metadata.labels,
                "kind": r.metadata.kind,
                "created_at": str(r.metadata.creation_timestamp)
            }
            for r in resources
        ]

    except Exception as e:
        raise RuntimeError(f"Error while fetching resources: {str(e)}")


async def add_app(args={}) -> str:
    db.execute("""
        INSERT INTO Applications (app_id, app_name, cluster_name, namespaces, labels)
        VALUES (nextval('seq_app_id'), ?, ?, ?, ?)
        """, (args['app_name'], args['cluster_name'], args['namespaces'], args['labels'],))
    return args['app_name'] + " application created."


async def get_apps(args={}) -> list:
    return db.execute_fetch_all("SELECT (app_id, app_name, cluster_name, namespaces, labels) FROM Applications ORDER BY created_at DESC")


async def delete_app(args={}):
    db.execute("DELETE FROM Applications WHERE app_id = ?", (args['app_id'],))


async def add_web_app(args={}) -> str:
    db.execute("""
        INSERT INTO WebApplications (app_id, app_name, address, port)
        VALUES (nextval('seq_web_app_id'), ?, ?, ?)
        """, (args['app_name'], args['address'], args['port'],))
    return args['app_name'] + " web application created."


async def get_web_apps(args={}) -> list:
    return db.execute_fetch_all("SELECT (app_id, app_name, address, port) FROM WebApplications ORDER BY created_at DESC")


async def delete_web_app(args={}):
    db.execute("DELETE FROM WebApplications WHERE app_id = ?", (args['app_id'],))