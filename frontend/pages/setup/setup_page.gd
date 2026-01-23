extends Page


const StepScene: PackedScene = preload("uid://bdw6luqob0462")

@onready var step_container: VBoxContainer = %StepContainer


func _ready() -> void:
	_refresh()
	visibility_changed.connect(_refresh)


func _refresh():
	if not visible:
		return
	for child in step_container.get_children():
		child.queue_free()
	var cluster_step = _init_cluster_creation_step()
	if cluster_step.checking:
		await cluster_step.updated
	var repo_step = _init_repo_creation_step()
	if repo_step.checking:
		await repo_step.updated
	var filter_step = _init_filter_step()
	if filter_step.checking:
		await repo_step.updated
	var collector_step = _init_collector_step()
	if collector_step.checking:
		await collector_step.updated
	var dataset_step = _init_dataset_step()
	if dataset_step.checking:
		await dataset_step.updated
	for step: SetupStep in [cluster_step, repo_step, filter_step, collector_step, dataset_step]:
		if not step.completed:
			step.folded = false
			break


func _init_cluster_creation_step() -> SetupStep:
	var step = StepScene.instantiate() as SetupStep
	step.title = "Connect a cluster"
	step.description = "Connect to a running cluster to collect data from"
	step.complete_condition = Callable(
		func () -> bool:
			if RequestStatus.is_request_pending(Commands.GET_CLUSTERS):
				await ClusterManager.clusters_fetched
			return not ClusterManager.clusters.is_empty()
	)
	step.primary_action = Callable(
		func ():
			Navigation.go_to_page("clusters", page_manager.pages_catalog.AddClusterPage)
	)
	step.primarty_action_title = "Connect"
	step_container.add_child(step)
	return step


func _init_repo_creation_step() -> SetupStep:
	var step = StepScene.instantiate() as SetupStep
	step.title = "Create a repository"
	step.description = "Create a new repository to store collected data"
	step.complete_condition = Callable(
		func () -> bool:
			if RequestStatus.is_request_pending(Commands.GET_REPOSITORIES):
				await RepositoryManager.repositories_fetched
			return not RepositoryManager.repositories.is_empty()
	)
	step.primary_action = Callable(
		func ():
			Navigation.go_to_page("repositories", page_manager.pages_catalog.CreateRepositoriesPage)
	)
	step.primarty_action_title = "Create a repository"
	step_container.add_child(step)
	return step


func _init_filter_step() -> SetupStep:
	var step = StepScene.instantiate() as SetupStep
	step.title = "Filter data to collect"
	step.description = "Create and configure which events and metrics you want to monitor"
	step.complete_condition = Callable(
		func () -> bool:
			if RequestStatus.is_request_pending(Commands.GET_EVENT_FILTERS):
				await EventManager.event_filters_fetched
			return not EventManager.filters.is_empty()
	)
	step.primary_action = Callable(
		func ():
			Navigation.go_to_page("event_filters")
	)
	step.primarty_action_title = "Create a filter"
	step_container.add_child(step)
	return step


func _init_collector_step() -> SetupStep:
	var step = StepScene.instantiate() as SetupStep
	step.title = "Start data collection"
	step.description = "Create a collector to start collecting your data"
	step.complete_condition = Callable(
		func () -> bool:
			if RequestStatus.is_request_pending(Commands.GET_COLLECTORS):
				await EventManager.event_collectors_fetched
			return not EventManager.collectors.is_empty()
	)
	step.primary_action = Callable(
		func ():
			Navigation.go_to_page("event_collectors", page_manager.pages_catalog.CreateEventCollectorPage)
	)
	step.primarty_action_title = "Create a collector"
	step_container.add_child(step)
	return step


func _init_dataset_step() -> SetupStep:
	var step = StepScene.instantiate() as SetupStep
	step.title = "Build a dataset"
	step.description = "Build a dataset from collected data"
	step.complete_condition = Callable(
		func () -> bool:
			if RequestStatus.is_request_pending(Commands.GET_DATASETS):
				await DatasetManager.datasets_fetched
			return not DatasetManager.datasets.is_empty()
	)
	step.primary_action = Callable(
		func ():
			Navigation.go_to_page("datasets")
	)
	step.primarty_action_title = "Create a dataset"
	step_container.add_child(step)
	return step


func _init_intallation_step() -> SetupStep:
	var step = StepScene.instantiate() as SetupStep
	step.title = "Install storage component"
	step.description = "Deploy or connect to an object storage system"
	step.complete_condition = Callable(
		func () -> bool:
			return await Setup.is_minio_installed()
	)
	step.primary_action = Callable(
		func ():
			pass
	)
	step.primarty_action_title = "Install"
	step_container.add_child(step)
	return step
