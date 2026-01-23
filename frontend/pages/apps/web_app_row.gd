extends Button


var app: WebApp
var menu: PopupMenu 


func _ready() -> void:
	menu = %MenuButton.get_popup()
	if app.app_name:
		%NameLabel.text = app.app_name
	if app.address:
		var address = app.address
		if not address.begins_with('http'):
			address = address.insert(0, "http://")
		if app.port:
			address += ":" + str(app.port)
		%AddressLabel.text = "[url]" + address + "[img color=#2563eb]res://assets/icons/redirect.png[/img][/url]"
	
	menu.id_pressed.connect(
		func (id: int):
			match id:
				0: # Delete
					AppManager.delete_web_app(app)
	)


func _on_address_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))
