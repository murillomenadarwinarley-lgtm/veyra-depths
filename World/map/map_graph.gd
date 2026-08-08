class_name MapGraph
extends Resource
## Grafo del mundo cargado desde data/map/world_map.json.
## Única fuente de verdad de la conexión entre salas y sus requisitos
## (puertas bloqueadas por habilidad o por jefe).

var format_version: int = 0
var start_room_id: String = ""

var _rooms: Dictionary = {}  # id -> Dictionary (entrada completa del JSON)

func load_from_json(path: String) -> void:
	var data := JsonLoader.load_dict(path)
	if data.is_empty():
		push_error("MapGraph.load_from_json: no se pudo cargar %s" % path)
		return
	format_version = data.get("format_version", 1)
	start_room_id = data.get("start_room", "")
	_rooms.clear()
	for entry in data.get("rooms", []):
		var room_id: String = entry.get("id", "")
		if room_id.is_empty():
			push_warning("MapGraph: sala sin 'id' en %s" % path)
			continue
		_rooms[room_id] = entry

func has_room(room_id: String) -> bool:
	return _rooms.has(room_id)

func get_room(room_id: String) -> Dictionary:
	return _rooms.get(room_id, {})

func get_all_rooms() -> Array:
	return _rooms.values()

func get_room_by_scene(scene_path: String) -> Dictionary:
	for entry in _rooms.values():
		if entry.get("scene", "") == scene_path:
			return entry
	return {}

func get_connection(from_room_id: String, gate_id: String) -> Dictionary:
	for connection in get_room(from_room_id).get("gates", []):
		if connection.get("id", "") == gate_id:
			return connection
	return {}

func get_neighbor_ids(room_id: String) -> Array[String]:
	var neighbors: Array[String] = []
	for connection in get_room(room_id).get("gates", []):
		var to: String = connection.get("to_room", "")
		if not to.is_empty() and not neighbors.has(to):
			neighbors.append(to)
	return neighbors
