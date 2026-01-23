class_name BreadcrumbItem
extends HBoxContainer


signal breadcrumn_item_pressed(item)

var root: bool = false
var page: Page

@onready var titleLabel: Label = %ItemTitle
@onready var arrowTexture: TextureRect = %ArrowTexture


func _ready() -> void:
	if page:
		titleLabel.text = page.title
	arrowTexture.visible = not root
	page.title_changed.connect(_on_page_title_changed)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_released():
		breadcrumn_item_pressed.emit()


func _on_page_title_changed():
	titleLabel.text = page.title
