class_name PlayerFocusState
extends PlayerState
## Cura focalizada estilo Hollow Knight: mantén "focus" (C) quieto en el
## suelo para canalizar; al completar cada canalización gasta FOCUS_COST
## de alma y recupera 1 de vida. Se encadena si sigues manteniendo el botón
## (y hay alma). Cualquier daño interrumpe el estado (hurt lo pisa).

const CHANNEL_DURATION := 0.8

var _channel_time_left: float = 0.0

func enter(_message: Dictionary = {}) -> void:
	_channel_time_left = CHANNEL_DURATION
	player.velocity.x = 0.0
	player.velocity.y = 0.0
	Audio.play_sfx("whoosh")

func exit() -> void:
	pass

func physics_process(delta: float) -> void:
	if not Input.is_action_pressed("focus"):
		state_machine.change_to(&"idle" if player.is_on_floor() else &"jump")
		return
	_channel_time_left -= delta
	if _channel_time_left <= 0.0:
		player.health.heal(1)
		Progress.spend_soul(Progress.FOCUS_COST)
		Feel.flash(player, Color(0.4, 0.7, 1.0), 0.2)
		Audio.play_sfx("hit")
		if Progress.get_soul() < Progress.FOCUS_COST:
			state_machine.change_to(&"idle")
			return
		_channel_time_left = CHANNEL_DURATION
	player.move_and_slide()
