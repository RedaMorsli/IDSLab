extends Button


var app: App
var running_resources: int:
	set(value):
		running_resources = value
		if %ResourceLabel:
			%ResourceLabel.text = str(running_resources)


func _ready() -> void:
	if app.app_name:
		%NameLabel.text = app.app_name
	if running_resources:
		%ResourceLabel.text = str(running_resources)
	AppManager.app_resources_fetched.connect(
			func (fetched_app_name, resources):
				if fetched_app_name == app.app_name:
					running_resources = resources
	)
	
	var menu: PopupMenu = %MenuButton.get_popup()
	menu.id_pressed.connect(
		func (id: int):
			match id:
				0: # Delete
					AppManager.delete_app(app)
	)
