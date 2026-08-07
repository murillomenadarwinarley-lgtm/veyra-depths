class_name PlayerAttackState
extends PlayerState

const ATTACK_DURATION := 0.25
## Posición base de la hitbox frontal (definida en player.tscn).
const SIDE_HITBOX_POS := Vector2(44, 0)
## Posición de la hitbox del ataque descendente (pogo). Debe sobresalir
## por debajo de la zona de contacto de los enemigos (hurtbox r≈28) para
## que el pogo conecte antes de recibir daño de contacto: con el rect
## 48x40 en (0, 46) el pogo alcanza ~90px por debajo del centro y el
## contacto enemigo empieza ~52px; hay margen de sobra.
const DOWN_HITBOX_POS := Vector2(0, 46)

var _time_left: float = 0.0
var _down_attack := false

func enter(_message: Dictionary = {}) -> void:
	_time_left = ATTACK_DURATION
	player.use_attack()
	# En el aire + manteniendo abajo: ataque descendente para pogo.
	_down_attack = not player.is_on_floor() and Input.is_action_pressed("down")
	if _down_attack:
		player._attack_is_down = true
		player.attack_hitbox.position = DOWN_HITBOX_POS
		Audio.play_sfx("whoosh")
		Feel.slash(player.global_position + Vector2(0, 30), PI / 2.0)
	else:
		player.attack_hitbox.set_direction(player.facing)
		Audio.play_sfx("whoosh")
		Feel.slash(player.global_position + player.facing * 26.0, player.facing.angle())
	player.attack_hitbox.set_active(true)

func exit() -> void:
	player._attack_is_down = false
	player.attack_hitbox.position = SIDE_HITBOX_POS
	player.attack_hitbox.set_active(false)

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
