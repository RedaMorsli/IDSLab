class_name App
extends Resource


func _init(p_app_id: int, p_app_name: String, p_cluster_name: String, p_namespaces, p_labels) -> void:
	app_id = p_app_id
	app_name = p_app_name
	cluster_name = p_cluster_name
	var clean_namespaces = p_namespaces.replace("[", '["').replace("]", '"]').replace(", ", '", "')
	namespaces = str_to_var(clean_namespaces)
	var clean_labels = p_labels.replace("'", '"')
	var regex = RegEx.new()
	regex.compile(r'(:\s*)([a-zA-Z0-9_]+)(?=[,\s}])')
	clean_labels = regex.sub(clean_labels, ': "\\2"', true)
	labels = str_to_var(clean_labels)


@export var app_id: int

@export var app_name: String

@export var cluster_name: String

@export var namespaces: Array

@export var labels: Dictionary

@export var resources: Array
