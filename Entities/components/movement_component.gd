class_name MovementComponent
extends Node
## Componente de movimiento reutilizable.
## Opera sobre el nodo padre (la entidad) con aceleración/velocidad.
## Duck-typed: si el padre expone move_and_slide() (CharacterBody2D) se
## mueve con física; si no, desplaza la posición directamente (Node2D).

@export var max_speed: float = 120.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0
@export var gravity: float = 900.0
@export var max_fall_speed: float = 900.0

var facing: Vector2 = Vector2.RIGHT

var _actor: Node2D = null
var _uses_physics: bool = false
var _velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	_actor = get_parent() as Node2D
	_uses_physics = _actor != null and _actor.has_method("move_and_slide")

## Velocidad actual. Si el actor usa física (CharacterBody2D), la
## velocidad vive en el actor (así el knockback externo se respeta);
## si no, se guarda aquí.
var velocity: Vector2:
	get:
		return _actor.velocity if _uses_physics else _velocity
	set(value):
		if _uses_physics:
			_actor.velocity = value
		_velocity = value

func apply_gravity(delta: float) -> void:
	var v := velocity
	v.y = minf(v.y + gravity * delta, max_fall_speed)
	velocity = v

## Acelera hacia la dirección * velocidad máxima (opcional override de
## velocidad, p.ej. velocidad de patrulla vs persecución).
func move_towards(direction: Vector2, delta: float, speed: float = -1.0) -> void:
	var target_speed: float = max_speed if speed < 0.0 else speed
	var v := velocity
	v.x = move_toward(v.x, direction.x * target_speed, acceleration * delta)
	velocity = v
	if direction.x > 0.01:
		facing = Vector2.RIGHT
	elif direction.x < -0.01:
		facing = Vector2.LEFT

## Frena en horizontal (fricción).
func stop(delta: float) -> void:
	var v := velocity
	v.x = move_toward(v.x, 0.0, friction * delta)
	velocity = v

## Aplica la velocidad al actor. CharacterBody2D -> move_and_slide();
## Node2D -> desplazamiento directo.
func apply_motion(delta: float) -> void:
	if _actor == null:
		return
	if _uses_physics:
		_actor.move_and_slide()
	else:
		_actor.position += _velocity * delta
