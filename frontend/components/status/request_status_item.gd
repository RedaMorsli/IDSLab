class_name RequestStatusItem
extends Control


const ANIM_EASE = Tween.EASE_OUT
const ANIM_TRANS = Tween.TRANS_SINE
const ANIM_DURATION = 0.3
const HIDE_TIMEOUT = 3

var request_id: int
var message: String
var command: String

@onready var loading_texture: TextureRect = %LoadingTexture
@onready var complete_texture: TextureRect = %CompleteTexture
@onready var fail_texture: TextureRect = %FailTexture
@onready var request_execution_message: Label = %RequestExecutionMessage


func _ready() -> void:
	complete_texture.hide()
	fail_texture.hide()
	if message:
		request_execution_message.text = message


func complete():
	loading_texture.hide()
	complete_texture.show()
	destroy()


func fail():
	loading_texture.hide()
	fail_texture.show()
	request_execution_message.set("theme_override_colors/font_color", Color(0.937, 0.267, 0.267))
	destroy()


func destroy():
	await get_tree().create_timer(HIDE_TIMEOUT).timeout
	var tween = create_tween()
	tween.set_ease(ANIM_EASE)
	tween.set_trans(ANIM_TRANS)
	tween.set_parallel()
	tween.tween_property(self, "modulate:a", 0, ANIM_DURATION)
	await tween.finished
	queue_free()
