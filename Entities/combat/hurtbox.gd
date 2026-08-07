class_name Hurtbox
extends Area2D
## Zona que recibe daño (la tienen las entidades con HealthComponent).
## Una hitbox (grupo "hitbox") que entra en contacto invoca receive_hit()
## de esta zona; aquí se aplica el daño al HealthComponent del padre y se
## emite damage_taken. La comunicación es por grupos + métodos duck-typed,
## sin chequeos directos de tipo. Gestiona la invulnerabilidad (i-frames).
## El daño NO se aplica desde area_entered de la hurtbox: cuando una hitbox
## alterna monitoring (ataques con hit_once), la víctima no vuelve a recibir
## area_entered en cada activación, así que el disparo lo hace la hitbox.

signal damage_taken(amount: int, source: Node2D)
signal invulnerability_started
signal invulnerability_ended

## Duración de los i-frames tras recibir un golpe (0.0 = sin i-frames).
@export var invulnerability_duration: float = 0.0
@export var apply_knockback: bool = true
@export var start_active: bool = true

var active: bool = true
var invulnerable: bool = false

var _body: Node2D
var _health: HealthComponent

func _ready() -> void:
	add_to_group("hurtbox")
	active = start_active
	monitoring = start_active
	_body = get_parent()
	_health = _find_health()

func _find_health() -> HealthComponent:
	if _body is Entity:
		return _body.get_component(HealthComponent) as HealthComponent
	return _body.get_node_or_null("Health") as HealthComponent

func receive_hit(hitbox: Hitbox) -> void:
	if not active or invulnerable or _health == null or _health.is_dead():
		return
	var attacker: Node2D = hitbox.get_attacker()
	if attacker == _body:
		return
	damage_taken.emit(hitbox.damage, attacker)
	_health.take_damage(hitbox.damage, attacker)
	if apply_knockback and _body is CharacterBody2D:
		var body := _body as CharacterBody2D
		var dir := 1.0
		if attacker:
			dir = signf(_body.global_position.x - attacker.global_position.x)
			if dir == 0.0:
				dir = 1.0
		body.velocity.x = dir * hitbox.knockback_strength
	if invulnerability_duration > 0.0:
		_start_invulnerability()

func _start_invulnerability() -> void:
	invulnerable = true
	invulnerability_started.emit()
	get_tree().create_timer(invulnerability_duration).timeout.connect(_end_invulnerability)

func _end_invulnerability() -> void:
	invulnerable = false
	invulnerability_ended.emit()
