extends Node


signal minio_status_fetched()


var _minio_status: bool = false


func is_minio_installed() -> bool:
	Server.send_command(
		"check_minio_connection",
		{},
		"Checking minio status",
		func (response):
			_minio_status = response.data
			minio_status_fetched.emit()
	)
	await minio_status_fetched
	return _minio_status
