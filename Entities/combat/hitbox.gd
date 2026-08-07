class_name Hitbox
extends Area2D
## Zona que inflige daño (jugador al atacar, enemigos al golpear por
## contacto). Detecta hurtboxes (grupo "hurtbox") y, al entrar en contacto,
## invoca receive_hit() de la hurtbox (el daño lo aplica la hurtbox, no este
## nodo) y emite la señal hit() para observadores (audio, VFX, etc.).
## Comunicación por grupos + métodos duck-typed: sin chequeos directos de
## tipo. Recorrer receive_hit() directamente (en lugar de depender del
## area_entered de la víctima) es fiable con hitboxes que alternan
## monitoring: su propio area_entered se emite en cada activación.

signal hit(hurtbox: Area2D)

@export var damage: int = 1
@export var knockback_strength: float = 250.0
@export var hit_once: bool = true
## Cooldown entre golpes (0.0 = sin cooldown). Útil para daño de contacto.
@export var cooldown: float = 0.0
@export var start_active: bool = false
## Ventana de i-frames que recibe la víctima al ser golpeada por esta
## hitbox. -1 = la víctima usa la configuración de su hurtbox.
@export var invulnerability_duration: float = -1.0

var active: bool = false

var _last_hit_time: float = -INF

func _ready() -> void:
	add_to_group("hitbox")
	area_entered.connect(_on_area_entered)
	set_active(start_active)

## Activar/desactivar la detección. Se difiere porque set_active puede
## llamarse dentro de un callback de señal (hit_once), donde cambiar
## monitoring directamente está bloqueado por el motor.
func set_active(value: bool) -> void:
	active = value
	set_deferred("monitoring", value)

## Orienta la hitbox según la dirección (para ataques frontales).
func set_direction(dir: Vector2) -> void:
	var sign_x := 1.0 if dir.x >= 0.0 else -1.0
	position.x = absf(position.x) * sign_x

## El nodo que ataca (el padre). Se usa para calcular el knockback.
func get_attacker() -> Node2D:
	return get_parent() as Node2D

func _on_area_entered(area: Area2D) -> void:
	if not active:
		return
	if not area.is_in_group("hurtbox"):
		return
	if area.get_parent() == get_parent():
		return
	if cooldown > 0.0 and Time.get_ticks_msec() / 1000.0 - _last_hit_time < cooldown:
		return
	_last_hit_time = Time.get_ticks_msec() / 1000.0
	hit.emit(area)
	if area.has_method("receive_hit"):
		area.receive_hit(self)
	if hit_once:
		set_active(false)
