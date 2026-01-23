class_name OutputDatasetNode
extends GenericGraphNode


@onready var file_label: RichTextLabel = %FileLabel
@onready var file_dialog: FileDialog = %FileDialog

var _bytes = null


func get_params() -> Dictionary:
	return {}


func set_params(params: Dictionary):
	pass


func _ready() -> void:
	DatasetManager.dataset_ready.connect(_on_dataset_ready)
	DatasetManager.downloaded_file_ready.connect(_on_downloaded_file_ready)


func _on_dataset_ready(file_name):
	file_label.text = "[color=2563eb][url][img color=2563eb]uid://ckystscdknaye[/img] " + file_name + "[/url]"


func _on_file_label_meta_clicked(meta: Variant) -> void:
	DatasetManager.download_dataset()


func _on_downloaded_file_ready(file_name, bytes):
	file_dialog.current_file = file_name
	file_dialog.popup()
	_bytes = bytes


func _on_file_path_selected(path):
	var f = FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer(_bytes)
	f.close()
	_bytes = null
	print("Saved CSV to ", path)


func _on_file_dialog_canceled() -> void:
	_bytes = null
