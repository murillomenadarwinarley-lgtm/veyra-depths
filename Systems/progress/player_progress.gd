extends Node
## Progreso del jugador (autoload "Progress").
## Estado central y extensible: habilidades desbloqueadas (nivel por
## habilidad), salas visitadas, jefes derrotados, stats y playtime.
## Es la única fuente de verdad; los sistemas (Saves, WorldMap, HUD...)
## leen y escriben aquí. Serializable vía to_dict()/load_from_dict().

signal ability_unlocked(ability_id: String, level: int)
signal room_visited(room_id: String)
signal boss_defeated(boss_id: String)

var unlocked_abilities: Dictionary = {}  # ability_id -> nivel
var rooms_visited: Array[String] = []
var bosses_defeated: Array[String] = []

var playtime_seconds: float = 0.0
var deaths: int = 0

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	playtime_seconds += delta

func has_ability(ability_id: String) -> bool:
	return unlocked_abilities.has(ability_id)

func get_ability_level(ability_id: String) -> int:
	return unlocked_abilities.get(ability_id, 0)

func grant_ability(ability_id: String, level: int = 1) -> void:
	if not Abilities.has(ability_id):
		push_warning("Progress.grant_ability: habilidad desconocida '%s'" % ability_id)
		return
	if level <= get_ability_level(ability_id):
		return
	unlocked_abilities[ability_id] = level
	ability_unlocked.emit(ability_id, level)
	# TODO: aplicar efectos (habilidad con effect_script en su definición)

## Quita una habilidad desbloqueada (debug, cheats y tests).
func revoke_ability(ability_id: String) -> void:
	unlocked_abilities.erase(ability_id)

func mark_room_visited(room_id: String) -> void:
	if rooms_visited.has(room_id):
		return
	rooms_visited.append(room_id)
	room_visited.emit(room_id)

func defeat_boss(boss_id: String) -> void:
	if bosses_defeated.has(boss_id):
		return
	bosses_defeated.append(boss_id)
	boss_defeated.emit(boss_id)

func is_boss_defeated(boss_id: String) -> bool:
	return bosses_defeated.has(boss_id)

func register_death() -> void:
	deaths += 1

func reset() -> void:
	unlocked_abilities.clear()
	rooms_visited.clear()
	bosses_defeated.clear()
	Inventory.clear()
	playtime_seconds = 0.0
	deaths = 0

func to_dict() -> Dictionary:
	return {
		"unlocked_abilities": unlocked_abilities,
		"rooms_visited": rooms_visited,
		"bosses_defeated": bosses_defeated,
		"playtime_seconds": playtime_seconds,
		"deaths": deaths,
		"inventory": Inventory.items,
	}

func load_from_dict(data: Dictionary) -> void:
	reset()
	var abilities_data: Dictionary = data.get("unlocked_abilities", {})
	for ability_id in abilities_data:
		if Abilities.has(ability_id):
			unlocked_abilities[ability_id] = abilities_data[ability_id]
	for room_id in data.get("rooms_visited", []):
		rooms_visited.append(String(room_id))
	for boss_id in data.get("bosses_defeated", []):
		bosses_defeated.append(String(boss_id))
	playtime_seconds = data.get("playtime_seconds", 0.0)
	deaths = data.get("deaths", 0)
	var inventory_data: Dictionary = data.get("inventory", {})
	for item_id in inventory_data:
		Inventory.items[item_id] = inventory_data[item_id]
