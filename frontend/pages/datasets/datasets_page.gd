extends Page


const DatasetDialogScene = preload("uid://cpipmt6bj8vgb")
const CardScene = preload("uid://cp1t62qrn47xp")

@onready var dataset_contianer: VBoxContainer = %DatasetContianer


func _ready() -> void:
	DatasetManager.datasets_fetched.connect(_on_datasets_fetched)
	_update_ui()


func _update_ui():
	for child in dataset_contianer.get_children():
		child.queue_free()
	for dataset in DatasetManager.datasets:
		var card: CardRow = CardScene.instantiate()
		card.item = dataset
		card.title = dataset.dataset_name
		card.options = ["Delete"]
		card.option_pressed.connect(
			func(index: int):
				match index:
					0:
						DatasetManager.delete_dataset(card.item)
		)
		card.pressed.connect(
			func ():
				DatasetManager.selected_dataset = card.item
				request_page.emit(page_manager.pages_catalog.DatasetEditorPage)
		)
		dataset_contianer.add_child(card)


func _on_datasets_fetched():
	_update_ui()


func _on_new_dataset_button_pressed() -> void:
	Dialog.popup("New Dataset", DatasetDialogScene)
