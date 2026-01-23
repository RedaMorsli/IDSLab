extends HBoxContainer


var cluster: Cluster


func _ready() -> void:
	if cluster:
		%ClusterName.text = cluster.cluster_name
		ClusterManager.check_cluster_connection(cluster)
		ClusterManager.cluster_connection_checked.connect(
			func (connected: bool):
				%Status.text = "connected" if connected else "disconnected"
		)


func _on_delete_button_button_up() -> void:
	ClusterManager.delete_cluster(cluster)
