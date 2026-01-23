extends VBoxContainer


@onready var name_line_edit: LineEdit = %NameLineEdit
@onready var create_button: Button = %CreateButton


func create_dataset():
	if name_line_edit.text.is_empty():
		return
	create_button.disabled = true
	DatasetManager.create_dataset(name_line_edit.text)
	DatasetManager.dataset_creation_succeeded.connect(
		func ():
			queue_free()
	)
	DatasetManager.dataset_creation_failed.connect(
		func ():
			create_button.disabled = false
	)


func _on_create_button_pressed() -> void:
	create_dataset()


func _on_name_line_edit_text_changed(new_text: String) -> void:
	create_button.disabled = new_text.is_empty()


func _on_name_line_edit_text_submitted(new_text: String) -> void:
	create_dataset()
