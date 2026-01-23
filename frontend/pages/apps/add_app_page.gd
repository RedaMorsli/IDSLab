extends Page


@export var CheckableLabelScene: PackedScene
@export var KeyValueRowScene: PackedScene

var _selected_namespaces: Array[String] = []
var _labels: Dictionary = {}


func _ready() -> void:
	ClusterManager.namespaces_fetched.connect(_on_namespaces_fetched)
	if ClusterManager.clusters.is_empty():
		return
	for cluster in ClusterManager.clusters:
		%ClusterOption.add_item(cluster.cluster_name)
	_on_cluster_option_item_selected(0)


func _on_cluster_option_item_selected(index: int) -> void:
	var cluster_name = %ClusterOption.get_item_text(index)
	ClusterManager.list_namespaces_by_cluster(cluster_name)


func _on_namespaces_fetched(namespaces):
	for child in %NamespaceContainer.get_children():
		child.hide()
		child.queue_free()
	for ns in namespaces:
		var ns_label: Button = CheckableLabelScene.instantiate()
		ns_label.text = ns
		ns_label.toggled.connect(
			func (toggle_on):
				if toggle_on:
					_selected_namespaces.append(ns)
				else:
					_selected_namespaces.erase(ns)
		)
		%NamespaceContainer.add_child(ns_label)


func _on_add_label_button_button_up() -> void:
	var key = %LabelKeyEdit.text
	var value = %LabelValueEdit.text
	if key == "" or value == "":
		return
	var label: KeyValueRow = KeyValueRowScene.instantiate()
	label.key = key
	label.value = value
	_labels[key] = value
	label.delete_button_pressed.connect(
		func ():
			_labels.erase(key)
			label.hide()
			label.queue_free()
	)
	%LabelKeyEdit.text = ""
	%LabelValueEdit.text = ""
	%LabelContainer.add_child(label)
	%LabelContainer.move_child(label, %LabelContainer.get_children().size() - 2)


func _on_add_app_button_button_up() -> void:
	var app_name = %AppNameEdit.text
	var cluster_name = %ClusterOption.get_item_text(%ClusterOption.selected)
	AppManager.add_app(app_name, cluster_name, _selected_namespaces, _labels)
	request_pop_back.emit()
