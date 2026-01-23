class_name FileRow
extends PanelContainer


var file: File

@onready var name_label: Label = %NameLabel
@onready var last_modified_label: Label = %LastModifiedLabel
@onready var size_label: Label = %SizeLabel


func _ready() -> void:
	if not file:
		return
	name_label.text = file.file_name.split('/')[-1]
	last_modified_label.text = file.get_last_modified_str()
	size_label.text = file.get_size_str()
