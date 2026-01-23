extends Page


const CardRowScene: PackedScene = preload("uid://dy543vxtsc8ex")

@onready var collectorContainer: Container = %CollectorContainer


func _ready() -> void:
	EventManager.event_collectors_fetched.connect(_update_collectors)
	_update_collectors()


func _on_new_collection_button_pressed() -> void:
	request_page.emit(page_manager.pages_catalog.CreateEventCollectorPage)


func _update_collectors():
	for child in collectorContainer.get_children():
		child.queue_free()
	for collector in EventManager.collectors:
		var card: CardRow = CardRowScene.instantiate()
		card.item = collector
		card.title = collector.name
		collectorContainer.add_child(card)


func _on_refresh_button_pressed() -> void:
	EventManager.fetch_event_collectors()
