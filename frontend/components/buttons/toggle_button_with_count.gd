class_name FilterCategoryButton
extends PanelContainer


signal pressed()

@export var title: String
@export var icon: Texture
@export var button_pressed: bool = false

@onready var icon_texture_rect: TextureRect = %IconTextureRect
@onready var title_label: Label = %TitleLabel
@onready var count_label: Label = %CountLabel
@onready var button: Button = $Button


func _ready() -> void:
	if title:
		title_label.text = title
	if icon:
		icon_texture_rect.texture = icon
	button.button_pressed = button_pressed
	
	button.pressed.connect(
		func ():
			pressed.emit()
	)


func set_counter(value: int):
	count_label.text = str(value)


func is_selected() -> bool:
	return button.button_pressed
