extends Page


@export var cardRow: PackedScene

@onready var repositoryContainer = %RepositoryContianer


func _ready() -> void:
	RepositoryManager.repositories_fetched.connect(
		func(repositories: Array[Repository]):
			_update_repositories()
	)
	_update_repositories()


func _update_repositories():
	for child in repositoryContainer.get_children():
		child.queue_free()
	
	for repository in RepositoryManager.repositories:
		var repository_row: CardRow = cardRow.instantiate()
		repository_row.title = repository.repository_name
		repository_row.item_id = repository.repository_id
		repository_row.options.append('Delete')
		repository_row.card_pressed.connect(
			func ():
				page_manager.requested_repository_idx = RepositoryManager.repositories.find(repository)
				request_page.emit(page_manager.pages_catalog.RepositoryPage)
		)
		repository_row.option_pressed.connect(
			func(option_idx: int):
				match option_idx:
					0:
						RepositoryManager.delete_repository(repository)
		)
		repositoryContainer.add_child(repository_row)


func _on_new_repository_button_pressed() -> void:
	request_page.emit(page_manager.pages_catalog.CreateRepositoriesPage)
