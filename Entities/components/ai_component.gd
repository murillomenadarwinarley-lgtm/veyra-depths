class_name AIComponent
extends Node
## Componente de IA reutilizable: patrulla -> detecta -> persigue -> ataca
## -> vuelve a patrulla si pierde de vista al jugador.
## Operación por composición: usa MovementComponent para moverse y
## AttackComponent (junto a la Hitbox del enemigo) para golpear.
## Todos los parámetros de dificultad son @export para ajustarlos sin
## tocar código.

enum AIState { IDLE, PATROL, CHASE, ATTACK }

signal state_changed(old_state: AIState, new_state: AIState)

@export var enabled: bool = false
@export var starting_state: AIState = AIState.IDLE

# Detección (rango de visión y de pérdida del jugador).
@export var detection_range: float = 240.0
@export var chase_range: float = 320.0
@export var attack_range: float = 48.0

# Movimiento.
@export var patrol_half_width: float = 120.0
@export var patrol_speed: float = 60.0
@export var chase_speed: float = 140.0
@export var attack_speed: float = 120.0

# Ataque (telegrafía y ventana activa del golpe).
@export var attack_telegraph_time: float = 0.4
@export var attack_active_time: float = 0.2

var current_state: AIState = AIState.IDLE

var home_x: float = 0.0

var _actor: Node2D = null
var _movement: MovementComponent = null
var _attack: AttackComponent = null
var _hitbox: Hitbox = null
var _player: Node2D = null
var _patrol_dir: float = 1.0
var _attack_timer: float = 0.0
var _in_attack_active: bool = false

func _ready() -> void:
	_actor = get_parent() as Node2D
	if _actor:
		home_x = _actor.global_position.x
		_movement = _actor.get_component(MovementComponent) as MovementComponent
		_attack = _actor.get_component(AttackComponent) as AttackComponent
		_hitbox = _actor.get_node_or_null("Hitbox") as Hitbox
	current_state = starting_state

func set_state(new_state: AIState) -> void:
	if current_state == new_state:
		return
	var old := current_state
	current_state = new_state
	state_changed.emit(old, new_state)

func _get_player() -> Node2D:
	for node in get_tree().get_nodes_in_group("player"):
		if node is Node2D and is_instance_valid(node):
			return node as Node2D
	return null

func _player_distance() -> float:
	if _player == null:
		return INF
	return _actor.global_position.distance_to(_player.global_position)

func _physics_process(delta: float) -> void:
	if not enabled or _movement == null or _actor == null:
		return
	_player = _get_player()
	_movement.apply_gravity(delta)
	match current_state:
		AIState.IDLE:
			_tick_idle(delta)
		AIState.PATROL:
			_tick_patrol(delta)
		AIState.CHASE:
			_tick_chase(delta)
		AIState.ATTACK:
			_tick_attack(delta)
	_movement.apply_motion(delta)

func _tick_idle(delta: float) -> void:
	_movement.stop(delta)
	if _player_distance() <= detection_range:
		set_state(AIState.CHASE)

## Va y viene en [home - half, home + half].
func _tick_patrol(delta: float) -> void:
	if _player_distance() <= detection_range:
		set_state(AIState.CHASE)
		return
	if _patrol_dir > 0.0 and _actor.global_position.x >= home_x + patrol_half_width:
		_patrol_dir = -1.0
	elif _patrol_dir < 0.0 and _actor.global_position.x <= home_x - patrol_half_width:
		_patrol_dir = 1.0
	_movement.move_towards(Vector2(_patrol_dir, 0.0), delta, patrol_speed)

func _tick_chase(delta: float) -> void:
	var dist := _player_distance()
	if _player == null or dist > chase_range:
		set_state(AIState.PATROL)
		return
	if dist <= attack_range and _attack != null and _attack.can_attack():
		_begin_attack()
		return
	var dir := 1.0 if _player.global_position.x >= _actor.global_position.x else -1.0
	_movement.move_towards(Vector2(dir, 0.0), delta, chase_speed)

## Fase 1 (telegrafía): se queda quieto avisando y mirando al jugador.
## Fase 2 (activa): activa la hitbox y embiste hacia el jugador.
func _begin_attack() -> void:
	_in_attack_active = false
	_attack_timer = attack_telegraph_time
	set_state(AIState.ATTACK)

func _tick_attack(delta: float) -> void:
	_attack_timer -= delta
	if not _in_attack_active:
		_movement.stop(delta)
		_face_player()
		if _attack_timer <= 0.0:
			_in_attack_active = true
			_attack_timer = attack_active_time
			_attack.attack()
			if _hitbox:
				_hitbox.set_direction(_movement.facing)
				_hitbox.set_active(true)
	else:
		if _player != null:
			var dir := 1.0 if _player.global_position.x >= _actor.global_position.x else -1.0
			_movement.move_towards(Vector2(dir, 0.0), delta, attack_speed)
		if _attack_timer <= 0.0:
			if _hitbox:
				_hitbox.set_active(false)
			if _player_distance() > chase_range:
				set_state(AIState.PATROL)
			else:
				set_state(AIState.CHASE)

func _face_player() -> void:
	if _player == null:
		return
	var dir := 1.0 if _player.global_position.x >= _actor.global_position.x else -1.0
	_movement.facing = Vector2(dir, 0.0)
