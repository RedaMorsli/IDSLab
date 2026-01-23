class_name NodeData
extends Resource


@export var id: int
@export var name: String
@export var offset: Vector2
@export var params = {}


func _init(p_id, p_name, p_offset, p_params) -> void:
	id = p_id
	name = p_name
	offset = p_offset if p_offset is Vector2 else str_to_var(p_offset)
	params = p_params


func to_dict() -> Dictionary:
	return {
		"node_id": id,
		"node_name": name,
		"offset": var_to_str(offset),
		"params": params
	}
