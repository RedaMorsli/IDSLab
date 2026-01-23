extends Node


signal event_filters_fetched()
signal event_collectors_fetched()
signal collector_created()

var filters: Array[EventFilter]
var collectors: Array[EventCollector]
var selected_event_filter: EventFilter


func _ready() -> void:
	fetch_event_filters()
	fetch_event_collectors()


func create_event_filter(filter: EventFilter):
	Server.send_command("create_event_filter",
	{"filter_name": filter.filter_name, 
	"scope_expressions": filter.scope_expressions, 
	"events": filter.events,
	"metrics": filter.metrics}, 
	"Creating new event filter",
	func (args):
		var filter_id = args.data['filter_id']
		filter.filter_id = filter_id
		filter.filter_name = "filter" + str(filter.filter_id)
		)


func fetch_event_filters():
	Server.send_command("get_event_filters", null, 
	"Fetching event filters",
	func (reponse):
		var p_filters = reponse.data
		filters.clear()
		for filter in p_filters:
			filters.append(EventFilter.new.callv(filter[0]))
		event_filters_fetched.emit()
		)


func update_event_filter(filter: EventFilter):
	Server.send_command("update_event_filter",
	{"filter_id": filter.filter_id, 
	"filter_name": filter.filter_name, 
	"scope_expressions": filter.scope_expressions, 
	"events": filter.events,
	"metrics": filter.metrics}, 
	"Updating event filter '" + filter.filter_name + "",
	func (args):
		fetch_event_filters()
		)


func fetch_event_collectors():
	Server.send_command("get_collectors", null, 
	"Fetching event collectors",
	func (reponse):
		var p_collectors = reponse.data
		collectors.clear()
		for collector in p_collectors:
			collectors.append(EventCollector.new.callv(collector))
		event_collectors_fetched.emit()
		)


func create_collector(cluster: Cluster, filter: EventFilter, repository: Repository, autostart: bool):
	Server.send_command("create_collector",
	{"cluster_id": cluster.cluster_id, "filter_id": filter.filter_id, "repository_id": repository.repository_id, "autostart": autostart},
	"Creating collector for \'" + repository.repository_name + "\' repository",
	func (reponse):
		match reponse['status']:
			'ok':
				fetch_event_collectors()
				event_collectors_fetched.emit()
			_:
				pass
		)


func start_collector(collector: EventCollector):
	Server.send_command("start_collector",
	{"collector_id": collector.id},
	"Starting collector \'" + collector.name,
	func (reponse):
		match reponse['status']:
			'ok':
				fetch_event_collectors()
			_:
				pass
		)


func stop_collector(collector: EventCollector):
	Server.send_command("stop_collector",
	{"collector_id": collector.id},
	"Stopping collector \'" + collector.name,
	func (reponse):
		match reponse['status']:
			'ok':
				fetch_event_collectors()
			_:
				pass
		)


func delete_collector(collector: EventCollector):
	Server.send_command("delete_collector",
	{"collector_id": collector.id},
	"Stopping collector \'" + collector.name,
	func (reponse):
		match reponse['status']:
			'ok':
				fetch_event_collectors()
			_:
				pass
		)
