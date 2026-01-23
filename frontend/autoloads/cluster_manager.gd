extends Node


signal clusters_fetched()
signal cluster_add_succeeded()
signal cluster_add_failed()
signal clusters_changed()
signal cluster_connection_checked(connected)
signal namespaces_fetched(namespaces)

var clusters: Array[Cluster] = []


func _ready() -> void:
	fetch_clusters()


func fetch_clusters():
	Server.send_command("get_clusters", {
	}, "Fetching clusters",
	 func (response):
		var fetched_clusters = response['data']
		clusters.clear()
		for cluster in fetched_clusters:
			clusters.append(Cluster.new.callv(cluster[0]))
		clusters_fetched.emit()
		)


func add_cluster(config_yaml: String):
	Server.send_command("add_cluster", {
		"config_yaml": config_yaml
	}, "Adding cluster",
	 func (response):
		match response['status']:
			'ok':
				cluster_add_succeeded.emit()
				fetch_clusters()
			_:
				cluster_add_failed.emit()
		)


func check_cluster_connection(cluster: Cluster):
	Server.send_command("check_cluster_connection", {
		"config_json": cluster.config_json
	}, "",
	 func (response):
		cluster_connection_checked.emit(response['data'])
		)


func list_namespaces_by_cluster(cluster_name: String):
	Server.send_command("list_namespaces_by_cluster", {
		"cluster_name": cluster_name
	}, "Fetching namespaces from cluster \'" + cluster_name + "\'",
	 func (fetched_namespaces):
		namespaces_fetched.emit(fetched_namespaces)
		)


func delete_cluster(cluster: Cluster):
	Server.send_command("delete_cluster", {
		"cluster_id": cluster.cluster_id
	}, "Deleting cluster \'" + cluster.cluster_name + "\'",
	 func (response):
		fetch_clusters()
		)
