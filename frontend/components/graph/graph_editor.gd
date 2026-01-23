class_name GraphEditor
extends GraphEdit


signal graph_updated(graph: GraphData)

var node_scene_map: Dictionary[String, PackedScene]
var _update_timer_active: bool = false
var _loaded_scroll_offset


func _ready() -> void:
	connection_request.connect(_on_connection_request)
	disconnection_request.connect(_on_disconnection_request)
	end_node_move.connect(_on_end_node_move)
	scroll_offset_changed.connect(_on_scroll_offset_changed)
	for child in get_children():
		_on_child_added(child)
	child_entered_tree.connect(_on_child_added)


func set_graph(graph: GraphData):
	_load(graph)


func get_data() -> GraphData:
	var graph_data = GraphData.new({})
	graph_data.scroll_offset = scroll_offset
	graph_data.zoom = zoom
	var id_count = 0
	var graph_connections: Array[Dictionary] = get_connection_list()
	for node in get_children():
		if node is not GenericGraphNode:
			continue
		var node_data = NodeData.new(
			id_count,
			node.node_name,
			node.position_offset,
			node.get_params()
		)
		id_count += 1
		for cnx: Dictionary in graph_connections:
			if cnx['from_node'] is StringName and cnx['from_node'].get_file() == node.name:
				cnx['from_node'] = node_data.id
			if cnx['to_node'] is StringName and cnx['to_node'].get_file() == node.name:
				cnx['to_node'] = node_data.id
		graph_data.nodes.append(node_data)
	graph_data.connections = graph_connections
	return graph_data


func _load(p_graph: GraphData):
	_clear()
	for node in p_graph.nodes:
		var node_scene: GenericGraphNode = node_scene_map[node.name].instantiate()
		node_scene.position_offset = node.offset
		node_scene.node_id = node.id
		node_scene.set_params(node.params)
		add_child(node_scene)
	for cnx in p_graph.connections:
		connect_node(
			_get_node_name_by_id(cnx['from_node']),
			cnx['from_port'],
			_get_node_name_by_id(cnx['to_node']),
			cnx['to_port']
		)
	await get_tree().process_frame
	zoom = p_graph.zoom
	await get_tree().process_frame
	scroll_offset = p_graph.scroll_offset


func _save():
	graph_updated.emit(get_data())


func _clear():
	for child in get_children():
		if child is GraphNode:
			child.free()
	connections.clear()


func _get_node_name_by_id(id: int) -> StringName:
	for node in get_children():
		if node is GenericGraphNode and node.node_id == id:
			return node.name
	return ""


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	connect_node(from_node, from_port, to_node, to_port)
	_save()


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	disconnect_node(from_node, from_port, to_node, to_port)
	_save()


func _on_child_added(node: Node):
	if not node is GenericGraphNode:
		return
	node.node_updated.connect(_save)


func _on_scroll_offset_changed(offset: Vector2):
	if _update_timer_active:
		return
	_update_timer_active = true
	await get_tree().create_timer(1).timeout
	_update_timer_active = false
	_save()


func _on_end_node_move() -> void:
	_save()
