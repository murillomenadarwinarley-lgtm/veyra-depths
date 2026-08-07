class_name PlayerHurtState
extends PlayerState
## Estado de daño: el knockback lo aplica la Hurtbox (desde la fuerza de la
## hitbox atacante, ver hurtbox.gd). Este estado solo desliza al jugador
## hasta frenarse y pasa a idle/jump al terminar la duración.

const HURT_FRICTION := 700.0

var _time_left: float = 0.0

func enter(message: Dictionary = {}) -> void:
	_time_left = player.hurt_duration

func physics_process(delta: float) -> void:
	_time_left -= delta
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, HURT_FRICTION * delta)
	player.move_and_slide()
	if _time_left <= 0.0:
		if player.is_on_floor():
			state_machine.change_to(&"idle")
		else:
			state_machine.change_to(&"jump")
