class_name Repository
extends Node


@export var repository_id: int
@export var repository_name: String
@export var s3_bucket: String


func _init(p_id: int, p_name: String, p_bucket: String) -> void:
	repository_id = p_id
	repository_name = p_name
	s3_bucket = p_bucket
