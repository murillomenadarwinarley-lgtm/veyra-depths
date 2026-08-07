extends Node
## Registro central de habilidades (autoload "Abilities").
## Catalogo las definiciones desde data/abilities/abilities.json.
## Extensible: añadir una habilidad nueva = añadir una entrada al JSON,
## sin tocar código de comprobaciones (las gates del mapa consultan
## Progress.has_ability(), no strings sueltos en el código).

signal definitions_loaded

const ABILITIES_PATH := "res://data/abilities/abilities.json"

var definitions: Dictionary = {}  # id -> AbilityDefinition

func _ready() -> void:
	load_definitions()

func load_definitions(path: String = ABILITIES_PATH) -> void:
	definitions.clear()
	var data := JsonLoader.load_dict(path)
	for entry in data.get("abilities", []):
		var definition := AbilityDefinition.from_dict(entry)
		if definition.id.is_empty():
			push_warning("AbilityRegistry: habilidad sin 'id' en %s" % path)
			continue
		definitions[definition.id] = definition
	definitions_loaded.emit()

func has(id: String) -> bool:
	return definitions.has(id)

func get_definition(id: String) -> AbilityDefinition:
	return definitions.get(id)

func all_definitions() -> Array:
	return definitions.values()
