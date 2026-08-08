class_name Player
extends CharacterBody2D
## Controlador del jugador.
## La lógica de comportamiento vive en el FSM de estados (Player/states/),
## no aquí. Este script solo registra los estados y expone los datos y
## temporizadores de movimiento: coyote time, buffer de salto y cooldown
## de dash. Todo el input se lee vía Input Map, así que funciona igual
## con teclado, mando y controles táctiles.

const MAX_FALL_SPEED := 900.0

var movement_speed: float = 240.0
var jump_velocity: float = -520.0
var coyote_time: float = 0.12
var jump_buffer_time: float = 0.15
var dash_cooldown_time: float = 0.5
var attack_cooldown_time: float = 0.3
## Duración del estado de daño (tras un golpe, antes de recuperar control).
var hurt_duration: float = 0.35
var facing: Vector2 = Vector2.RIGHT

var _coyote_time_left: float = 0.0
var _jump_buffer_time_left: float = 0.0
var _dash_cooldown_left: float = 0.0
var _attack_cooldown_left: float = 0.0
var _air_jumps: int = 0
var _jumped_this_frame := false
var _was_in_air := false
## Ataque en curso apuntando hacia abajo (pogo). Lo gestiona attack_state.
var _attack_is_down := false
## True mientras el arco activo corresponde a un arte de carga (más alma).
var _charged_attack := false

## Velocidad de rebote del pogo (golpear enemigos desde arriba en el aire).
var pogo_velocity: float = -420.0

@onready var state_machine: StateMachine = $StateMachine
@onready var health: HealthComponent = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var attack_hitbox: Hitbox = $AttackHitbox

func _ready() -> void:
	add_to_group("player")
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)
	attack_hitbox.hit.connect(_on_attack_hit)
	_register_states()
	# Espejo de salud hacia Progress (fuente de verdad persistible).
	Progress.set_player_health(health.health)

func _physics_process(delta: float) -> void:
	# Al saltar, is_on_floor() sigue siendo true un tick (el impulso se
	# aplica antes de move_and_slide): sin el flag, el coyote se refrescaría
	# y permitiría un doble salto accidental nada más despegar.
	if is_on_floor() and not _jumped_this_frame:
		_coyote_time_left = coyote_time
		_air_jumps = 0
		if _was_in_air:
			_on_landed()
	else:
		_coyote_time_left = maxf(_coyote_time_left - delta, 0.0)
	_was_in_air = not is_on_floor()
	_jumped_this_frame = false
	_jump_buffer_time_left = maxf(_jump_buffer_time_left - delta, 0.0)
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
	_attack_cooldown_left = maxf(_attack_cooldown_left - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_time_left = jump_buffer_time

## Eje horizontal del Input Map (-1.0 a 1.0). Los controles táctiles
## alimentan las mismas acciones, así que aquí no hay lógica duplicada.
func get_move_axis() -> float:
	return Input.get_axis("move_left", "move_right")

## True si el jugador puede saltar ahora mismo: está en el suelo o
## acaba de salir de él (coyote time) sin haber saltado ya en el aire.
func can_coyote_jump() -> bool:
	return is_on_floor() or (_coyote_time_left > 0.0 and _air_jumps == 0)

func consume_coyote() -> void:
	_coyote_time_left = 0.0

func set_jump_buffer() -> void:
	_jump_buffer_time_left = jump_buffer_time

## True si el salto se presionó recientemente; el buffer se consume.
func consume_jump_buffer() -> bool:
	if _jump_buffer_time_left > 0.0:
		_jump_buffer_time_left = 0.0
		return true
	return false

func clear_jump_buffer() -> void:
	_jump_buffer_time_left = 0.0

func do_jump() -> void:
	velocity.y = jump_velocity
	_air_jumps += 1
	_jumped_this_frame = true
	consume_coyote()
	clear_jump_buffer()
	Audio.play_sfx("jump")

## Límite de saltos aéreos: 1 base, +1 con doble salto desbloqueado.
func air_jump_limit() -> int:
	return 1 + (1 if Progress.has_ability("double_jump") else 0)

## True si puede hacer un salto aéreo (doble salto): en el aire,
## sin coyote y con saltos aéreos restantes. Se resetea al aterrizar.
func can_double_jump() -> bool:
	return not is_on_floor() and _air_jumps < air_jump_limit()

## Salto aéreo: re-aplica el impulso vertical sin tocar suelo.
## No consume coyote ni buffer.
func do_air_jump() -> void:
	velocity.y = jump_velocity
	_air_jumps += 1
	_jumped_this_frame = true
	clear_jump_buffer()
	Audio.play_sfx("jump")

## Saltos aéreos consumidos en este vuelo (para tests).
func air_jumps_used() -> int:
	return _air_jumps

## True si el ataque en curso es descendente (pogo).
func is_down_attack() -> bool:
	return _attack_is_down

## Rebote del pogo: impulsa hacia arriba y refresca los saltos aéreos
## (permite encadenar pogos o pogo + doble salto).
func pogo_bounce() -> void:
	velocity.y = pogo_velocity
	_air_jumps = 0
	_jumped_this_frame = true
	Feel.dust(global_position + Vector2(0, 18))
	Audio.play_sfx("jump")

func can_dash() -> bool:
	return _dash_cooldown_left <= 0.0

func use_dash() -> void:
	_dash_cooldown_left = dash_cooldown_time
	Audio.play_sfx("dash")
	Feel.dust(global_position + Vector2(0, 16))

func can_attack() -> bool:
	return _attack_cooldown_left <= 0.0

func use_attack() -> void:
	_attack_cooldown_left = attack_cooldown_time

## Arma equipada (definición del catálogo data/weapons/weapons.json).
func get_weapon() -> WeaponDefinition:
	return Weapons.get_definition(Progress.get_equipped_weapon())

func apply_gravity(delta: float) -> void:
	velocity.y = minf(velocity.y + get_gravity().y * delta, MAX_FALL_SPEED)

func _register_states() -> void:
	state_machine.add_state(&"idle", PlayerIdleState.new(state_machine, self))
	state_machine.add_state(&"run", PlayerRunState.new(state_machine, self))
	state_machine.add_state(&"jump", PlayerJumpState.new(state_machine, self))
	state_machine.add_state(&"dash", PlayerDashState.new(state_machine, self))
	state_machine.add_state(&"attack", PlayerAttackState.new(state_machine, self))
	state_machine.add_state(&"dive", PlayerDiveState.new(state_machine, self))
	state_machine.add_state(&"spell", PlayerSpellState.new(state_machine, self))
	state_machine.add_state(&"focus", PlayerFocusState.new(state_machine, self))
	state_machine.add_state(&"hurt", PlayerHurtState.new(state_machine, self))
	state_machine.change_to(&"idle")

func is_dead() -> bool:
	return health.is_dead()

## Reinicia salud y estado (al reintentar tras morir).
func reset() -> void:
	health.reset()
	hurtbox.invulnerable = false
	state_machine.change_to(&"idle")

func take_damage(amount: int) -> void:
	health.take_damage(amount)

func _on_health_changed(current: int, _max_health: int) -> void:
	Progress.set_player_health(current)

func _on_landed() -> void:
	Feel.dust(global_position + Vector2(0, 18))
	Audio.play_sfx("land")

func _on_damaged(amount: int, source: Node) -> void:
	var message := {"damage": amount}
	if source is Node2D:
		message["from"] = source.global_position
	state_machine.change_to(&"hurt", message)
	Feel.hitstop(0.05)
	Feel.screen_shake(0.28)
	Feel.flash(self, Color(1.0, 0.35, 0.35), 0.25)
	Audio.play_sfx("hurt")

func _on_died() -> void:
	Progress.register_death()
	Feel.burst(global_position, Color(0.0, 1.0, 1.0))
	Feel.screen_shake(0.45)
	Audio.play_sfx("death")
	Game.trigger_game_over()

func _on_attack_hit(hurtbox: Area2D) -> void:
	var victim := hurtbox.get_parent()
	var multiplier := 2 if victim != null and victim.is_in_group("boss") else 1
	var weapon := get_weapon()
	if weapon != null and _charged_attack:
		multiplier *= weapon.soul_multiplier
	Progress.add_soul(Progress.SOUL_PER_HIT * multiplier)
	Feel.hitstop(0.06)
	Feel.screen_shake(0.18)
	Feel.sparks(hurtbox.global_position)
	Audio.play_sfx("hit")
	# Pogo: en el aire, ataque descendente (o golpear claramente por encima
	# del enemigo) rebota al jugador en lugar de empujarlo.
	if not is_on_floor():
		var enemy := hurtbox.get_parent() as Node2D
		var above := enemy != null and global_position.y < enemy.global_position.y - 12.0
		if _attack_is_down or above:
			pogo_bounce()
