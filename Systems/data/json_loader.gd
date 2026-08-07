class_name JsonLoader
## Utilidades estáticas para cargar JSON desde disco (res:// o user://).

static func load_dict(path: String) -> Dictionary:
	var parsed = load_any(path)
	if parsed is Dictionary:
		return parsed
	return {}

static func load_array(path: String) -> Array:
	var parsed = load_any(path)
	if parsed is Array:
		return parsed
	return []

static func load_any(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("JsonLoader: archivo no encontrado: %s" % path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("JsonLoader: no se pudo abrir %s (error %d)" % [path, FileAccess.get_open_error()])
		return null
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("JsonLoader: JSON inválido en %s" % path)
	return parsed
