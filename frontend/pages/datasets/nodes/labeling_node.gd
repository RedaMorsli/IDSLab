extends GenericGraphNode


const LabelItemScene: PackedScene = preload("uid://cjwsww4emcedu")

@onready var labels_container: VBoxContainer = %LabelsContainer


func get_params() -> Dictionary:
	var labels = []
	for label:LabelNodeItem in labels_container.get_children():
		labels.append(label.get_dict())
	return {
		'labels': labels
	}


func set_params(params: Dictionary):
	var labels: Array = params['labels'] if params.has('labels') else []
	if labels.is_empty():
		return
	await ready
	labels_container.get_child(0).label = labels[0]
	labels.remove_at(0)
	for label in labels:
		add_label_item(label)


func add_label_item(label = null) -> void:
	var item: LabelNodeItem = LabelItemScene.instantiate()
	if label:
		item.label = label
	item.tree_exited.connect(_on_label_deleted)
	labels_container.add_child(item)


func _on_label_deleted():
	size.y = 0
