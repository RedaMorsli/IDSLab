extends Node


signal apps_fetched()
signal web_apps_fetched()
signal app_resources_fetched(app_name, running_resources)

var apps: Array[App]
var web_apps: Array[WebApp]


func _ready() -> void:
	#fetch_web_apps()
	pass


func add_app(app_name: String, cluster_name: String, namespaces: Array, labels: Dictionary):
	Server.send_command("add_app",
	{"app_name": app_name, "cluster_name": cluster_name, "namespaces": namespaces, "labels": labels},
	"Adding app \'" + app_name + "\'",
	func (args):
		fetch_apps()
		)


func fetch_apps():
	Server.send_command("get_apps", null, "Fetching applications", 
	func (reponse):
		var p_apps = reponse['data']
		apps.clear()
		for app in p_apps:
			apps.append(App.new.callv(app[0]))
		apps_fetched.emit()
		)


func delete_app(app: App):
	Server.send_command("delete_app",
	{"app_id": app.app_id}, "Deleting app \'" + app.app_name + "\'",
	func (args):
		fetch_apps()
		)


func get_resources_by_app(app: App):
	Server.send_command("get_resources_by_app",
	{"app_name": app.app_name, "cluster_name": app.cluster_name, "namespaces": app.namespaces, "labels": app.labels}, 
	"Fetching resources for app \'" + app["app_name"] + "\'",
	func (resources: Array):
		for a in apps:
			if a.app_name == app.app_name:
				a.resources = resources
		app_resources_fetched.emit(app['app_name'], resources.size())
		print(resources)
		)


func add_web_app(app_name: String, address: String, port: int):
	Server.send_command("add_web_app",
	{"app_name": app_name, "address": address, "port": port}, 
	"Adding web app \'" + app_name + "\'",
	func (args):
		fetch_web_apps()
		)


func fetch_web_apps():
	Server.send_command("get_web_apps", null, 
	"Fetching web applications",
	func (reponse):
		var p_web_apps = reponse['data']
		print(p_web_apps)
		web_apps.clear()
		for app in p_web_apps:
			web_apps.append(WebApp.new.callv(app[0]))
		web_apps_fetched.emit()
		)


func delete_web_app(app: WebApp):
	Server.send_command("delete_web_app",
	{"app_id": app.app_id}, 
	"Deleting web app \'" + app.app_name + "\'",
	func (args):
		fetch_web_apps()
	)
