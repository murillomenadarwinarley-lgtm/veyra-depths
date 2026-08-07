class_name PlayerDashState
extends PlayerState

const DASH_SPEED := 600.0
const DASH_DURATION := 0.18

var _time_left: float = 0.0

func enter(_message: Dictionary = {}) -> void:
	_time_left = DASH_DURATION
	player.velocity = Vector2(player.facing.x * DASH_SPEED, 0.0)
	# TODO: efectos de dash (partículas, invulnerabilidad)

func physics_process(delta: float) -> void:
	_time_left -= delta
	player.move_and_slide()
	if _time_left <= 0.0:
		if player.is_on_floor():
			state_machine.change_to(&"idle")
		else:
			state_machine.change_to(&"jump")
