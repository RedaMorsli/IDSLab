class_name Dataset
extends Resource


@export var dataset_id: int
@export var dataset_name: String
@export var graph: GraphData


func _init(id: int, p_name: String, p_graph = null) -> void:
	dataset_id = id
	dataset_name = p_name
	graph = GraphData.new(str_to_var(p_graph)) if p_graph else GraphData.new({})
	
	


func get_dict() -> Dictionary:
	return {
		"dataset_id": dataset_id,
		"dataset_name": dataset_name,
		"dataset_graph": graph.to_dict()
	}
