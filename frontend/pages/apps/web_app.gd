class_name WebApp
extends Resource


func _init(p_app_id: int, p_app_name: String, p_address: String, p_port: int) -> void:
	app_id = p_app_id
	app_name = p_app_name
	address = p_address
	port = p_port


@export var app_id: int

@export var app_name: String

@export var address: String

@export var port: int
