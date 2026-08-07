extends Node
## Streaming de salas (autoload "RoomStreamer").
## Solo mantiene cargadas la sala actual y sus vecinas inmediatas
## (STREAM_RADIUS); el resto se libera de memoria.

signal room_entered(room_id: String, previous_room_id: String)

const PLAYER_SCENE := preload("res://Player/player.tscn")
const STREAM_RADIUS := 1

var current_room_id: String = ""
var loaded_rooms: Dictionary = {}  # room_id -> Node (sala instanciada)
var player: CharacterBody2D = null

var _world_root: Node2D = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## El WorldRoot se crea perezosamente: durante el _ready de los autoloads
## el root aún está montando hijos y add_child fallaría.
func get_world_root() -> Node2D:
	if _world_root == null:
		_world_root = Node2D.new()
		_world_root.name = "WorldRoot"
		get_tree().root.add_child(_world_root)
	return _world_root

## Crea el jugador y carga la sala inicial. Lo llama PlayingState la
## primera vez que se entra a jugar.
func bootstrap() -> void:
	if player == null:
		player = PLAYER_SCENE.instantiate()
		get_world_root().add_child(player)
	enter_room(WorldMap.start_room_id)

func enter_room(room_id: String, spawn_marker: String = "") -> void:
	if not WorldMap.room_exists(room_id):
		push_warning("RoomStreamer.enter_room: sala desconocida '%s'" % room_id)
		return
	var previous := current_room_id
	var room := load_room(room_id)
	current_room_id = room_id
	if spawn_marker.is_empty():
		spawn_marker = "PlayerSpawn"
	Progress.mark_room_visited(room_id)
	Progress.set_checkpoint(room_id, spawn_marker)
	position_player_at_spawn(room, spawn_marker)
	configure_camera()
	stream_neighbors(room_id)
	room_entered.emit(room_id, previous)

## El jugador cruza una puerta (Area2D con grupo "room_gate" y meta
## "gate_id"). El destino y los requisitos salen del JSON, no del código.
func enter_gate(room_id: String, gate_id: String) -> void:
	if room_id != current_room_id:
		return
	var connection := WorldMap.get_connection(room_id, gate_id)
	if connection.is_empty():
		push_warning("RoomStreamer.enter_gate: puerta '%s' no existe en '%s'" % [gate_id, room_id])
		return
	if not WorldMap.can_traverse(connection):
		# TODO: feedback de puerta bloqueada (mensaje HUD, sonido)
		return
	enter_room(connection.get("to_room", ""))

func load_room(room_id: String) -> Node:
	if loaded_rooms.has(room_id):
		return loaded_rooms[room_id]
	var room_data := WorldMap.get_room(room_id)
	var scene := load(room_data.get("scene", "")) as PackedScene
	if scene == null:
		push_error("RoomStreamer.load_room: escena nula para '%s'" % room_id)
		return null
	var room := scene.instantiate()
	room.name = "Room_%s" % room_id
	prune_defeated_enemies(room_id, room)
	get_world_root().add_child(room)
	loaded_rooms[room_id] = room
	return room

## Carga vecinos del grafo y libera salas fuera del radio de streaming.
func stream_neighbors(room_id: String) -> void:
	var neighbors: Array = WorldMap.get_neighbors(room_id)
	for other_id in neighbors:
		load_room(other_id)
	var keep: Array = neighbors.duplicate()
	keep.append(room_id)
	for loaded_id in loaded_rooms.keys():
		if loaded_id in keep:
			continue
		var room: Node = loaded_rooms[loaded_id]
		loaded_rooms.erase(loaded_id)
		room.queue_free()

## Sitúa al jugador en un marcador seguro de la sala (por defecto
## PlayerSpawn). Si el marcador no existe, cae a PlayerSpawn.
func position_player_at_spawn(room: Node, marker_name: String = "PlayerSpawn") -> void:
	if player == null:
		return
	var spawn := room.get_node_or_null(marker_name)
	if spawn is not Marker2D:
		spawn = room.get_node_or_null("PlayerSpawn")
	if spawn is Marker2D:
		player.global_position = spawn.global_position
	else:
		push_warning("RoomStreamer: '%s' no tiene PlayerSpawn" % room.name)

## Elimina de la sala los enemigos ya derrotados (Progress.enemies_defeated)
## para que no reaparezcan al recargar. Se identifican por nombre de nodo
## dentro de la escena de la sala; no requiere tener el mapa en memoria.
func prune_defeated_enemies(room_id: String, room: Node) -> void:
	for enemy_name in Progress.get_defeated_enemies(room_id):
		var node := room.get_node_or_null(enemy_name)
		if node != null and node.is_in_group("enemies"):
			node.queue_free()

func configure_camera() -> void:
	if player == null:
		return
	var cam := player.get_node_or_null("Camera2D")
	if cam is RoomCamera:
		var bounds: Dictionary = WorldMap.get_room(current_room_id).get("bounds", {})
		cam.setup(bounds)
