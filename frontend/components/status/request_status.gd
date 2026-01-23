extends CanvasLayer


const RequestStatusItemScene: PackedScene = preload("uid://cfxkf5slu5kqx")

var pending_requests: Dictionary[int, RequestStatusItem] = {}

@onready var request_item_container: VBoxContainer = %RequestItemContainer


func _ready() -> void:
	Server.request_completed.connect(_on_request_completed)


func queue_request(request_id: int, message: String, command: String) -> void:
	if message.is_empty():
		return
	var request_item: RequestStatusItem = RequestStatusItemScene.instantiate()
	request_item.set_meta("request_id", request_id)
	request_item.request_id = request_id
	request_item.message = message
	request_item.command = command
	request_item_container.add_child(request_item)
	pending_requests[request_id] = request_item


func is_request_pending(command: String) -> bool:
	for request: RequestStatusItem in pending_requests.values():
		if request.command == command:
			return true
	return false


func _on_request_completed(request_id: int, status: String) -> void:
	if not request_id in pending_requests:
		return
	for item: RequestStatusItem in pending_requests.values():
		if item.request_id == request_id:
			match status:
				'ok':
					item.complete()
				'error':
					item.fail()
	pending_requests.erase(request_id)
