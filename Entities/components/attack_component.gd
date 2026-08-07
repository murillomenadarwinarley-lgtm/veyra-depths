class_name AttackComponent
extends Node
## Componente de ataque reutilizable (enemigos, trampas, NPCs hostiles).

@export var damage: int = 2
@export var cooldown: float = 1.0

var _last_attack_time: float = -INF

func can_attack() -> bool:
	return Time.get_ticks_msec() / 1000.0 - _last_attack_time >= cooldown

func attack() -> bool:
	if not can_attack():
		return false
	_last_attack_time = Time.get_ticks_msec() / 1000.0
	# TODO: crear hitbox, knockback, sonido
	return true
