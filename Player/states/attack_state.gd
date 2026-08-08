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
## Tope de mantenimiento de la carga: pasado este tiempo se dispara sola.
const MAX_HOLD_TIME := 2.5
## Fracción de movement_speed a la que se camina mientras se carga: el
## arte de carga te fija en el sitio (riesgo = recompensa en dificultad).
const CHARGE_MOVE_FACTOR := 0.35

var _time_left: float = 0.0
var _down_attack := false
var _charging := false
var _charged := false
var _charge_time_left: float = 0.0
var _lunge_time_left: float = 0.0
var _lunge_speed: float = 0.0
var _weapon: WeaponDefinition = null

func enter(_message: Dictionary = {}) -> void:
	# En el aire + manteniendo abajo: ataque descendente. Con la habilidad
	# "dive", ese combo es el buceo (se redirige a su estado).
	_down_attack = not player.is_on_floor() and Input.is_action_pressed("down")
	if _down_attack and Progress.has_ability("dive"):
		state_machine.change_to(&"dive")
		return
	_weapon = player.get_weapon()
	player.attack_cooldown_time = _weapon.attack_cooldown if _weapon != null else 0.3
	player.use_attack()
	player._charged_attack = false
	# Las armas con arte de carga disparan al soltar (o al agotar el tope);
	# las demás atacan al instante, como siempre.
	_charging = _weapon != null and _weapon.can_charge() and Input.is_action_pressed("attack")
	if _charging:
		_charge_time_left = _weapon.charge_time
		_time_left = MAX_HOLD_TIME
		Feel.flash(player, Color(0.45, 0.85, 1.0), 0.12)
	else:
		_fire(false)

func exit() -> void:
	player._attack_is_down = false
	player._charged_attack = false
	player.attack_hitbox.position = SIDE_HITBOX_POS
	player.attack_hitbox.set_active(false)

func physics_process(delta: float) -> void:
	_time_left -= delta
	if _charging:
		_process_charging(delta)
		return
	if _lunge_time_left > 0.0:
		_lunge_time_left -= delta
		player.velocity.x = player.facing.x * _lunge_speed
	if not player.is_on_floor():
		player.apply_gravity(delta)
	player.move_and_slide()
	if _time_left <= 0.0:
		if player.is_on_floor():
			state_machine.change_to(&"idle")
		else:
			state_machine.change_to(&"jump")

## Fase de carga: te quedas expuesto a media marcha mientras el filo se
## carga; al soltar (o al agotar el tope) sale el tajo, cargado o no.
func _process_charging(delta: float) -> void:
	var axis := player.get_move_axis()
	if axis != 0.0:
		player.facing = Vector2(axis, 0.0)
	player.velocity.x = move_toward(player.velocity.x, axis * player.movement_speed * CHARGE_MOVE_FACTOR, 900.0 * delta)
	if not player.is_on_floor():
		player.apply_gravity(delta)
	player.move_and_slide()
	if not _charged:
		_charge_time_left -= delta
		if _charge_time_left <= 0.0:
			_charged = true
			Audio.play_sfx("charge")
			Feel.flash(player, Color(0.55, 0.95, 1.0), 0.3)
			Feel.screen_shake(0.06)
	if Input.is_action_just_released("attack") or _time_left <= 0.0:
		_fire(_charged)

## Activa el golpe con las estadísticas del arma (cargadas o básicas).
func _fire(charged: bool) -> void:
	_charging = false
	_time_left = ATTACK_DURATION
	player._charged_attack = charged
	var damage: int = _weapon.charge_damage if charged and _weapon != null else _weapon.damage
	var arc: Vector2 = _weapon.charge_arc_size if charged and _weapon != null else _weapon.arc_size
	var knockback: float = _weapon.charge_knockback if charged and _weapon != null else _weapon.knockback
	var arc_shape := player.attack_hitbox.get_node_or_null("CollisionShape2D")
	if arc_shape != null and arc_shape.shape is RectangleShape2D:
		(arc_shape.shape as RectangleShape2D).size = arc
	player.attack_hitbox.damage = damage
	player.attack_hitbox.knockback_strength = knockback
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
	if charged and _weapon != null:
		_lunge_time_left = _weapon.charge_lunge_time
		_lunge_speed = _weapon.charge_lunge_speed
		Feel.hitstop(0.08)
		Feel.screen_shake(0.25)
	else:
		_lunge_time_left = 0.0
		_lunge_speed = 0.0
