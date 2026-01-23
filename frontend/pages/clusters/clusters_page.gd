extends Page


@export var ClusterRowScene: PackedScene

@onready var clusterTable = %ClusterTable
@onready var clusterContainer = %ClusterContainer
@onready var emptyMessage = %EmptyMessage


func _ready() -> void:
	clusterTable.hide()
	emptyMessage.show()
	ClusterManager.clusters_fetched.connect(_on_clusters_fetched)
	_update_clusters()


func _update_clusters():
	for child in clusterContainer.get_children():
		child.queue_free()
	for cluster in ClusterManager.clusters:
		var cluster_row = ClusterRowScene.instantiate()
		cluster_row.cluster = cluster
		clusterContainer.add_child(cluster_row)
		if ClusterManager.clusters.find(cluster) < ClusterManager.clusters.size() - 1:
			var separator : HSeparator = HSeparator.new()
			var stylebox = separator.get_theme_stylebox("separator").duplicate()
			stylebox.grow_begin = -8
			stylebox.grow_end = -8
			stylebox.color = Color(0.898, 0.906, 0.922)
			separator.add_theme_stylebox_override("separator", stylebox)
			clusterContainer.add_child(separator)
	clusterTable.visible = not ClusterManager.clusters.is_empty()
	emptyMessage.visible = ClusterManager.clusters.is_empty()


func _on_clusters_fetched():
	_update_clusters()


func _on_add_cluster_button_pressed() -> void:
	request_page.emit(page_manager.pages_catalog.AddClusterPage)
