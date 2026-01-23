@abstract
class_name GenericGraphNode
extends GraphNode


signal node_updated()

@export var node_id: int
@export var node_name: String


@abstract func get_params() -> Dictionary

@abstract func set_params(params: Dictionary)


func _save():
	node_updated.emit()
