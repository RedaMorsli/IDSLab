extends Page


@onready var repositoryNameEdit = %RepositoryNameEdit
@onready var confirmButton = %ConfirmButton
@onready var spinner = %Spinner


func _ready() -> void:
	spinner.hide()
	confirmButton.show()
	RepositoryManager.repository_creation_succeeded.connect(
		func():
			request_pop_back.emit()
	)
	RepositoryManager.repository_creation_failed.connect(
		func():
			spinner.hide()
			confirmButton.show()
	)


func _on_confirm_button_pressed() -> void:
	if not repositoryNameEdit.text.is_empty():
		spinner.hide()
		confirmButton.show()
		RepositoryManager.create_repository(repositoryNameEdit.text)


func _on_back_button_pressed() -> void:
	request_pop_back.emit()
