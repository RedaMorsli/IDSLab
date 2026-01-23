class_name StringUtils
extends GDScript


static func str_to_array(string: String):
	var str = string
	if str in ["", "[]"]:
		return []
	str = str.trim_prefix("[")
	str = str.trim_suffix("]")
	var arr = str.split(',')
	var arr1 = []
	for s: String in arr:
		var s1 = s.strip_edges().trim_prefix("'").trim_suffix("'")
		arr1.append(s1)
	return arr1
