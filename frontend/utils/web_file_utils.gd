class_name WebFileUtils


## Triggers a browser download of [param bytes] as a file named [param file_name].
## Uses a base64-encoded data URL so no server round-trip is needed.
## Only meaningful on the Web platform.
static func download_file(file_name: String, bytes: PackedByteArray) -> void:
	var b64 := Marshalls.raw_to_base64(bytes)
	# Escape the filename to avoid breaking the JS string literal.
	var safe_name := file_name.replace("'", "\\'")
	JavaScriptBridge.eval("""
		(function() {
			var a = document.createElement('a');
			a.href = 'data:application/octet-stream;base64,%s';
			a.download = '%s';
			document.body.appendChild(a);
			a.click();
			document.body.removeChild(a);
		})();
	""" % [b64, safe_name])


## Opens a browser file-picker by injecting a hidden [code]<input type="file">[/code] element.
## [param accept] is the MIME / extension filter passed to the input (e.g. [code]".csv,text/csv"[/code]).
## [param callback] is called as [code]callback(file_name: String, bytes: PackedByteArray)[/code]
## once the user selects a file.  Only meaningful on the Web platform.
static func open_file(accept: String, callback: Callable) -> void:
	# create_callback wraps a GDScript Callable so JavaScript can invoke it.
	# The JS side will call it with (fileName, base64Data).
	var js_cb := JavaScriptBridge.create_callback(
		func(args: Array) -> void:
			var file_name := str(args[0])
			var b64      := str(args[1])
			var bytes    := Marshalls.base64_to_raw(b64)
			callback.call(file_name, bytes)
	)
	# Attach the callback to window so the inline JS closure can reach it.
	var window := JavaScriptBridge.get_interface("window")
	window["_godotOpenFileCallback"] = js_cb

	var safe_accept := accept.replace("'", "\\'")
	JavaScriptBridge.eval("""
		(function() {
			var input = document.createElement('input');
			input.type   = 'file';
			input.accept = '%s';
			input.style.display = 'none';
			document.body.appendChild(input);
			input.onchange = function(e) {
				var file = e.target.files[0];
				document.body.removeChild(input);
				if (!file) return;
				var reader = new FileReader();
				reader.onload = function(ev) {
					// Strip the "data:<mime>;base64," prefix to get raw base64.
					var b64 = ev.target.result.split(',')[1];
					window._godotOpenFileCallback(file.name, b64);
				};
				reader.readAsDataURL(file);
			};
			input.click();
		})();
	""" % safe_accept)
