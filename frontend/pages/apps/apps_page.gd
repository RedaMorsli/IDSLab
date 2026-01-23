extends Page


@export var AppRowScene: PackedScene
@export var WebAppRowScene: PackedScene


func _ready() -> void:
	var add_menu: PopupMenu = %AddAppButton.get_popup()
	add_menu.id_pressed.connect(
		func (id: int):
			match id:
				0: # K8s app
					request_page.emit(page_manager.pages_catalog.AddAppPage)
				1: # Web app
					request_page.emit(page_manager.pages_catalog.AddWebAppPage)
	)
	AppManager.fetch_apps()
	AppManager.fetch_web_apps()
	AppManager.apps_fetched.connect(
		func ():
			_update_apps()
	)
	AppManager.web_apps_fetched.connect(
		func ():
			_update_web_apps()
	)
	await AppManager.apps_fetched
	%AppTable.visible = !AppManager.apps.is_empty()
	%EmptyLabel.visible = AppManager.apps.is_empty()


func _on_add_app_button_button_up() -> void:
	request_page.emit(page_manager.pages_catalog.AddAppPage)


func _update_apps():
	for child in %AppContainer.get_children():
		child.hide()
		child.queue_free()
	for app in AppManager.apps:
		var app_row:Button = AppRowScene.instantiate()
		app_row.app = app
		app_row.button_up.connect(
			func ():
				page_manager.requested_app_idx = AppManager.apps.find(app)
				request_page.emit(page_manager.pages_catalog.AppDetailPage)
		)
		%AppContainer.add_child(app_row)
		AppManager.get_resources_by_app(app)
	
	%AppTable.visible = !AppManager.apps.is_empty() or !AppManager.web_apps.is_empty()
	%EmptyLabel.visible = AppManager.apps.is_empty() and AppManager.web_apps.is_empty()


func _update_web_apps():
	for child in %WebAppContainer.get_children():
		child.hide()
		child.queue_free()
	for app in AppManager.web_apps:
		var app_row:Button = WebAppRowScene.instantiate()
		app_row.app = app
		app_row.button_up.connect(
			func ():
				#page_manager.requested_app_idx = AppManager.web_apps.find(app)
				#request_page.emit(page_manager.pages_catalog.AppDetailPage)
				pass
		)
		%WebAppContainer.add_child(app_row)
	
	%AppTable.visible = !AppManager.apps.is_empty() or !AppManager.web_apps.is_empty()
	%EmptyLabel.visible = AppManager.apps.is_empty() and AppManager.web_apps.is_empty()
