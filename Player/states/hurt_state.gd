class_name PlayerHurtState
extends PlayerState

const HURT_DURATION := 0.35
const KNOCKBACK_SPEED := 300.0

var _time_left: float = 0.0

func enter(message: Dictionary = {}) -> void:
	_time_left = HURT_DURATION
	player.velocity.x = -player.facing.x * KNOCKBACK_SPEED
	player.velocity.y = -200.0
	# TODO: i-frames, flash de daño, vida (vía Progress o HealthComponent)

func physics_process(delta: float) -> void:
	_time_left -= delta
	player.velocity.y += player.get_gravity().y * delta
	player.move_and_slide()
	if _time_left <= 0.0:
		if player.is_on_floor():
			state_machine.change_to(&"idle")
		else:
			state_machine.change_to(&"jump")
