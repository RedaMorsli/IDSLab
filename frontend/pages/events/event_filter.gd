class_name EventFilter
extends Resource


@export var filter_id: int
@export var filter_name: String:
	set(value):
		filter_name = value
		emit_changed()
@export var scope_expressions: Array = []
@export var events: Array = []
@export var metrics: Array = []


func _init(p_id: int = 0, p_name: String = "", p_scopes= [], p_events = [], p_metrics = "") -> void:
	filter_id = int(p_id)
	filter_name = p_name
	scope_expressions = StringUtils.str_to_array(p_scopes) if p_scopes is String else p_scopes
	events = StringUtils.str_to_array(p_events) if p_events is String else p_events
	changed.connect(_on_changed)
	#p_metrics = JSON.parse_string(p_metrics)
	#if p_metrics:
		#for query: String in p_metrics:
			#metrics.append(query.replace('"', ''))
	metrics = StringUtils.str_to_array(p_metrics) if p_metrics is String else p_metrics


func _on_changed():
	EventManager.update_event_filter(self)
