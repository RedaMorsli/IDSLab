class_name EventCollector
extends Resource


@export var id: int

@export var name: String

@export var cluster_id = null

@export var filter_id = null

@export var repository_id = null

@export var state: int


func _init(p_id: int = 0, p_name: String = "", p_cluster_id = null, p_filter_id = null, p_repository_id = null, p_state = 0) -> void:
	id = int(p_id)
	name = p_name
	cluster_id = p_cluster_id
	filter_id = p_filter_id
	repository_id = p_repository_id
	state = p_state
