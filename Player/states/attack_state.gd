class_name PlayerAttackState
extends PlayerState

const ATTACK_DURATION := 0.25

var _time_left: float = 0.0

func enter(_message: Dictionary = {}) -> void:
	_time_left = ATTACK_DURATION
	# TODO: hitbox del ataque, animación

func physics_process(delta: float) -> void:
	_time_left -= delta
	if not player.is_on_floor():
		player.apply_gravity(delta)
	player.move_and_slide()
	if _time_left <= 0.0:
		if player.is_on_floor():
			state_machine.change_to(&"idle")
		else:
			state_machine.change_to(&"jump")
