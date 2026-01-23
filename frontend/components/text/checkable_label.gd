extends Button


var _tween: Tween


func _ready() -> void:
	add_theme_constant_override("icon_max_width", 1)


func _on_toggled(toggled_on: bool) -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_QUINT)
	_tween.set_parallel()
	var final_icon_width: float = 20 if toggled_on else 1
	_tween.tween_property(self, "theme_override_constants/icon_max_width", final_icon_width, 0.3).from(get_theme_constant("icon_max_width"))
