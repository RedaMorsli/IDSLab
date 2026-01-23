extends Page


const GraphNodeSceneMap: Dictionary[String, PackedScene] = {
	'dataset_file_input_node': preload("uid://bck6t5hik3bt5"),
	'dataset_output_node': preload("uid://cfh51nmuk4csp"),
	'dataset_feature_extraction_node': preload("uid://dyvu1mx2yxitf"),
	'dataset_labeling_node': preload("uid://dynijy6xvyvdy")
}

@onready var graph_edit: GraphEditor = %GraphEditor


var dataset: Dataset


func _ready() -> void:
	dataset = DatasetManager.selected_dataset
	title = dataset.dataset_name
	graph_edit.node_scene_map = GraphNodeSceneMap
	if dataset.graph.is_empty():
		dataset.graph = graph_edit.get_data()
	else:
		graph_edit.set_graph(dataset.graph)


func _on_run_button_pressed() -> void:
	DatasetManager.execute_dataset_graph(graph_edit.get_data())


func _on_graph_editor_graph_updated(graph: GraphData) -> void:
	dataset.graph = graph
	DatasetManager.update_dataset(dataset)
