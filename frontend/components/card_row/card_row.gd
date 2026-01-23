class_name CardRow
extends Button


signal card_pressed()
signal option_pressed(idx: int)

@export var title: String
@export var options: Array[String]

@onready var titleLabel: Label = %TitleLabel
@onready var menuButton: MenuButton = %MenuButton
@onready var menu: PopupMenu = %MenuButton.get_popup()

var item_id: int
var item: Variant
var hide_menu: bool = false


func _ready() -> void:
	titleLabel.text = title
	menuButton.visible = not hide_menu
	
	for option in options:
		menu.add_item(option)
	
	menu.index_pressed.connect(
		func (idx: int):
			option_pressed.emit(idx)
	)


func _on_pressed() -> void:
	card_pressed.emit()
