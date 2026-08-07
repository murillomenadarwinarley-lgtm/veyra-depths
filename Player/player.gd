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
var facing: Vector2 = Vector2.RIGHT

var _coyote_time_left: float = 0.0
var _jump_buffer_time_left: float = 0.0
var _dash_cooldown_left: float = 0.0
var _air_jumps: int = 0
var _jumped_this_frame := false

@onready var state_machine: StateMachine = $StateMachine

func _ready() -> void:
	add_to_group("player")
	_register_states()

func _physics_process(delta: float) -> void:
	# Al saltar, is_on_floor() sigue siendo true un tick (el impulso se
	# aplica antes de move_and_slide): sin el flag, el coyote se refrescaría
	# y permitiría un doble salto accidental nada más despegar.
	if is_on_floor() and not _jumped_this_frame:
		_coyote_time_left = coyote_time
		_air_jumps = 0
	else:
		_coyote_time_left = maxf(_coyote_time_left - delta, 0.0)
	_jumped_this_frame = false
	_jump_buffer_time_left = maxf(_jump_buffer_time_left - delta, 0.0)
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
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

func can_dash() -> bool:
	return _dash_cooldown_left <= 0.0

func use_dash() -> void:
	_dash_cooldown_left = dash_cooldown_time

func apply_gravity(delta: float) -> void:
	velocity.y = minf(velocity.y + get_gravity().y * delta, MAX_FALL_SPEED)

func _register_states() -> void:
	state_machine.add_state(&"idle", PlayerIdleState.new(state_machine, self))
	state_machine.add_state(&"run", PlayerRunState.new(state_machine, self))
	state_machine.add_state(&"jump", PlayerJumpState.new(state_machine, self))
	state_machine.add_state(&"dash", PlayerDashState.new(state_machine, self))
	state_machine.add_state(&"attack", PlayerAttackState.new(state_machine, self))
	state_machine.add_state(&"hurt", PlayerHurtState.new(state_machine, self))
	state_machine.change_to(&"idle")

func take_damage(amount: int) -> void:
	state_machine.change_to(&"hurt", {"damage": amount})
