class_name AbilityDefinition
extends RefCounted
## Definición de una habilidad desbloqueable, construida desde el catálogo
## data/abilities/abilities.json. El catálogo vive en datos, no en código.

var id: String = ""
var display_name: String = ""
var category: String = ""      # movilidad, combate, traversal...
var description: String = ""
var icon_path: String = ""
var max_level: int = 1
var effect_script: String = ""  # path opcional a un script con _on_granted(progress)

static func from_dict(data: Dictionary) -> AbilityDefinition:
	var definition := AbilityDefinition.new()
	definition.id = data.get("id", "")
	definition.display_name = data.get("display_name", definition.id)
	definition.category = data.get("category", "")
	definition.description = data.get("description", "")
	definition.icon_path = data.get("icon_path", "")
	definition.max_level = data.get("max_level", 1)
	definition.effect_script = data.get("effect_script", "")
	return definition
