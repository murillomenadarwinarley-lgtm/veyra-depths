class_name CrystalBlock
extends StaticBody2D
## Bloque de cristal: obstáculo de travesía que se rompe con un golpe del
## arma SOLO si el jugador tiene la habilidad "crystal_heart". Sin ella,
## el golpe no hace nada (el cristal es inmune).
##
## La detección del golpe usa el protocolo de combate: el hijo Receiver
## (Area2D) se une al grupo "hurtbox", así que el AttackHitbox del jugador
## dispara receive_hit() al contactar. El bloque comprueba que el atacante
## sea el jugador y que tenga la habilidad antes de romperse.

const COLOR_CRYSTAL := Color(0.45, 0.85, 1.0, 1.0)
const COLOR_SHATTER := Color(0.65, 0.9, 1.0, 1.0)

@onready var receiver: Area2D = $Receiver

func _ready() -> void:
	receiver.add_to_group("hurtbox")
	# Un sello ya roto no reaparece al recargar la sala (poda permanente,
	# igual que enemigos derrotados: el candado metroidvania queda abierto).
	if Progress.is_enemy_defeated(_room_id(), name):
		queue_free()

## Protocolo de hurtbox: lo invoca el AttackHitbox del jugador al golpear.
func receive_hit(hitbox: Hitbox) -> void:
	var attacker := hitbox.get_attacker()
	if attacker == null or not attacker.is_in_group("player"):
		return
	if not Progress.has_ability("crystal_heart"):
		Feel.flash(self, Color(1.0, 1.0, 1.0), 0.08)
		Audio.play_sfx("hit")
		return
	_shatter()

func _shatter() -> void:
	Progress.register_enemy_defeated(_room_id(), name)
	Feel.hitstop(0.06)
	Feel.screen_shake(0.22)
	Feel.burst(global_position, COLOR_SHATTER)
	Feel.dust(global_position)
	Audio.play_sfx("crystal")
	queue_free()

## Sube por el árbol hasta la sala (Room) a la que pertenece el bloque.
func _room_id() -> String:
	var current: Node = get_parent()
	while current != null:
		if current is Room:
			return current.room_id
		current = current.get_parent()
	return ""
