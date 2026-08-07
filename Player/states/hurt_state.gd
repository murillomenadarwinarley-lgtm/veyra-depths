class_name PlayerHurtState
extends PlayerState

const HURT_DURATION := 0.35
const KNOCKBACK_SPEED := 300.0

var _time_left: float = 0.0

## El knockback empuja en dirección contraria al atacante (message["from"]
## es la posición del atacante); sin atacante, contra la dirección mirada.
func enter(message: Dictionary = {}) -> void:
	_time_left = HURT_DURATION
	var dir := -player.facing.x
	if message.has("from"):
		var from: Vector2 = message["from"]
		dir = signf(player.global_position.x - from.x)
		if dir == 0.0:
			dir = 1.0
	player.velocity.x = dir * KNOCKBACK_SPEED
	player.velocity.y = -200.0
	# TODO: flash de daño

func physics_process(delta: float) -> void:
	_time_left -= delta
	player.apply_gravity(delta)
	player.move_and_slide()
	if _time_left <= 0.0:
		if player.is_on_floor():
			state_machine.change_to(&"idle")
		else:
			state_machine.change_to(&"jump")
