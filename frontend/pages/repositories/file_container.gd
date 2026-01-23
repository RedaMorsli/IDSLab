class_name FileContainer
extends FoldableContainer


const FileRow: PackedScene = preload("uid://vkqit18ptkuc")

@onready var files_container: VBoxContainer = %FilesContainer
@onready var files_root: Control = %FilesRoot
@onready var empty_control: VBoxContainer = %EmptyControl
@onready var header: VBoxContainer = %Header


func _ready() -> void:
	header.hide()


var files: Array[File]:
	set(value):
		files = value
		if files.is_empty():
			header.hide()
			return
		for child in files_container.get_children():
			child.queue_free()
		for file in files:
			var file_row: FileRow = FileRow.instantiate()
			file_row.file = file
			files_container.add_child(file_row)
			files_container.add_child(HSeparator.new())
		files_root.visible = not files.is_empty()
		empty_control.visible = files.is_empty()
		header.show()
