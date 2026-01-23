extends Node

signal connecting
signal connected
signal disconnecting
signal disconnected
signal request_completed(request_id: int, status: String)


var _socket : WebSocketPeer = WebSocketPeer.new()
var _last_socket_state : WebSocketPeer.State = WebSocketPeer.STATE_CLOSED
var url: String
var error: String

var _request_id_counter : int = 0
var _pending_responses : Dictionary = {}


func _ready() -> void:
	_socket.inbound_buffer_size = 100000000
	set_process(false)


func connect_to_server(url: String):
	var error = _socket.connect_to_url(url)
	if error != OK:
		return
	set_process(true)
	Server.url = url


func disconnect_from_server():
	_socket.close()


func _process(delta):
	_socket.poll()
	var state = _socket.get_ready_state()
	if state != _last_socket_state:
		_on_socket_state_changed(state)
	if state == WebSocketPeer.STATE_OPEN:
		while _socket.get_available_packet_count():
			_handle_packet(_socket.get_packet())
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = _socket.get_close_code()
		var reason = _socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) # Stop processing.


func send_command(command: String, args = {}, status_message:String = "", finish_callback = null, progress_callback = null):
	var request_id = _request_id_counter
	_request_id_counter += 1
	
	var payload = {
		"request_id": request_id,
		"command": command,
		"args": args
	}
	
	_pending_responses[request_id] = {}
	
	if finish_callback:
		_pending_responses[request_id]['finish_callback'] = finish_callback
	
	if progress_callback:
		_pending_responses[request_id]['progress_callback'] = progress_callback
	
	if _last_socket_state == WebSocketPeer.STATE_CLOSED:
		await connected
	_socket.send_text(JSON.stringify(payload))
	print("Request ", request_id, " sent")
	RequestStatus.queue_request(request_id, status_message, command)


func _handle_packet(packet: PackedByteArray):
	if _socket.was_string_packet():
		var data = JSON.parse_string(packet.get_string_from_utf8())
		
		if not data:
			print("Invalid JSON received.")
			return
		
		var request_id : int = data.get("request_id", null)
		var status = data['status']
		match status:
			'ok':
				if request_id != null and request_id in _pending_responses:
					var callback = _pending_responses[request_id]['finish_callback']
					callback.call(data)
					_pending_responses.erase(request_id)
					print("[Server] Request ", request_id, " answered")
			'progress':
				if request_id != null and request_id in _pending_responses:
					var callback = _pending_responses[request_id]['progress_callback']
					callback.call(data)
			'error':
				if request_id != null and request_id in _pending_responses:
					var callback = _pending_responses[request_id]['finish_callback']
					callback.call(data)
				print('Error request ' + str(request_id) + ": " + data['message'])
		request_completed.emit(request_id, status)
	else:
		print("[Server] Received non string reponse")


func _on_socket_state_changed(new_state: WebSocketPeer.State):
	_last_socket_state = new_state
	if new_state == WebSocketPeer.STATE_CONNECTING:
		#print("WebSocket connecting...")
		connecting.emit()
	elif new_state == WebSocketPeer.STATE_OPEN:
		#print("WebSocket opened")
		connected.emit()
	elif new_state == WebSocketPeer.STATE_CLOSING:
		#print("WebSocket closing...")
		disconnecting.emit()
	elif new_state == WebSocketPeer.STATE_CLOSED:
		#print("WebSocket closed")
		var code = _socket.get_close_code()
		var reason = _socket.get_close_reason()
		error = "error code %d, reason %s, clean: %s" % [code, reason, code != -1]
		disconnected.emit()
