extends Page


@onready var inputContainer = %InputContainer
@onready var loadingContainer = %LoadingContainer


func _ready() -> void:
	inputContainer.show()
	loadingContainer.hide()
	get_window().files_dropped.connect(
		func (files):
			_on_file_selected(files[0])
	)
	ClusterManager.cluster_add_succeeded.connect(
		func ():
			request_pop_back.emit()
	)
	ClusterManager.cluster_add_failed.connect(
		func ():
			inputContainer.show()
			loadingContainer.hide()
	)


func _on_file_selected(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		ClusterManager.add_cluster(content)
		file.close()
	#if file_path.ends_with('yaml'):
		#ClusterManager.add_cluster(file_path)


func _on_file_label_meta_clicked(meta: Variant) -> void:
	%ClusterFileDialog.add_filter("*.yaml")
	%ClusterFileDialog.popup()


func _on_cluster_file_dialog_file_selected(path: String) -> void:
	_on_file_selected(path)


func _on_back_button_pressed() -> void:
	request_pop_back.emit()
