extends Node
## Registro central de armas (autoload "Weapons").
## Cataloga las definiciones desde data/weapons/weapons.json, igual que
## Abilities hace con las habilidades. Extensible: añadir un arma nueva =
## añadir una entrada al JSON, sin tocar código de estadísticas.

signal definitions_loaded

const WEAPONS_PATH := "res://data/weapons/weapons.json"

var definitions: Dictionary = {}  # id -> WeaponDefinition

func _ready() -> void:
	load_definitions()

func load_definitions(path: String = WEAPONS_PATH) -> void:
	definitions.clear()
	var data := JsonLoader.load_dict(path)
	for entry in data.get("weapons", []):
		var definition := WeaponDefinition.from_dict(entry)
		if definition.id.is_empty():
			push_warning("WeaponRegistry: arma sin 'id' en %s" % path)
			continue
		definitions[definition.id] = definition
	definitions_loaded.emit()

func has(id: String) -> bool:
	return definitions.has(id)

func get_definition(id: String) -> WeaponDefinition:
	return definitions.get(id)

func all_definitions() -> Array:
	return definitions.values()
