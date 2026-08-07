extends Node
## Gestor de guardado (autoload "Saves").
## Guarda/lee partidas en user://saves/slot_<n>.json (formato JSON).
## Una partida = snapshot de Progress (habilidades, salud, checkpoint,
## enemigos derrotados, inventario) + sala actual. Un solo slot por ahora.

const SAVE_DIR := "user://saves/"
const SAVE_FILE := "slot_%d.json"
const SAVE_VERSION := 2

var current_slot: int = 0

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func get_save_path(slot: int = current_slot) -> String:
	return SAVE_DIR + (SAVE_FILE % slot)

func has_save(slot: int = current_slot) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

func save_game(slot: int = current_slot, metadata: Dictionary = {}) -> Error:
	if RoomStreamer.player != null:
		Progress.set_player_health(RoomStreamer.player.health.health)
	var data := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"current_room": RoomStreamer.current_room_id,
		"progress": Progress.to_dict(),
		"metadata": metadata,
	}
	var path := get_save_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Saves.save_game: no se pudo escribir %s" % path)
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	current_slot = slot
	return OK

func load_game(slot: int = current_slot) -> Error:
	var path := get_save_path(slot)
	if not has_save(slot):
		push_error("Saves.load_game: no existe partida en %s" % path)
		return ERR_FILE_NOT_FOUND
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is not Dictionary:
		push_error("Saves.load_game: partida corrupta en %s" % path)
		return ERR_PARSE_ERROR
	if int(parsed.get("version", -1)) != SAVE_VERSION:
		push_error("Saves.load_game: versión de partida no soportada en %s" % path)
		return ERR_INVALID_DATA
	current_slot = slot
	Progress.load_from_dict(parsed.get("progress", {}))
	var saved_room: String = String(parsed.get("current_room", ""))
	if not WorldMap.room_exists(saved_room):
		push_warning("Saves.load_game: sala '%s' desconocida, usando inicio" % saved_room)
		saved_room = WorldMap.start_room_id
	if RoomStreamer.player == null:
		RoomStreamer.bootstrap()
	RoomStreamer.enter_room(saved_room, Progress.get_checkpoint_marker())
	if Progress.get_player_health() > 0 and RoomStreamer.player != null:
		RoomStreamer.player.health.set_health(Progress.get_player_health())
	return OK

func new_game() -> void:
	Progress.reset()
	current_slot = 0
