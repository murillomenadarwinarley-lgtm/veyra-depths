extends Node
## Grafo del mundo en memoria (autoload "WorldMap").
## Carga data/map/world_map.json en un MapGraph y responde consultas.
## Las comprobaciones de requisitos consultan a Progress (estado central).

signal map_loaded

const MAP_PATH := "res://data/map/world_map.json"

var graph: MapGraph = MapGraph.new()
var start_room_id: String = ""

func _ready() -> void:
	load_map()

func load_map(path: String = MAP_PATH) -> void:
	graph = MapGraph.new()
	graph.load_from_json(path)
	start_room_id = graph.start_room_id
	map_loaded.emit()

func room_exists(room_id: String) -> bool:
	return graph.has_room(room_id)

func get_room(room_id: String) -> Dictionary:
	return graph.get_room(room_id)

func get_room_by_scene(scene_path: String) -> Dictionary:
	return graph.get_room_by_scene(scene_path)

func get_connection(from_room_id: String, gate_id: String) -> Dictionary:
	return graph.get_connection(from_room_id, gate_id)

func get_neighbors(room_id: String) -> Array:
	return graph.get_neighbor_ids(room_id)

func can_traverse(connection: Dictionary) -> bool:
	var ability_id: String = connection.get("requires_ability", "")
	if not ability_id.is_empty() and not Progress.has_ability(ability_id):
		return false
	var boss_id: String = connection.get("requires_boss", "")
	if not boss_id.is_empty() and not Progress.is_boss_defeated(boss_id):
		return false
	return true
