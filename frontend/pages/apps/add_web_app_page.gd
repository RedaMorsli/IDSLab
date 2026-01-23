extends Page


func _on_add_app_button_pressed() -> void:
	var address = %AddressEdit.text
	AppManager.add_web_app(%AppNameEdit.text, address, %PortEdit.value)
	request_pop_back.emit()
