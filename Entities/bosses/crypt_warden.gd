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
const VOLLEY_SPREAD := 0.28
const ARENA_MARGIN := 90.0
const PROJECTILE_SCENE := preload("res://Entities/projectiles/projectile.tscn")

enum BossState {
	DORMANT,
	AWAKEN,
	CHARGE_TELEGRAPH,
	CHARGING,
	VOLLEY_TELEGRAPH,
	VOLLEYING,
	RECOVERING,
}

var _state: BossState = BossState.DORMANT
var _state_time_left: float = 0.0
var _flash_timer: float = 0.0
var _charge_dir: float = 1.0
var _last_pattern: BossState = BossState.RECOVERING
var _barrier: Node = null

@onready var _hitbox: Hitbox = $Hitbox

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	($Health as HealthComponent).died.connect(_on_died)
	($Health as HealthComponent).damaged.connect(_on_damaged)
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
	if _state == BossState.CHARGING:
		_state_time_left -= delta
		velocity.x = _charge_dir * CHARGE_SPEED
		move_and_slide()
		position.x = clampf(position.x, ARENA_MARGIN, 1920.0 - ARENA_MARGIN)
		if _state_time_left <= 0.0 or position.x <= ARENA_MARGIN or position.x >= 1920.0 - ARENA_MARGIN:
			_hitbox.set_active(false)
			_enter_state(BossState.RECOVERING, 0.75)
		return
	_state_time_left -= delta
	velocity.x = 0.0
	match _state:
		BossState.AWAKEN:
			_drift_toward_player(55.0, delta)
			if _state_time_left <= 0.0:
				_pick_pattern()
		BossState.CHARGE_TELEGRAPH:
			_drift_toward_player(35.0, delta)
			_pulse_flash(delta)
			if _state_time_left <= 0.0:
				_enter_charge()
		BossState.VOLLEY_TELEGRAPH:
			_drift_toward_player(35.0, delta)
			_pulse_flash(delta)
			if _state_time_left <= 0.0:
				_fire_volley()
				_enter_state(BossState.VOLLEYING, 0.3)
		BossState.VOLLEYING:
			if _state_time_left <= 0.0:
				_enter_state(BossState.RECOVERING, 0.75)
		BossState.RECOVERING:
			_drift_toward_player(70.0, delta)
			if _state_time_left <= 0.0:
				_pick_pattern()
	position.x = clampf(position.x, ARENA_MARGIN, 1920.0 - ARENA_MARGIN)
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
	var patterns: Array[BossState] = [BossState.CHARGE_TELEGRAPH, BossState.VOLLEY_TELEGRAPH]
	var options := patterns.filter(func(s: BossState) -> bool: return s != _last_pattern)
	var chosen: BossState = options[randi() % options.size()]
	_last_pattern = chosen
	match chosen:
		BossState.CHARGE_TELEGRAPH:
			_enter_state(BossState.CHARGE_TELEGRAPH, 0.55)
		BossState.VOLLEY_TELEGRAPH:
			_enter_state(BossState.VOLLEY_TELEGRAPH, 0.6)

func _enter_charge() -> void:
	_enter_state(BossState.CHARGING, 0.42)
	var player := _find_player()
	if player != null:
		_charge_dir = 1.0 if player.global_position.x >= global_position.x else -1.0
	Audio.play_sfx("whoosh")
	_hitbox.set_active(true)

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
		projectile.setup(Vector2.from_angle(base_angle + (i - 1) * VOLLEY_SPREAD), 300.0)

func _drift_toward_player(speed: float, delta: float) -> void:
	var player := _find_player()
	if player == null:
		return
	velocity.x = move_toward(velocity.x, signf(player.global_position.x - global_position.x) * speed, 300.0 * delta)

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

## El jefe recibe daño del jugador: hitstop, shake y parpadeo.
func _on_damaged(amount: int, source: Node) -> void:
	Feel.flash(self, Color.WHITE, 0.15)
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
