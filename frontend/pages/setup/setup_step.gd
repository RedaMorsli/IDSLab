class_name SetupStep
extends PanelContainer


signal updated()

var title: String
var description: String
var complete_condition: Callable
var primary_action: Callable
var primarty_action_title: String

var completed: bool = false
var folded: bool = true:
	set(value):
		folded = value
		details.visible = false if folded else true
var checking: bool = false

@onready var check_box: Button = %CheckBox
@onready var details: VBoxContainer = %Details
@onready var title_label: Label = %Title
@onready var description_label: Label = %Description
@onready var primary_button: Button = %PrimaryButton


func _ready() -> void:
	details.hide()
	_update_ui()


func _update_ui():
	title_label.text = title
	description_label.text = description
	primary_button.pressed.connect(primary_action)
	primary_button.text = primarty_action_title
	checking = true
	completed = await complete_condition.call()
	checking = false
	check_box.theme_type_variation = "SetupCheckBoxChecked" if completed else "SetupCheckBoxUnchecked"
	updated.emit()
