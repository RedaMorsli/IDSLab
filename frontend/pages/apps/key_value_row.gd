class_name KeyValueRow
extends HBoxContainer


signal delete_button_pressed()

var key: String
var value: String


func _ready() -> void:
	if key:
		$KeyLabel.text = key
	if value:
		$ValueLabel.text = value


func _on_delete_row_button_button_up() -> void:
	delete_button_pressed.emit()
