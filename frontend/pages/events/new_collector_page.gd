extends Page


@onready var clusterOption: OptionButton = %ClusterOptionButton
@onready var filterOption: OptionButton = %FilterOptionButton
@onready var repositoryOption: OptionButton = %RepositoryOptionButton
@onready var timeoutCheck: CheckBox = %TimeoutCheck
@onready var timeoutContainer: Container = %Timeout
@onready var timeoutHour: SpinBox = %TimeoutHour
@onready var timeoutMinute: SpinBox = %TimeoutMinute
@onready var timeoutSecond: SpinBox = %TimeoutSecond
@onready var autostartCheck: CheckBox = %AutostartCheck


func _ready() -> void:
	for cluster in ClusterManager.clusters:
		clusterOption.add_item(cluster.cluster_name)
	for filter in EventManager.filters:
		filterOption.add_item(filter.filter_name)
	for repository in RepositoryManager.repositories:
		repositoryOption.add_item(repository.repository_name)
	
	timeoutContainer.hide()
	timeoutCheck.toggled.connect(
		func (toggled: bool):
			timeoutContainer.visible = toggled
	)


func _on_create_collector_button_pressed() -> void:
	EventManager.create_collector(
		ClusterManager.clusters[clusterOption.selected],
		EventManager.filters[filterOption.selected],
		RepositoryManager.repositories[repositoryOption.selected],
		autostartCheck.button_pressed
		)
	request_pop_back.emit()
