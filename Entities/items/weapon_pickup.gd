class_name WeaponPickup
extends Area2D
## Arma del mundo: al tocarla se añade al inventario y se equipa (una vez).
## Si el arma ya está equipada, el pickup no aparece al cargar la sala
## (se poda en _ready, como los orbes de habilidad).

const COLOR_WEAPON := Color(0.55, 0.95, 1.0, 1.0)

@export var weapon_id: String = "rusty_nail"

@onready var crystal: Polygon2D = $Crystal

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if Progress.get_equipped_weapon() == weapon_id:
		queue_free()

## Flotación suave del cristal.
func _process(_delta: float) -> void:
	crystal.position.y = sin(Time.get_ticks_msec() / 350.0) * 4.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and Progress.get_equipped_weapon() != weapon_id:
		Inventory.add(weapon_id)
		Progress.equip_weapon(weapon_id)
		Audio.play_sfx("pickup")
		Feel.burst(global_position, COLOR_WEAPON)
		queue_free()
