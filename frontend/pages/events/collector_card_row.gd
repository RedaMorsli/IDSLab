extends CardRow


var collector: EventCollector

@onready var status_label: Label = %StatusLabel
@onready var start_button: Button = %StartButton
@onready var stop_button: Button = %StopButton


func _ready() -> void:
	if not item or not item is EventCollector:
		return
	collector = item as EventCollector
	
	match collector.state:
		0: # Stopped
			status_label.text = "Stopped"
			start_button.show()
			stop_button.hide()
		1: # Running
			status_label.text = "Running"
			start_button.hide()
			stop_button.show()
		2: # Error
			status_label.text = "Error"
			start_button.hide()
			stop_button.show()
	
	options = ['Delete']
	option_pressed.connect(
		func (idx):
			if idx == 0: # Delete
				EventManager.delete_collector(collector)
	)
	
	super()


func _on_start_button_pressed() -> void:
	EventManager.start_collector(collector)


func _on_stop_button_pressed() -> void:
	EventManager.stop_collector(collector)
