extends CanvasLayer


@export var mainScene: PackedScene

@onready var urlEdit: LineEdit = %UrlEdit
@onready var connectButton: Button = %ConnectButton
@onready var loadingSpinner: Control = %LoadingSpinner
@onready var errorLabel: Label = %ErrorLabel


func _ready() -> void:
	loadingSpinner.hide()
	errorLabel.text = ""
	Server.connecting.connect(
		func ():
			print('Connecting to ' + Server.url + " ...")
			connectButton.hide()
			loadingSpinner.show()
	)
	
	
	Server.connected.connect(
		func ():
			print("Connected to " + Server.url + "")
			get_tree().change_scene_to_packed(mainScene)
	)
	
	Server.disconnected.connect(
		func ():
			print("Disconnected.")
			connectButton.show()
			loadingSpinner.hide()
			errorLabel.show()
			errorLabel.text = "Failed to connect to the server (" + Server.error + ")"
	)


func _on_connect_button_pressed() -> void:
	var url = urlEdit.text
	Server.connect_to_server(url)
