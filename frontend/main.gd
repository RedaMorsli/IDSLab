extends CanvasLayer


@export var connectScene = "res://connect.tscn"

@onready var serverUrlLabel: Label = %ServerUrlLabel


func _ready() -> void:
	serverUrlLabel.text = Server.url


func _on_disconnect_button_meta_clicked(meta: Variant) -> void:
	Server.disconnect_from_server()
	get_tree().change_scene_to_file(connectScene)
