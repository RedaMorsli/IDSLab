extends Control


@export var destination_container: Control
@export var nav_items: Array[NavButton]


func _ready() -> void:
	for item in nav_items:
		var nav_item = item as Button
		nav_item.pressed.connect(_on_nav_item_toggled.bind(item.nav_name))
	Navigation.page_requested.connect(_on_page_requested)


func _on_nav_item_toggled(nav_name: String):
	var instanciated_destinations = get_tree().get_nodes_in_group("NavDestinations")
	var destination_is_instanciated = false
	for destination in instanciated_destinations:
		if destination.nav_name == nav_name:
			if not destination.visible:
				destination.show()
			destination_is_instanciated = true
		elif destination.visible:
			destination.hide()

	if destination_is_instanciated:
		return

	var destination_scene: PackedScene
	for item in nav_items:
		if item.nav_name == nav_name:
			destination_scene = item.nav_scene
	if not destination_scene:
		print("Navigation destination scene not found.")
		return
	var destination = destination_scene.instantiate()
	destination_container.add_child(destination)


func _get_page_manager(nav_name: String) -> PageManager:
	for manager: PageManager in destination_container.get_children():
		if manager.nav_name == nav_name:
			return manager
	return null


func _on_page_requested(nav_name: String, page: PackedScene):
	for item: NavButton in nav_items:
		if item.nav_name == nav_name:
			item.button_pressed = true
			_on_nav_item_toggled(nav_name)
			var manager = _get_page_manager(nav_name)
			manager.back_to_root()
			if page:
				manager.push_page(page)
