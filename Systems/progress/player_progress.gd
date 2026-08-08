extends Node
## Progreso del jugador (autoload "Progress").
## Estado central y extensible: habilidades desbloqueadas (nivel por
## habilidad), salas visitadas, jefes derrotados, stats y playtime.
## Es la única fuente de verdad; los sistemas (Saves, WorldMap, HUD...)
## leen y escriben aquí. Serializable vía to_dict()/load_from_dict().

signal ability_unlocked(ability_id: String, level: int)
signal room_visited(room_id: String)
signal boss_defeated(boss_id: String)
signal soul_changed(amount: int)

var unlocked_abilities: Dictionary = {}  # ability_id -> nivel
var rooms_visited: Array[String] = []
var bosses_defeated: Array[String] = []
## Salud actual del jugador (espejo del HealthComponent, para persistir).
var player_health: int = -1  # -1 = sin jugador creado aún
## Punto seguro de reaparición: sala + nombre de Marker2D dentro de ella.
var checkpoint_room: String = ""
var checkpoint_marker: String = "PlayerSpawn"
## Enemigos derrotados por sala: room_id -> Array[String] (nombres de nodo).
var enemies_defeated: Dictionary = {}
## Arma equipada: id del catálogo data/weapons/weapons.json. La espada
## de óxido es el arma inicial; las demás se consiguen en el mundo.
var equipped_weapon: String = "rusty_nail"
## Alma (recurso de combate): se gana golpeando enemigos y se gasta en
## cura focalizada y (futuras) hechizos. 0-100.
var soul: int = 0

const MAX_SOUL := 100
const SOUL_PER_HIT := 6
const FOCUS_COST := 30
## Coste del hechizo de alma: más barato que Focus para que sirva como
## gasto ofensivo frecuente sin vaciar la reserva defensiva.
const SPELL_COST := 25

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

## Equipa un arma del catálogo (no valida propiedad: el que lo llama
## decide). Se persiste en el save.
func equip_weapon(weapon_id: String) -> void:
	if not Weapons.has(weapon_id):
		push_warning("Progress.equip_weapon: arma desconocida '%s'" % weapon_id)
		return
	equipped_weapon = weapon_id

func get_equipped_weapon() -> String:
	return equipped_weapon

func set_player_health(value: int) -> void:
	player_health = maxi(value, 0)

func get_player_health() -> int:
	return player_health

## Marca el punto seguro de reaparición (sala + Marker2D dentro de ella).
func set_checkpoint(room_id: String, marker: String = "PlayerSpawn") -> void:
	checkpoint_room = room_id
	checkpoint_marker = marker

func get_checkpoint_room() -> String:
	return checkpoint_room

func get_checkpoint_marker() -> String:
	return checkpoint_marker

## Registra la derrota de un enemigo en su sala (por nombre de nodo).
func register_enemy_defeated(room_id: String, enemy_name: String) -> void:
	var list: Array = enemies_defeated.get(room_id, [])
	if enemy_name not in list:
		list.append(enemy_name)
		enemies_defeated[room_id] = list

func is_enemy_defeated(room_id: String, enemy_name: String) -> bool:
	return enemy_name in enemies_defeated.get(room_id, [])

func get_defeated_enemies(room_id: String) -> Array:
	return enemies_defeated.get(room_id, [])

## Alma: gana por golpear enemigos (SOUL_PER_HIT), gasta en Focus.
func add_soul(amount: int) -> void:
	soul = clampi(soul + amount, 0, MAX_SOUL)
	soul_changed.emit(soul)

## Gasta alma si hay suficiente; devuelve si se pudo.
func spend_soul(amount: int) -> bool:
	if soul < amount:
		return false
	soul -= amount
	soul_changed.emit(soul)
	return true

func get_soul() -> int:
	return soul

func register_death() -> void:
	deaths += 1

func reset() -> void:
	unlocked_abilities.clear()
	rooms_visited.clear()
	bosses_defeated.clear()
	Inventory.clear()
	player_health = -1
	checkpoint_room = ""
	checkpoint_marker = "PlayerSpawn"
	enemies_defeated.clear()
	soul = 0
	soul_changed.emit(0)
	equipped_weapon = "rusty_nail"
	playtime_seconds = 0.0
	deaths = 0

func to_dict() -> Dictionary:
	return {
		"unlocked_abilities": unlocked_abilities,
		"rooms_visited": rooms_visited,
		"bosses_defeated": bosses_defeated,
		"player_health": player_health,
		"checkpoint_room": checkpoint_room,
		"checkpoint_marker": checkpoint_marker,
		"enemies_defeated": enemies_defeated,
		"soul": soul,
		"equipped_weapon": equipped_weapon,
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
	if data.has("player_health"):
		player_health = int(data["player_health"])
	checkpoint_room = String(data.get("checkpoint_room", ""))
	checkpoint_marker = String(data.get("checkpoint_marker", "PlayerSpawn"))
	if data.has("soul"):
		soul = clampi(int(data["soul"]), 0, MAX_SOUL)
	soul_changed.emit(soul)
	var equipped := String(data.get("equipped_weapon", "rusty_nail"))
	if Weapons.has(equipped):
		equipped_weapon = equipped
	var enemies_data: Dictionary = data.get("enemies_defeated", {})
	for room_id in enemies_data:
		var list: Array = []
		for enemy_name in enemies_data[room_id]:
			list.append(String(enemy_name))
		enemies_defeated[String(room_id)] = list
	playtime_seconds = data.get("playtime_seconds", 0.0)
	deaths = data.get("deaths", 0)
	var inventory_data: Dictionary = data.get("inventory", {})
	for item_id in inventory_data:
		Inventory.items[item_id] = inventory_data[item_id]
