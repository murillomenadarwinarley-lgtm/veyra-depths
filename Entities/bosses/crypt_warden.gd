class_name CryptWarden
extends CharacterBody2D
## Guardián de la Cripta Sepultada: jefe que flota sobre la arena y
## alterna embestidas y andanadas de proyectiles. Se activa al entrar
## el jugador, bloquea la salida con la barrera y se registra derrotado
## en Progress (la puerta de la caverna se desbloquea sola).
##
## Patrones: AWAKEN (presentación) -> [CHARGE | VOLLEY] -> RECOVER ->
## (repite). Cada patrón tiene su telegraph parpadeante antes de ejecutar.
## No extiende Enemy (que es Node2D): duplica el cableado mínimo de
## health/hitbox porque el jefe necesita ser CharacterBody2D.

const BOSS_ID := "crypt_warden"
const HOVER_Y := -1200.0
const CHARGE_SPEED := 560.0
const DIVE_SPEED := 620.0
const GLIDE_SPEED := 155.0
const VOLLEY_SPREAD := 0.28
const ARENA_MARGIN := 90.0
const ARENA_TOP_Y := -1750.0
const ARENA_FLOOR_Y := -1190.0
## Al bajar de la mitad de vida el jefe se enfurece: planea más rápido,
## telegrafía menos y encadena patrones con menos respiro.
const ENRAGE_HP_FRACTION := 0.5
const ENRAGE_SPEED_MULT := 1.35
const ENRAGE_PATTERN_MULT := 0.75
const PROJECTILE_SCENE := preload("res://Entities/projectiles/projectile.tscn")

enum BossState {
	DORMANT,
	AWAKEN,
	CHARGE_TELEGRAPH,
	CHARGING,
	DIVE_TELEGRAPH,
	DIVING,
	VOLLEY_TELEGRAPH,
	VOLLEYING,
	RECOVERING,
}

var _state: BossState = BossState.DORMANT
var _state_time_left: float = 0.0
var _flash_timer: float = 0.0
var _charge_dir: float = 1.0
var _last_pattern: BossState = BossState.RECOVERING
var _enraged: bool = false
var _barrier: Node = null

@onready var _hitbox: Hitbox = $Hitbox
@onready var _health: HealthComponent = $Health

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	_health.died.connect(_on_died)
	_health.damaged.connect(_on_damaged)
	_hitbox.hit.connect(_on_hit)
	if Progress.is_boss_defeated(BOSS_ID):
		queue_free()
		return
	_barrier = get_node_or_null("../BossBarrier")
	position.y = HOVER_Y
	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if _state == BossState.DORMANT:
		var player := _find_player()
		if player != null and player.global_position.y > -1700.0:
			_start_fight()
		return
	_state_time_left -= delta
	match _state:
		BossState.CHARGING:
			_tick_charge(delta)
		BossState.DIVING:
			_tick_dive(delta)
		BossState.AWAKEN:
			_glide_toward_player(_glide_speed() * 0.9, delta)
			if _state_time_left <= 0.0:
				_pick_pattern()
		BossState.CHARGE_TELEGRAPH:
			_glide_toward_player(_glide_speed() * 0.7, delta)
			_pulse_flash(delta)
			if _state_time_left <= 0.0:
				_enter_charge()
		BossState.DIVE_TELEGRAPH:
			_glide_toward_player(_glide_speed() * 0.7, delta)
			_pulse_flash(delta)
			if _state_time_left <= 0.0:
				_enter_dive()
		BossState.VOLLEY_TELEGRAPH:
			_glide_toward_player(_glide_speed() * 0.7, delta)
			_pulse_flash(delta)
			if _state_time_left <= 0.0:
				_fire_volley()
				_enter_state(BossState.VOLLEYING, 0.3)
		BossState.VOLLEYING:
			if _state_time_left <= 0.0:
				_enter_state(BossState.RECOVERING, 0.6)
		BossState.RECOVERING:
			_glide_toward_player(_glide_speed(), delta)
			if _state_time_left <= 0.0:
				_pick_pattern()
	position.x = clampf(position.x, ARENA_MARGIN, 1920.0 - ARENA_MARGIN)
	position.y = clampf(position.y, ARENA_TOP_Y, ARENA_FLOOR_Y)
	move_and_slide()

func _start_fight() -> void:
	_enter_state(BossState.AWAKEN, 0.9)
	Audio.play_sfx("roar")
	Feel.screen_shake(0.3)
	Feel.flash(self, Color.WHITE, 0.2)
	if _barrier != null:
		_barrier.show()
		_barrier.set_deferred("collision_layer", 1)

func _pick_pattern() -> void:
	var patterns: Array[BossState] = [BossState.CHARGE_TELEGRAPH, BossState.VOLLEY_TELEGRAPH, BossState.DIVE_TELEGRAPH]
	var options := patterns.filter(func(s: BossState) -> bool: return s != _last_pattern)
	var chosen: BossState = options[randi() % options.size()]
	_last_pattern = chosen
	# Jitter en las duraciones: los tiempos exactos nunca se repiten.
	var jitter := randf_range(0.9, 1.1) * _pattern_mult()
	match chosen:
		BossState.CHARGE_TELEGRAPH:
			_enter_state(BossState.CHARGE_TELEGRAPH, 0.5 * jitter)
		BossState.DIVE_TELEGRAPH:
			_enter_state(BossState.DIVE_TELEGRAPH, 0.55 * jitter)
		BossState.VOLLEY_TELEGRAPH:
			_enter_state(BossState.VOLLEY_TELEGRAPH, 0.6 * jitter)

func _enter_charge() -> void:
	_enter_state(BossState.CHARGING, 0.42)
	var player := _find_player()
	if player != null:
		_charge_dir = 1.0 if player.global_position.x >= global_position.x else -1.0
	Audio.play_sfx("whoosh")
	_hitbox.set_active(true)

func _tick_charge(delta: float) -> void:
	velocity.x = _charge_dir * CHARGE_SPEED
	move_and_slide()
	if _state_time_left <= 0.0 or position.x <= ARENA_MARGIN or position.x >= 1920.0 - ARENA_MARGIN:
		_hitbox.set_active(false)
		_enter_state(BossState.RECOVERING, 0.6)

## Picado: el jefe se deja caer a toda velocidad sobre la arena y golpea
## el suelo con un estruendo (contacto dañino durante todo el descenso).
func _enter_dive() -> void:
	_enter_state(BossState.DIVING, 0.9)
	Audio.play_sfx("whoosh")
	_hitbox.set_active(true)

func _tick_dive(delta: float) -> void:
	velocity.y = minf(velocity.y + 3400.0 * delta, DIVE_SPEED)
	var player := _find_player()
	if player != null:
		velocity.x = move_toward(velocity.x, signf(player.global_position.x - global_position.x) * CHARGE_SPEED * 0.5, 700.0 * delta)
	move_and_slide()
	if global_position.y >= ARENA_FLOOR_Y or _state_time_left <= 0.0:
		_hitbox.set_active(false)
		if global_position.y >= ARENA_FLOOR_Y:
			Audio.play_sfx("land")
			Feel.screen_shake(0.3)
			Feel.dust(global_position + Vector2(0.0, 30.0))
			Feel.burst(global_position + Vector2(0.0, 30.0), Color(0.85, 0.6, 0.2))
		_enter_state(BossState.RECOVERING, 0.55)

func _fire_volley() -> void:
	var player := _find_player()
	Audio.play_sfx("whoosh")
	if player == null:
		return
	var base_angle := (player.global_position - global_position).angle()
	for i in range(3):
		var projectile: Area2D = PROJECTILE_SCENE.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = global_position + Vector2(0.0, -10.0)
		projectile.setup(Vector2.from_angle(base_angle + (i - 1) * VOLLEY_SPREAD), 340.0)

## Planeo: el jefe se desliza hacia el jugador en AMBOS ejes (nunca se
## queda clavado) con un cabeceo sinusoidal para que el vuelo respire.
func _glide_toward_player(speed: float, delta: float) -> void:
	var player := _find_player()
	if player == null:
		return
	var target_y := player.global_position.y + sin(Time.get_ticks_msec() / 300.0) * 28.0
	velocity.x = move_toward(velocity.x, signf(player.global_position.x - global_position.x) * speed, 460.0 * delta)
	velocity.y = move_toward(velocity.y, signf(target_y - global_position.y) * speed * 0.55, 340.0 * delta)

func _glide_speed() -> float:
	return GLIDE_SPEED * (ENRAGE_SPEED_MULT if _enraged else 1.0)

func _pattern_mult() -> float:
	return ENRAGE_PATTERN_MULT if _enraged else 1.0

func _pulse_flash(delta: float) -> void:
	_flash_timer -= delta
	if _flash_timer <= 0.0:
		_flash_timer = 0.13
		Feel.flash(self, Color.WHITE, 0.13)

func _enter_state(state: BossState, duration: float) -> void:
	_state = state
	_state_time_left = duration

func _find_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

## Recibe un golpe propio (contacto): feedback ligero.
func _on_hit(_hurtbox: Area2D) -> void:
	Feel.sparks(global_position + Vector2(0.0, -18.0))
	Audio.play_sfx("hit")

## El jefe recibe daño del jugador: hitstop, shake y parpadeo. Al caer por
## debajo de la mitad de vida se enfurece (ruge y acelera el ritmo).
func _on_damaged(amount: int, source: Node) -> void:
	Feel.flash(self, Color.WHITE, 0.15)
	if not _enraged and not _health.is_dead() and _health.health <= _health.max_health * ENRAGE_HP_FRACTION:
		_enraged = true
		Audio.play_sfx("roar")
		Feel.screen_shake(0.25)
	if source is Player:
		Feel.hitstop(0.05)
		Feel.screen_shake(0.18)
		Audio.play_sfx("hit")
		Feel.sparks(global_position + Vector2(0.0, -18.0))
	else:
		Feel.sparks(global_position + Vector2(0.0, -18.0))

func _on_died() -> void:
	Progress.defeat_boss(BOSS_ID)
	Audio.play_sfx("death")
	Feel.hitstop(0.12)
	Feel.screen_shake(0.45)
	var color := Color(1.0, 0.15, 0.6)
	Feel.burst(global_position, color)
	Feel.burst(global_position + Vector2(-40.0, -25.0), color)
	Feel.burst(global_position + Vector2(40.0, -30.0), color)
	if _barrier != null:
		_barrier.queue_free()
	var player := get_tree().get_first_node_in_group("player")
	if player is Player:
		player.health.heal(3)
	var room := _find_room()
	if room is Room:
		Progress.register_enemy_defeated(room.room_id, name)
	queue_free()

## Sube por el árbol hasta la sala (Room) a la que pertenece el jefe.
func _find_room() -> Node:
	var current: Node = get_parent()
	while current != null:
		if current is Room:
			return current
		current = current.get_parent()
	return null
