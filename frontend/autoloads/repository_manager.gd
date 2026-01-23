extends Node


signal repository_creation_succeeded
signal repository_creation_failed
signal repositories_fetched(repositories: Array[Repository])
signal event_files_fetched(files: Array[File])
signal metric_files_fetched(files: Array[File])


var repositories: Array[Repository] = []


func _ready() -> void:
	fetch_repositories()


func create_repository(repository_name: String):
	Server.send_command("create_repository",
	{"repository_name": repository_name},
	"Creating repository \'" + repository_name + "\'",
	func (reponse):
		match reponse['status']:
			'ok':
				repository_creation_succeeded.emit()
				fetch_repositories()
			_:
				repository_creation_failed.emit()
		)


func fetch_repositories():
	Server.send_command("get_repositories", {},
		"Fetching repositories",
		func (reponse):
			var p_repositories: Array = reponse['data']
			repositories.clear()
			for repo in p_repositories:
				repositories.append(Repository.new.callv(repo[0]))
			repositories_fetched.emit(repositories)
	)


func delete_repository(repo: Repository):
	Server.send_command("delete_repository",
	{"repository_id": repo.repository_id},
	"Deleting repository \'" + repo.repository_name + "\'",
	func (reponse):
		match reponse['status']:
			'ok':
				fetch_repositories()
			_:
				pass
		)


func fetch_event_files(repo: Repository):
	Server.send_command("get_event_files",
	{"repository_id": repo.repository_id},
	"Fetching event files from \'" + repo.repository_name + "\' repository",
	func (reponse):
		match reponse['status']:
			'ok':
				var files = reponse.data
				var event_files: Array[File] = []
				for file in files:
					event_files.append(File.new.callv(file))
				event_files_fetched.emit(event_files)
			_:
				pass
		)


func fetch_metric_files(repo: Repository):
	Server.send_command("get_metric_files",
	{"repository_id": repo.repository_id},
	"Fetching metric files from \'" + repo.repository_name + "\' repository",
	func (reponse):
		match reponse['status']:
			'ok':
				var files = reponse.data
				var metric_files: Array[File] = []
				for file in files:
					metric_files.append(File.new.callv(file))
				metric_files_fetched.emit(metric_files)
			_:
				pass
		)


func get_repository_by_name(repo_name: String) -> Repository:
	for repo: Repository in repositories:
		if repo.repository_name == repo_name:
			return repo
	return null
