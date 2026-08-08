class_name PlayerDiveState
extends PlayerState
## Buceo (habilidad "dive"): en el aire con abajo + ataque, el jugador cae
## en picado. Golpea a los enemigos durante la caída (2 de daño, i-frames
## de víctima de 1s para no golpear repetido) y al aterrizar genera una
## onda expansiva (2 de daño en área, ignora i-frames de la víctima).
## Durante la caída el jugador es invulnerable (estilo Desolate Dive).

const DIVE_FALL_SPEED := 1100.0
const DIVE_DAMAGE := 2
const FALL_HITBOX_RADIUS := 26.0
const SHOCKWAVE_DAMAGE := 2
const SHOCKWAVE_RADIUS := 90.0

var _fall_hitbox: Hitbox = null

func enter(_message: Dictionary = {}) -> void:
	player.use_attack()
	player.hurtbox.invulnerable = true
	Audio.play_sfx("whoosh")
	Feel.slash(player.global_position + Vector2(0, 40), PI / 2.0)
	_fall_hitbox = _spawn_hitbox(FALL_HITBOX_RADIUS, DIVE_DAMAGE, 1.0, Vector2(0, 36))
	_fall_hitbox.hit.connect(_on_dive_hit)

func exit() -> void:
	player.hurtbox.invulnerable = false
	if _fall_hitbox != null and is_instance_valid(_fall_hitbox):
		_fall_hitbox.queue_free()
		_fall_hitbox = null

func physics_process(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0.0, 2000.0 * delta)
	player.velocity.y = minf(player.velocity.y + player.get_gravity().y * delta, DIVE_FALL_SPEED)
	player.move_and_slide()
	if _fall_hitbox != null and is_instance_valid(_fall_hitbox):
		_fall_hitbox.global_position = player.global_position + Vector2(0, 36)
	if player.is_on_floor():
		_on_landed()

func _on_landed() -> void:
	Feel.dust(player.global_position + Vector2(0, 22))
	Feel.burst(player.global_position + Vector2(0, 28), Color(1.0, 0.75, 0.4))
	Feel.screen_shake(0.3)
	Audio.play_sfx("dive")
	_spawn_shockwave()
	state_machine.change_to(&"idle")

## Crea una hitbox con el script Hitbox para el buceo o la onda expansiva.
## Vive en la sala (get_parent), así sobrevive al cambio de estado.
func _spawn_hitbox(radius: float, damage: int, victim_iframes: float, offset: Vector2) -> Hitbox:
	var hitbox := Hitbox.new()
	hitbox.damage = damage
	hitbox.hit_once = false
	hitbox.cooldown = 0.0
	hitbox.invulnerability_duration = victim_iframes
	hitbox.knockback_strength = 220.0
	hitbox.knockback_vertical = -180.0
	hitbox.attacker_override = player
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	hitbox.add_child(shape)
	player.get_parent().add_child(hitbox)
	hitbox.global_position = player.global_position + offset
	hitbox.set_active(true)
	return hitbox
## Onda expansiva al aterrizar: breve y sin i-frames de víctima, para que
## conecte incluso con enemigos ya golpeados por la caída.
func _spawn_shockwave() -> void:
	var wave := _spawn_hitbox(SHOCKWAVE_RADIUS, SHOCKWAVE_DAMAGE, 0.0, Vector2(0, 30))
	wave.ignore_invulnerability = true
	wave.hit.connect(_on_dive_hit)
	player.get_tree().create_timer(0.05).timeout.connect(func() -> void:
		if is_instance_valid(wave):
			wave.queue_free())

## Golpe del buceo: alma + feedback (sin rebote de pogo: el buceo no rebota).
func _on_dive_hit(_hurtbox: Area2D) -> void:
	Progress.add_soul(Progress.SOUL_PER_HIT)
	Feel.hitstop(0.05)
	Feel.screen_shake(0.15)
	Audio.play_sfx("hit")
