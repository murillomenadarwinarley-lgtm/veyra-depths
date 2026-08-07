class_name PlayerSpellState
extends PlayerState
## Hechizo de alma estilo Hollow Knight: dispara un proyectil hacia
## adelante gastando SPELL_COST de alma. Funciona en suelo y en el aire.
## El proyectil reporta al jugador como atacante (attacker_override),
## así el knockback sale desde el jugador y no puede herirlo a él.

const CAST_DURATION := 0.18
const SPAWN_DISTANCE := 36.0
const SPELL_SCENE := preload("res://Entities/projectiles/player_spell.tscn")

var _time_left: float = 0.0

func enter(_message: Dictionary = {}) -> void:
	_time_left = CAST_DURATION
	player.velocity.x = 0.0
	Audio.play_sfx("whoosh")
	Feel.flash(player, Color(0.35, 0.7, 1.0), 0.15)
	_fire()

func exit() -> void:
	pass

func physics_process(delta: float) -> void:
	_time_left -= delta
	if not player.is_on_floor():
		player.apply_gravity(delta)
	player.move_and_slide()
	if _time_left <= 0.0:
		state_machine.change_to(&"idle" if player.is_on_floor() else &"jump")

func _fire() -> void:
	if not Progress.spend_soul(Progress.SPELL_COST):
		# Defensa extra: sin alma no se gasta ni se dispara (los estados de
		# entrada ya filtran con get_soul() >= SPELL_COST).
		state_machine.change_to(&"idle" if player.is_on_floor() else &"jump")
		return
	# Posicionar ANTES de add_child: _ready captura _spawn_pos y un
	# teleport posterior falsearía max_distance (muerte instantánea).
	var spell: Node = SPELL_SCENE.instantiate()
	spell.global_position = player.global_position + player.facing * SPAWN_DISTANCE
	player.get_parent().add_child(spell)
	spell.hitbox.attacker_override = player
	spell.setup(player.facing, 420.0)
	Feel.hitstop(0.04)
	Feel.screen_shake(0.12)
