extends Page


func _on_attack_1_pressed() -> void:
	request_page.emit(page_manager.pages_catalog.DosPage)
