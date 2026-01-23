extends Page


@export var PortIntervalRowScene: PackedScene

var port_intervals: Array = []


func _on_create_cluster_button_button_up() -> void:
	var cluster_name = %ClusterNameEdit.text
	var agent_count = %AgentCountSpinBox.value - 1
	ClusterManager.create_k3d_cluster(cluster_name, agent_count, port_intervals)
	request_pop_back.emit()


func _on_add_port_interval_button_pressed() -> void:
	var interval_start = int(%PortStartEdit.text)
	var interval_end = int(%PortEndEdit.text)
	var port_row = PortIntervalRowScene.instantiate()
	port_row.interval_start = interval_start
	port_row.interval_end = interval_end
	%PortIntervalContainer.add_child(port_row)
	%PortIntervalContainer.move_child(port_row, %PortIntervalContainer.get_children().size() - 2)
	port_intervals.append([interval_start, interval_end])
	%PortStartEdit.clear()
	%PortEndEdit.clear()
	print(port_intervals)
