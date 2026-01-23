class_name Breadcrumb
extends Control


signal request_back_to_page(page: Page)

@export var BreadcumbItemScene: PackedScene
@export var item_container: Container

var items: Array[BreadcrumbItem]


func push_item(page: Page):
	var new_item: BreadcrumbItem = BreadcumbItemScene.instantiate()
	new_item.page = page
	new_item.breadcrumn_item_pressed.connect(
		func ():
			request_back_to_page.emit(page)
	)
	new_item.root = items.is_empty()
	item_container.add_child(new_item)
	items.push_back(new_item)


func pop_item():
	var last_item: BreadcrumbItem = items.pop_back()
	last_item.hide()
	last_item.queue_free()
