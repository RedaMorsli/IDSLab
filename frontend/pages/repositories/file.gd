class_name File
extends Resource


@export var file_name: String
@export var last_modified: String
@export var size: float


func _init(p_name: String, p_date: String, p_size: float) -> void:
	file_name = p_name
	last_modified = p_date
	size = p_size


func get_last_modified_str():
	# Example input: "2025-11-26 13:00:04.768000+00:00"
	# 1) Strip microseconds and timezone so Godot can parse it.
	var clean := last_modified.split("+")[0]   # "2025-11-26 13:00:04.768000"
	clean = clean.split(".")[0]              # "2025-11-26 13:00:04"

	# 2) Parse as a UTC datetime string -> Unix time (still UTC).
	var utc_unix := Time.get_unix_time_from_datetime_string(clean)
	if utc_unix == 0:
		# Fallback if parsing failed
		return last_modified

	# 3) Get client timezone offset from UTC (in minutes), then convert to seconds.
	var tz := Time.get_time_zone_from_system()  # { "bias": minutes, "name": "..." }
	var offset_minutes := int(tz["bias"])
	var offset_seconds := offset_minutes * 60

	# 4) Convert event time from UTC to local Unix time.
	var local_event_unix := utc_unix + offset_seconds
	var event_local_dt := Time.get_datetime_dict_from_unix_time(int(local_event_unix))

	# 5) Get "now" in local time using the same logic (UTC -> local).
	var now_utc_unix := int(Time.get_unix_time_from_system())
	var now_local_unix := now_utc_unix + offset_seconds
	var now_local_dt := Time.get_datetime_dict_from_unix_time(now_local_unix)

	# 6) Compute "yesterday" in local time (now - 1 day).
	var yesterday_local_unix := now_local_unix - 86400  # 24 * 60 * 60
	var yesterday_local_dt := Time.get_datetime_dict_from_unix_time(yesterday_local_unix)

	# 7) Decide label: Today / Yesterday / date.
	var label := ""
	if (event_local_dt.year == now_local_dt.year
		and event_local_dt.month == now_local_dt.month
		and event_local_dt.day == now_local_dt.day):
		label = "Today"
	elif (event_local_dt.year == yesterday_local_dt.year
		and event_local_dt.month == yesterday_local_dt.month
		and event_local_dt.day == yesterday_local_dt.day):
		label = "Yesterday"
	else:
		label = "%02d/%02d/%04d" % [event_local_dt.day, event_local_dt.month, event_local_dt.year]

	# 8) Format time as HH:MM in local time.
	var time_str := "%02d:%02d" % [event_local_dt.hour, event_local_dt.minute]

	return "%s, %s" % [label, time_str]


func get_size_str() -> String:
	var units = ["B", "KiB", "MiB", "GiB", "TiB"]
	var unit_index = 0
	
	while size >= 1024.0 and unit_index < units.size() - 1:
		size /= 1024.0
		unit_index += 1
	
	if unit_index == 0:
		return "%d %s" % [int(size), units[unit_index]]
	else:
		return "%.2f %s" % [size, units[unit_index]]
