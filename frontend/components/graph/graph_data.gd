class_name GraphData
extends Resource


@export var nodes: Array[NodeData]
@export var connections: Array
@export var scroll_offset: Vector2 = Vector2.ZERO
@export var zoom: float = 1.0


func _init(graph_dict: Dictionary) -> void:
	if graph_dict.is_empty():
		nodes = []
		connections = []
		return
	for node in graph_dict['nodes']:
		nodes.append(NodeData.new.callv(node.values()))
	connections = graph_dict['connections']
	scroll_offset = str_to_var(graph_dict['scroll_offset'])
	zoom = graph_dict['zoom']


func to_dict() -> Dictionary:
	var nodes_str = []
	for node in nodes:
		nodes_str.append(node.to_dict())
	return {
		'nodes': nodes_str,
		'connections': connections,
		'scroll_offset': var_to_str(scroll_offset),
		'zoom': zoom
	}


func is_empty():
	return nodes.is_empty()
