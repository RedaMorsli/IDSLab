class_name LabelNodeItem
extends VBoxContainer


var label: Dictionary:
	set(value):
		label = value
		if not is_node_ready():
			await ready
		column_edit.text = label['column']
		value_edit.text = label['value']
		label_edit.text = label['label']
		for idx in operator_option.item_count:
			if operator_option.get_item_text(idx) == label['operator']:
				operator_option.select(idx)

@onready var column_edit: LineEdit = %ColumnEdit
@onready var operator_option: OptionButton = %OperatorOption
@onready var value_edit: LineEdit = %ValueEdit
@onready var label_edit: LineEdit = %LabelEdit


func get_dict() -> Dictionary:
	return {
		'column': column_edit.text,
		'operator': operator_option.get_item_text(operator_option.selected),
		'value': value_edit.text,
		'label': label_edit.text
	}


func _on_delete_button_pressed() -> void:
	queue_free()
