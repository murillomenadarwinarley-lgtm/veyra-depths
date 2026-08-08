class_name AttackComponent
extends Node
## Componente de ataque: posee TODO el ciclo del ataque (telegrafía ->
## fase activa -> fin) y sincroniza la hitbox del enemigo con sus
## parámetros. La IA (AIComponent) solo decide CUÁNDO atacar
## (can_attack()/start_attack()); el CÓMO ataca vive aquí, así una variante
## (p.ej. ataque a distancia) puede heredar y sobreescribir
## _begin_hit_phase() sin tocar ai_component.gd.

signal attack_started
signal attack_hit_phase
signal attack_finished

@export var damage: int = 2
## Cooldown entre golpes (0.0 = sin cooldown). Se mide desde el inicio de la
## fase activa (cuando la hitbox se activa), como antes.
@export var cooldown: float = 1.0
## Ventana de i-frames que recibe la víctima al ser golpeada por este
## ataque. -1 = la víctima usa su propia configuración de hurtbox.
@export var invulnerability_duration: float = -1.0
## Fase 1 del ataque: duración de la telegrafía (el atacante se queda
## quieto mirando al objetivo antes del golpe).
@export var telegraph_time: float = 0.4
## Fase 2 del ataque: duración de la ventana activa (hitbox conectada).
@export var active_time: float = 0.2
## Velocidad de embestida durante la fase activa.
@export var dash_speed: float = 120.0

enum Phase { IDLE, TELEGRAPH, ACTIVE }

var phase: Phase = Phase.IDLE

var _last_attack_time: float = -INF
var _phase_time_left: float = 0.0
var _actor: Node2D = null
var _movement: MovementComponent = null
var _hitbox: Hitbox = null

func _ready() -> void:
	_actor = get_parent() as Node2D
	if _actor:
		_movement = _actor.get_component(MovementComponent) as MovementComponent
		_hitbox = _actor.get_component(Hitbox) as Hitbox
	if _hitbox:
		_hitbox.damage = damage
		_hitbox.cooldown = cooldown
		_hitbox.invulnerability_duration = invulnerability_duration
	elif _actor and _requires_hitbox():
		push_warning("AttackComponent: entidad '%s' sin Hitbox: el ataque no hará daño" % _actor.name)
	# Patrón claro: el parpadeo durante la telegrafía avisa del golpe
	# (respuesta a "cuándo esquivar").
	attack_started.connect(_on_attack_started)

func _on_attack_started() -> void:
	if _actor != null:
		Feel.flash(_actor, Color.WHITE, telegraph_time)

func can_attack() -> bool:
	return phase == Phase.IDLE and Time.get_ticks_msec() / 1000.0 - _last_attack_time >= cooldown

## Inicia el ataque (telegrafía). Devuelve false si está en cooldown o ya
## hay un ataque en curso.
func start_attack() -> bool:
	if not can_attack():
		return false
	_phase_time_left = telegraph_time
	phase = Phase.TELEGRAPH
	attack_started.emit()
	return true

## Avanza el ataque un frame. `direction` es hacia dónde atacar
## (normalmente hacia el jugador; lo decide la IA). Devuelve true mientras
## el ataque siga en curso y false al terminar.
func process_attack(delta: float, direction: Vector2) -> bool:
	match phase:
		Phase.TELEGRAPH:
			if _movement:
				_movement.stop(delta)
				_face(direction)
			_phase_time_left -= delta
			if _phase_time_left <= 0.0:
				_begin_hit_phase(direction)
		Phase.ACTIVE:
			if _movement and _phase_time_left > 0.0:
				_movement.move_towards(direction, delta, dash_speed)
			_phase_time_left -= delta
			if _phase_time_left <= 0.0:
				_finish_attack()
	return phase != Phase.IDLE

## Punto de extensión: una variante (ataque a distancia, área, combo...)
## sobreescribe `_do_hit()` (o directamente `_begin_hit_phase()`) para
## disparar un proyectil o lo que sea en `direction`.
func _begin_hit_phase(direction: Vector2) -> void:
	_phase_time_left = active_time
	phase = Phase.ACTIVE
	_last_attack_time = Time.get_ticks_msec() / 1000.0
	_do_hit(direction)
	attack_hit_phase.emit()

## Golpe por defecto: activa la hitbox frontal del enemigo.
func _do_hit(direction: Vector2) -> void:
	if _hitbox:
		_hitbox.set_direction(direction)
		_hitbox.set_active(true)

## False en variantes que no necesitan hitbox propia (p.ej. ataques a
## distancia): evita el aviso de "sin Hitbox" en _ready.
func _requires_hitbox() -> bool:
	return true

func _finish_attack() -> void:
	# Desactivar SIEMPRE la hitbox al terminar: el siguiente ataque la
	# reactiva y ese toggle de monitoring re-emite area_entered por los
	# solapamientos ya existentes (única vía fiable de daño repetido de
	# contacto; mantenerla activa rompería el ciclo).
	if _hitbox:
		_hitbox.set_active(false)
	phase = Phase.IDLE
	attack_finished.emit()

func _face(direction: Vector2) -> void:
	if _movement == null:
		return
	if direction.x > 0.01:
		_movement.facing = Vector2.RIGHT
	elif direction.x < -0.01:
		_movement.facing = Vector2.LEFT
