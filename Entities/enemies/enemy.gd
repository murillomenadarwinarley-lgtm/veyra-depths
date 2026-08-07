class_name Enemy
extends Entity
## Base de enemigos. No hereda lógica: monta componentes y los cablea.
## Cada enemigo concreto es una escena con sus componentes y valores.
## La sincronización hitbox <- AttackComponent la hace el propio
## AttackComponent (búsqueda por tipo, no por nombre de nodo).

func _ready() -> void:
	add_to_group("enemies")
	var health := get_component(HealthComponent) as HealthComponent
	if health:
		health.died.connect(_on_died)
		health.damaged.connect(_on_damaged)
	else:
		push_warning("Enemy '%s' sin HealthComponent" % name)
	var hitbox := get_node_or_null("Hitbox") as Hitbox
	if hitbox:
		hitbox.hit.connect(_on_hit)

## El enemigo conecta un golpe propio (contacto/embestida): feedback ligero.
func _on_hit(_hurtbox: Area2D) -> void:
	Feel.sparks(global_position + Vector2(0.0, -18.0))
	Audio.play_sfx("hit")

## El enemigo recibe daño. Si el atacante es el jugador, hay hitstop y
## más shake; si no, solo el parpadeo y las chispas.
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
	var color := Color(1.0, 0.3, 0.3)
	var visual := get_node_or_null("Visual") as Polygon2D
	if visual != null:
		color = visual.color
	Feel.burst(global_position, color)
	Feel.screen_shake(0.22)
	Audio.play_sfx("death")
	var room := _find_room()
	if room is Room:
		Progress.register_enemy_defeated(room.room_id, name)
	queue_free()

## Sube por el árbol hasta la sala (Room) a la que pertenece el enemigo.
func _find_room() -> Node:
	var current: Node = get_parent()
	while current != null:
		if current is Room:
			return current
		current = current.get_parent()
	return null
