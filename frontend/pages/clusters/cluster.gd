class_name Cluster


var cluster_id: int
var cluster_name: String
var config_json: String
var state: String


func _init(p_id: int, p_name: String, p_config: String) -> void:
	cluster_id = p_id
	cluster_name = p_name
	config_json = p_config
