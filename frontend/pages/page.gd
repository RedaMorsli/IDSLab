class_name Page
extends Control

signal title_changed()

const ANIM_DURATION = 0.3
const SLIDE_RANGE = 20
const ANIM_EASE = Tween.EASE_OUT
const ANIM_TRANS = Tween.TRANS_QUINT

signal request_page(page_scene: PackedScene)
signal request_pop_back()

@export var title: String:
	set(value):
		title = value
		title_changed.emit()

var page_manager: PageManager


func show_slide_left():
	var tween = create_tween()
	tween.set_ease(ANIM_EASE)
	tween.set_trans(ANIM_TRANS)
	tween.set_parallel()
	tween.tween_property(self, "position", Vector2.ZERO, ANIM_DURATION).from(Vector2(SLIDE_RANGE, 0))
	tween.tween_property(self, "modulate:a", 1, ANIM_DURATION).from(0)
	show()


func hide_slide_left():
	var tween = create_tween()
	tween.set_ease(ANIM_EASE)
	tween.set_trans(ANIM_TRANS)
	tween.set_parallel()
	tween.tween_property(self, "position", Vector2(-SLIDE_RANGE, 0), ANIM_DURATION)
	tween.tween_property(self, "modulate:a", 0, ANIM_DURATION).from(1)
	await tween.finished
	hide()


func show_slide_right():
	var tween = create_tween()
	tween.set_ease(ANIM_EASE)
	tween.set_trans(ANIM_TRANS)
	tween.set_parallel()
	tween.tween_property(self, "position", Vector2.ZERO, ANIM_DURATION).from(Vector2(-SLIDE_RANGE, 0))
	tween.tween_property(self, "modulate:a", 1, ANIM_DURATION).from(0)
	show()


func hide_slide_right():
	var tween = create_tween()
	tween.set_ease(ANIM_EASE)
	tween.set_trans(ANIM_TRANS)
	tween.set_parallel()
	tween.tween_property(self, "position", Vector2(SLIDE_RANGE, 0), ANIM_DURATION)
	tween.tween_property(self, "modulate:a", 0, ANIM_DURATION).from(1)
	await tween.finished
	hide()
