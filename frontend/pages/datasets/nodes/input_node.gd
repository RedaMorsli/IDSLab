class_name InputDatasetNode
extends GenericGraphNode




@onready var type_option_button: OptionButton = %TypeOptionButton
@onready var repo_option_button: OptionButton = %RepoOptionButton
@onready var file_container: Container = %FileContainer


var _files: Array[File] = []
var _checked_files_names: Array = []
var _selected_repo: int = 0


func get_params() -> Dictionary:
	var repo_name = repo_option_button.get_item_text(repo_option_button.selected)
	var file_names: Array[String]
	for check: CheckBox in file_container.get_children():
		if check.button_pressed:
			var file_path = check.text
			if file_path.begins_with('events'):
				file_path = file_path.insert(0, "events/")
			file_names.append(file_path)
	var repo = RepositoryManager.get_repository_by_name(repo_name)
	var bucket = repo.s3_bucket if repo else ""
	return {
		"bucket_name": bucket,
		"file_pahts": file_names
	}


func set_params(params: Dictionary):
	var bucket_name = params['bucket_name']
	_checked_files_names = params['file_pahts']
	for i in RepositoryManager.repositories.size():
		if RepositoryManager.repositories[i].s3_bucket == bucket_name:
			_selected_repo = i


func _ready() -> void:
	_load_repositories()
	RepositoryManager.event_files_fetched.connect(_on_files_fetched)


func _load_repositories():
	for repo in RepositoryManager.repositories:
		repo_option_button.add_item(repo.repository_name)
	_select_repo(_selected_repo)


func _select_repo(index: int):
	if not RepositoryManager.repositories.is_empty():
		repo_option_button.select(index)
		RepositoryManager.fetch_event_files(RepositoryManager.repositories[index])


func _clear_files():
	for child in file_container.get_children():
		child.queue_free()
	_files.clear()


func _on_files_fetched(files: Array[File]):
	_clear_files()
	_files = files
	for file in _files:
		var check = CheckBox.new()
		check.text = file.file_name.split("/")[-1]
		check.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		check.button_pressed = file.file_name in _checked_files_names
		check.toggled.connect(_on_file_toggled)
		file_container.add_child(check)


func _on_file_toggled(toggled_on: bool):
	_save()


func _on_repo_option_button_item_selected(index: int) -> void:
	_save()
	RepositoryManager.fetch_event_files(RepositoryManager.repositories[index])
