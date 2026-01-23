class_name ParameterUI
extends HBoxContainer


signal value_changed(value)

@export var parameter: Parameter

@onready var paramNameLabel: Label = %ParamName
@onready var numberValueSpin: SpinBox = %NumberValue
@onready var boolValueCheck: CheckBox = %BoolValue


func _ready() -> void:
	paramNameLabel.text = parameter.param_name
	paramNameLabel.tooltip_text = parameter.description
	match parameter.type:
		Parameter.ParamType.NUMBER:
			numberValueSpin.visible = true
			numberValueSpin.value = parameter.default_value[0]
		Parameter.ParamType.BOOL:
			boolValueCheck.visible = true
			boolValueCheck.button_pressed = parameter.default_value[0]


func _value_changed(value):
	value_changed.emit(value)
