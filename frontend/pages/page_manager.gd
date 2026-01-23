class_name PageManager
extends Control


@export var nav_name: String
@export var pages_catalog: PageCatalog
@export var root_container: Control
@export var root_page: PackedScene
@export var breadcrumb: Breadcrumb

var pages: Array[Page]


func _ready() -> void:
	add_to_group("NavDestinations")
	if root_page:
		push_page(root_page)
	if breadcrumb:
		breadcrumb.request_back_to_page.connect(back_to_page)


func push_page(page_scene: PackedScene):
	if not pages.is_empty():
		pages.back().hide_slide_left()
	var new_page: Page = page_scene.instantiate()
	new_page.request_page.connect(push_page)
	new_page.request_pop_back.connect(pop_page)
	new_page.page_manager = self
	root_container.add_child(new_page)
	new_page.show_slide_left()
	pages.push_back(new_page)
	if breadcrumb:
		breadcrumb.push_item(new_page)


func pop_page():
	if pages.size() <= 1:
		return
	var active_page = pages.pop_back()
	active_page.hide_slide_right()
	pages.back().show_slide_right()
	if breadcrumb:
		breadcrumb.pop_item()
	await active_page.visibility_changed
	active_page.queue_free()


func back_to_root():
	while pages.size() > 1:
		pop_page()


func back_to_page(page: Page):
	while pages.size() > 1 and pages.back() != page:
		pop_page()
