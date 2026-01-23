extends Page


var _repository: Repository

@onready var container: VBoxContainer = %Container
@onready var file_containers = [%EventFileContainer, %MetricFileContainer]
@onready var event_file_container: FileContainer = %EventFileContainer
@onready var metric_file_container: FileContainer = %MetricFileContainer


func _ready() -> void:
	_repository = RepositoryManager.repositories[page_manager.requested_repository_idx]
	if _repository:
		title = _repository.repository_name
	RepositoryManager.event_files_fetched.connect(_on_event_files_fetched)
	RepositoryManager.metric_files_fetched.connect(_on_metric_files_fetched)
	RepositoryManager.fetch_event_files(_repository)
	RepositoryManager.fetch_metric_files(_repository)


func _on_start_button_pressed() -> void:
	RepositoryManager.start_repository_collection(_repository)


func _on_event_files_fetched(files: Array[File]):
	event_file_container.files = files


func _on_metric_files_fetched(files: Array[File]):
	metric_file_container.files = files


func _on_file_container_folding_changed(is_folded: bool) -> void:
	for container: FoldableContainer in file_containers:
		if container.folded:
			container.set("size_flags_vertical", SIZE_SHRINK_BEGIN)
		else:
			container.set("size_flags_vertical", SIZE_EXPAND_FILL)
