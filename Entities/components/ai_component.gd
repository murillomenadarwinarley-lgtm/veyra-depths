class_name AIComponent
extends Node
## Componente de IA reutilizable: patrulla -> detecta -> persigue -> ataca
## -> vuelve a patrulla si pierde de vista al jugador.
## Operación por composición: usa MovementComponent para moverse.
## La IA SOLO decide CUÁNDO atacar (rango + cooldown de AttackComponent);
## el CÓMO ataca (telegrafía -> hitbox -> embestida) lo posee
## AttackComponent, así una variante de ataque no toca este script.
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
## Distancia mínima de seguridad: si el jugador se acerca más que esto,
## el enemigo huye en vez de perseguir (0.0 = desactivado). Útil para
## enemigos ranged que no quieren cuerpo a cuerpo.
@export var retreat_range: float = 0.0

# Movimiento (patrulla y persecución; la embestida es del ataque).
@export var patrol_half_width: float = 120.0
@export var patrol_speed: float = 60.0
@export var chase_speed: float = 140.0

var current_state: AIState = AIState.IDLE

var home_x: float = 0.0

var _actor: Node2D = null
var _movement: MovementComponent = null
var _attack: AttackComponent = null
var _player: Node2D = null
var _patrol_dir: float = 1.0

func _ready() -> void:
	_actor = get_parent() as Node2D
	if _actor:
		home_x = _actor.global_position.x
		_movement = _actor.get_component(MovementComponent) as MovementComponent
		_attack = _actor.get_component(AttackComponent) as AttackComponent
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
	if _has_ground_ahead(_patrol_dir):
		_movement.move_towards(Vector2(_patrol_dir, 0.0), delta, patrol_speed)
	else:
		_movement.stop(delta)

func _tick_chase(delta: float) -> void:
	var dist := _player_distance()
	if _player == null or dist > chase_range:
		set_state(AIState.PATROL)
		return
	var dir := 1.0 if _player.global_position.x >= _actor.global_position.x else -1.0
	# Mantener distancia: si el jugador se acerca demasiado, huye en vez
	# de perseguir (genérico: cualquier enemigo puede usarlo).
	if retreat_range > 0.0 and dist < retreat_range:
		_movement.move_towards(Vector2(-dir, 0.0), delta, chase_speed)
		return
	if dist <= attack_range and _attack != null and _attack.can_attack():
		if _attack.start_attack():
			set_state(AIState.ATTACK)
		return
	# No caminar hacia el vacío: si no hay suelo delante, no avanzar
	# (los enemigos no se tiran a los pozos persiguiendo al jugador).
	if _has_ground_ahead(dir):
		_movement.move_towards(Vector2(dir, 0.0), delta, chase_speed)
	else:
		_movement.stop(delta)

## True si hay suelo debajo del borde en `dir` (sonda física bajo el pie).
## Evita que los enemigos caminen fuera de plataformas al patrullar o
## perseguir. Si la sonda falla (sin space_state), se asume seguro.
func _has_ground_ahead(dir: float) -> bool:
	if _actor == null or not _actor.is_inside_tree():
		return true
	var space := _actor.get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = Vector2(
		_actor.global_position.x + dir * 16.0,
		_actor.global_position.y + 34.0
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [_actor.get_rid()]
	return not space.intersect_point(query).is_empty()

## Mientras dura el ataque, la IA se limita a pasarle la dirección hacia el
## jugador; el ciclo telegrafía -> golpe -> fin lo posee AttackComponent.
## Al terminar, vuelve a perseguir o a patrullar si perdió de vista.
func _tick_attack(delta: float) -> void:
	if _attack == null or not _attack.process_attack(delta, _dir_to_player()):
		if _player_distance() > chase_range:
			set_state(AIState.PATROL)
		else:
			set_state(AIState.CHASE)

func _dir_to_player() -> Vector2:
	if _player == null:
		return _movement.facing
	return Vector2(1.0 if _player.global_position.x >= _actor.global_position.x else -1.0, 0.0)
