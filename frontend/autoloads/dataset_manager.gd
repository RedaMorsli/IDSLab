extends Node


signal dataset_creation_succeeded
signal dataset_creation_failed
signal datasets_fetched()
signal dataset_ready(file_name)
signal downloaded_file_ready(file_name, content)


var datasets: Array[Dataset] = []
var selected_dataset: Dataset


func _ready() -> void:
	fetch_datasets()


func create_dataset(dataset_name: String):
	Server.send_command("create_dataset",
	{"dataset_name": dataset_name},
	"Creating dataset \'" + dataset_name + "\'",
	func (reponse):
		match reponse['status']:
			'ok':
				dataset_creation_succeeded.emit()
				fetch_datasets()
			_:
				dataset_creation_failed.emit()
		)


func fetch_datasets():
	Server.send_command("get_datasets", {},
		"Fetching datasets",
		func (reponse):
			var p_datasets: Array = reponse['data']
			datasets.clear()
			for dataset in p_datasets:
				datasets.append(Dataset.new.callv(dataset[0]))
			datasets_fetched.emit()
	)


func delete_dataset(repo: Dataset):
	Server.send_command("delete_dataset",
	{"dataset_id": repo.dataset_id},
	"Deleting dataset \'" + repo.dataset_name + "\'",
	func (reponse):
		match reponse['status']:
			'ok':
				fetch_datasets()
			_:
				pass
		)


func update_dataset(dataset: Dataset):
	Server.send_command("update_dataset",
	dataset.get_dict(),
	"Saved",
	func (reponse):
		match reponse['status']:
			'ok':
				pass
			_:
				pass
		)


func execute_dataset_graph(graph: GraphData):
	var graph_dict = graph.to_dict()
	Server.send_command("execute_dataset_graph",
	{
		"nodes": graph_dict['nodes'], 
		"connections": graph_dict['connections'], 
		"dataset_name": selected_dataset.dataset_name
	},
	"Running dataset",
	func (reponse):
		match reponse['status']:
			'ok':
				var file_name = reponse.data['file_name']
				dataset_ready.emit(file_name)
			_:
				pass
		)


func download_dataset():
	var dataset_name = selected_dataset.dataset_name
	Server.send_command("download_dataset",
	{
		"dataset_name": dataset_name
	},
	"Downloading dataset " + dataset_name,
	func (reponse):
		match reponse['status']:
			'ok':
				var bytes = Marshalls.base64_to_raw(reponse.data["csv_base64"])
				downloaded_file_ready.emit(
					reponse.data['file_name'], 
					bytes)
			_:
				pass
		)
	
