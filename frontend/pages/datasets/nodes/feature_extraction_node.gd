extends GenericGraphNode


@export var features: Array[String]

var _selected_features: Array

@onready var feature_container: Container = %FeatureContainer


func get_params() -> Dictionary:
	_selected_features.clear()
	for check: CheckBox in feature_container.get_children():
		if check.button_pressed:
			_selected_features.append(check.text)
	return {
		'features': _selected_features
	}


func set_params(params: Dictionary):
	_selected_features.clear()
	_selected_features = params['features']


func _ready() -> void:
	for feature in features:
		var check = CheckBox.new()
		check.text = feature
		check.button_pressed = feature in _selected_features
		check.toggled.connect(_on_feature_toggled)
		feature_container.add_child(check)


func _on_feature_toggled(toggled_on: bool):
	_save()
