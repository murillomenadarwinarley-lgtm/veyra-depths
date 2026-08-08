class_name WeaponDefinition
extends RefCounted
## Definición de un arma del jugador, construida desde el catálogo
## data/weapons/weapons.json. El catálogo vive en datos, no en código:
## añadir un arma = añadir una entrada al JSON.

var id: String = ""
var display_name: String = ""
var category: String = ""
var description: String = ""

# Estadísticas del ataque básico.
var damage: int = 1
var arc_size: Vector2 = Vector2(48, 40)
var knockback: float = 250.0
var attack_cooldown: float = 0.3
## Multiplicador de alma ganada al golpear con este arma.
var soul_multiplier: int = 1

# Arte de carga (0.0 = el arma no puede cargarse).
var charge_time: float = 0.0
var charge_damage: int = 0
var charge_arc_size: Vector2 = Vector2.ZERO
var charge_knockback: float = 0.0
var charge_lunge_speed: float = 0.0
var charge_lunge_time: float = 0.0

func can_charge() -> bool:
	return charge_time > 0.0

static func from_dict(data: Dictionary) -> WeaponDefinition:
	var definition := WeaponDefinition.new()
	definition.id = data.get("id", "")
	definition.display_name = data.get("display_name", definition.id)
	definition.category = data.get("category", "")
	definition.description = data.get("description", "")
	definition.damage = data.get("damage", definition.damage)
	definition.arc_size = _vector2(data.get("arc_size", [48, 40]))
	definition.knockback = data.get("knockback", definition.knockback)
	definition.attack_cooldown = data.get("attack_cooldown", definition.attack_cooldown)
	definition.soul_multiplier = data.get("soul_multiplier", 1)
	definition.charge_time = data.get("charge_time", 0.0)
	definition.charge_damage = data.get("charge_damage", 0)
	definition.charge_arc_size = _vector2(data.get("charge_arc_size", []))
	definition.charge_knockback = data.get("charge_knockback", 0.0)
	definition.charge_lunge_speed = data.get("charge_lunge_speed", 0.0)
	definition.charge_lunge_time = data.get("charge_lunge_time", 0.0)
	return definition

static func _vector2(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
