extends Page


@export var CardRowScene: PackedScene
@export var EventFilterCheckbox: PackedScene

var filter: EventFilter

@onready var nameEdit: LineEdit = %NameEdit
@onready var fieldOptionBtn: OptionButton = %FieldOptionButton
@onready var operatorOptionBtn: OptionButton = %OperatorOptionButton
@onready var valueEdit: LineEdit = %ValueEdit
@onready var scopeContainer: Container = %ScopeContainer
@onready var event_metric_container: GridContainer = %EventMetricContainer
@onready var network_button: FilterCategoryButton = %NetworkButton
@onready var syscall_button: FilterCategoryButton = %SyscallButton
@onready var security_button: FilterCategoryButton = %SecurityButton
@onready var container_button: FilterCategoryButton = %ContainerButton


func _ready() -> void:
	filter = EventManager.selected_event_filter
	
	for field in EventConsts.ExpressionFields.keys():
		fieldOptionBtn.add_item(field)
	fieldOptionBtn.item_selected.connect(_on_field_selected)
	_on_field_selected(0)
	
	_init_network_events()
	
	filter.changed.connect(_update_ui)
	_update_ui()


func _init_network_events():
	_erase_events_metrics()
	for event in EventConsts.NetworkEvents:
		_add_event_metric_checkbox(event)
	_update_counters()


func _init_syscall_events():
	_erase_events_metrics()
	for event in EventConsts.SyscallEvents:
		_add_event_metric_checkbox(event)
	_update_counters()


func _init_security_events():
	_erase_events_metrics()
	for event in EventConsts.SecurityEvents:
		_add_event_metric_checkbox(event)
	_update_counters()


func _init_container_metrics():
	_erase_events_metrics()
	for event in EventConsts.ContainerMetrics.keys():
		_add_event_metric_checkbox(event, false)
	_update_counters()


func _add_event_metric_checkbox(event_name: String, is_event: bool = true):
	var check: Button = EventFilterCheckbox.instantiate()
	check.text = event_name
	if is_event:
		check.button_pressed = event_name in filter.events
	else:
		check.button_pressed = event_name in filter.metrics
	event_metric_container.add_child(check)
	check.toggled.connect(_on_check_toggled.bind(event_name, is_event))


func _on_check_toggled(toggled: bool, event_name, is_event: bool):
	if is_event:
		_on_event_toggled(toggled, event_name)
	else:
		_on_metric_toggled(toggled, event_name)


func _update_counters():
	var net_counter := 0
	var sys_counter := 0
	var sec_counter := 0
	var con_counter := 0
	for event in filter.events:
		if event in EventConsts.NetworkEvents:
			net_counter += 1
		if event in EventConsts.SyscallEvents:
			sys_counter += 1
		if event in EventConsts.SecurityEvents:
			sec_counter += 1 
	con_counter = filter.metrics.size()
	network_button.set_counter(net_counter)
	syscall_button.set_counter(sys_counter)
	security_button.set_counter(sec_counter)
	container_button.set_counter(con_counter)


func _erase_events_metrics():
	for child in event_metric_container.get_children():
		child.queue_free()


func _select_all():
	for check: CheckBox in event_metric_container.get_children():
		if check.button_pressed:
			continue
		check.toggled.disconnect(_on_check_toggled)
		check.button_pressed = true
		if _is_events_selected():
			var event_name = check.text
			filter.events.append(event_name)
			check.toggled.connect(_on_check_toggled.bind(event_name, true))
		else:
			var metric_name = check.text
			filter.metrics.append(metric_name)
			check.toggled.connect(_on_check_toggled.bind(metric_name, false))
	filter.emit_changed()
	_update_counters()


func _unselect_all():
	for check: CheckBox in event_metric_container.get_children():
		if not check.button_pressed:
			continue
		check.toggled.disconnect(_on_check_toggled)
		check.button_pressed = false
		if _is_events_selected():
			var event_name = check.text
			filter.events.erase(event_name)
			check.toggled.connect(_on_check_toggled.bind(event_name, true))
		else:
			var metric_name = check.text
			filter.metrics.erase(metric_name)
			check.toggled.connect(_on_check_toggled.bind(metric_name, false))
	filter.emit_changed()
	_update_counters()


func _on_event_toggled(toggled: bool, event: String):
	if toggled and event not in filter.events:
		filter.events.append(event)
		filter.emit_changed()
	elif event in filter.events and not toggled:
		filter.events.erase(event)
		filter.emit_changed()
	_update_counters()


func _on_metric_toggled(toggled: bool, metric: String):
	if toggled and metric not in filter.metrics:
		filter.metrics.append(metric)
		filter.emit_changed()
	elif metric in filter.metrics and not toggled:
		filter.metrics.erase(metric)
		filter.emit_changed()
	_update_counters()


func _is_events_selected() -> bool:
	if network_button.is_selected() or syscall_button.is_selected() or security_button.is_selected():
		return true
	return false


func _on_field_selected(idx: int):
	var op_list: Array
	match EventConsts.ExpressionFields[fieldOptionBtn.get_item_text(idx)]:
		EventConsts.EXP_FIELD_TYPE_1:
			op_list = EventConsts.ExpressionType1Operators
		EventConsts.EXP_FIELD_TYPE_2:
			op_list = EventConsts.ExpressionType2Operators
	operatorOptionBtn.clear()
	for op in op_list:
		operatorOptionBtn.add_item(op)


func _update_ui():
	var filter_name = EventManager.selected_event_filter.filter_name
	nameEdit.text = filter_name
	title = filter_name
	
	for child in scopeContainer.get_children():
		child.queue_free()
	for exp in filter.scope_expressions:
		_add_scope_card(exp)


func _add_scope_card(scope_expression: String):
	var card: CardRow = CardRowScene.instantiate()
	card.title = scope_expression
	scopeContainer.add_child(card)


func _on_add_scope_button_pressed() -> void:
	if valueEdit.text.is_empty():
		return
	
	var field = fieldOptionBtn.get_item_text(fieldOptionBtn.selected)
	var operator = operatorOptionBtn.get_item_text(operatorOptionBtn.selected)
	var value = valueEdit.text
	var expression = field + operator + value
	filter.scope_expressions.append(expression)
	filter.emit_changed()


func _save_name():
	var new_name = nameEdit.text
	if new_name.is_empty():
		return
	filter.filter_name = new_name


func _on_name_edit_focus_exited() -> void:
	_save_name()


func _on_name_edit_text_submitted(new_text: String) -> void:
	_save_name()
