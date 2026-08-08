class_name LeapAttackComponent
extends AttackComponent
## Ataque de salto (Saltador): en lugar de embestir, salta un arco hacia
## el objetivo con la hitbox activa durante el vuelo. El vuelo es
## balístico: solo actúa la gravedad (el movimiento X lo da el impulso),
## así que el enemigo puede saltar por encima de pozos y techos bajos.

@export var leap_velocity: Vector2 = Vector2(300, -480)

## Durante la fase activa no se empuja: el impulso del salto ya da el
## movimiento X y la gravedad (aplicada por la IA) hace el resto.
func process_attack(delta: float, direction: Vector2) -> bool:
	match phase:
		Phase.TELEGRAPH:
			if _movement:
				_movement.stop(delta)
				_face(direction)
			_phase_time_left -= delta
			if _phase_time_left <= 0.0:
				_begin_hit_phase(direction)
		Phase.ACTIVE:
			_phase_time_left -= delta
			if _phase_time_left <= 0.0:
				_finish_attack()
	return phase != Phase.IDLE

func _begin_hit_phase(direction: Vector2) -> void:
	super(direction)
	if _movement:
		var v := _movement.velocity
		v.x = direction.x * leap_velocity.x
		v.y = leap_velocity.y
		_movement.velocity = v
