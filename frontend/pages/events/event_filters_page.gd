extends Page


@export var CardRowScene: PackedScene

@onready var filterContainer: Container = %FilterContainer


func _ready() -> void:
	EventManager.event_filters_fetched.connect(_update_filters)
	_update_filters()


func _update_filters():
	for child in filterContainer.get_children():
		child.queue_free()
	for filter in EventManager.filters:
		var card: CardRow = CardRowScene.instantiate()
		card.item = filter
		card.title = filter.filter_name
		filterContainer.add_child(card)
		card.card_pressed.connect(
			func ():
				EventManager.selected_event_filter = filter
				request_page.emit(page_manager.pages_catalog.EventFilterEditPage)
		)


func _on_new_event_filter_button_pressed() -> void:
	var filter = EventFilter.new()
	EventManager.create_event_filter(filter)
	EventManager.selected_event_filter = filter
	request_page.emit(page_manager.pages_catalog.EventFilterEditPage)
