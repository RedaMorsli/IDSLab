extends HBoxContainer


var interval_start: int
var interval_end: int


func _ready() -> void:
	if interval_start:
		$PortStart.text = str(interval_start)
	if interval_end:
		$PortEnd.text = str(interval_end)
