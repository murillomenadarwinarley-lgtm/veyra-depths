class_name Projectile
extends Area2D
## Proyectil reutilizable (enemigos ranged, trampas, NPCs hostiles).
## Se mueve en línea recta, hace daño con la Hitbox hija (sistema
## hitbox/hurtbox existente) y se destruye al impactar (jugador/cuerpo),
## al superar su vida útil o al alejarse demasiado de su origen.

signal destroyed

@export var speed: float = 300.0
## Vida útil en segundos antes de destruirse.
@export var life_time: float = 3.0
## Distancia máxima recorrida antes de destruirse (0.0 = sin límite).
## Cubre "salió de la sala/pantalla" sin depender de la cámara.
@export var max_distance: float = 1200.0

@export var damage: int = 1
@export var knockback_strength: float = 150.0
@export var knockback_vertical: float = 0.0
## Ventana de i-frames que recibe la víctima. -1 = configuración de la
## hurtbox de la víctima.
@export var invulnerability_duration: float = -1.0

var _velocity: Vector2 = Vector2.ZERO
var _spawn_pos: Vector2 = Vector2.ZERO
var _alive: bool = true

@onready var hitbox: Hitbox = $Hitbox

func _ready() -> void:
	add_to_group("projectiles")
	hitbox.damage = damage
	hitbox.knockback_strength = knockback_strength
	hitbox.knockback_vertical = knockback_vertical
	hitbox.invulnerability_duration = invulnerability_duration
	hitbox.hit.connect(_on_hit)
	body_entered.connect(_on_body_entered)
	_spawn_pos = global_position
	get_tree().create_timer(life_time).timeout.connect(_die)

## Lanza el proyectil en `direction` (la velocidad se multiplica por
## `speed`; si se pasa una velocidad concreta, se usa esa).
func setup(direction: Vector2, launch_speed: float = -1.0) -> void:
	_velocity = direction.normalized() * (launch_speed if launch_speed > 0.0 else speed)

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	position += _velocity * delta
	if max_distance > 0.0 and global_position.distance_to(_spawn_pos) > max_distance:
		_die()

func _on_hit(_hurtbox: Area2D) -> void:
	_die()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		return
	_die()

func _die() -> void:
	if not _alive:
		return
	_alive = false
	destroyed.emit()
	queue_free()
