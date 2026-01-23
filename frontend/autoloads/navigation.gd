extends Node


signal page_requested(nav_name: String, page: PackedScene)


func go_to_page(nav_name: String, page: PackedScene = null):
	page_requested.emit(nav_name, page)
