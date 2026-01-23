extends Page


@export var ResourceItemScene: PackedScene

var _app: App


func _ready() -> void:
	_app = AppManager.apps[page_manager.requested_app_idx]
	title = _app.app_name
	for resource in _app.resources:
		if resource['kind'] == 'pod':
			_add_resource(resource, %PodContainer)
		elif resource['kind'] == 'service':
			_add_resource(resource, %ServiceContainer)
		elif resource['kind'] == 'deployment':
			_add_resource(resource, %DeploymentContainer)


func _add_resource(resource, container: Container):
	var resource_item = ResourceItemScene.instantiate()
	resource_item.resource = resource
	container.add_child(resource_item)
