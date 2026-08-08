class_name AmbushTrigger
extends Area2D
## Encuentro de exploración (emboscada): al cruzar la zona, los enemigos
## anclados como hijos despiertan (visibles, con colisión e IA) y atacan
## por sorpresa. Al derrotarlos TODOS, se registran como derrotados en
## Progress y el encuentro no vuelve a dispararse (los derrotados se podan
## al recargar la sala, igual que el resto de enemigos).
##
## Diseño de dificultad: los enemigos se colocan para flanquear al jugador
## (por delante y por detrás del punto de cruce) y sus estadísticas de
## emboscada se suben por instancia en la sala (chase_speed, detección...).
##
## Mientras están inactivos los enemigos son invisibles, sin colisión y con
## la hurtbox apagada: no se pueden golpear ni bloquean el paso.

signal ambush_started
signal ambush_cleared

var _awakened := false
var _enemies: Array[Node] = []
var _alive: int = 0
var _killed: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_enemies = _collect_enemies()
	for enemy in _enemies:
		if Progress.is_enemy_defeated(_room_id(), enemy.name):
			enemy.queue_free()
		else:
			_alive += 1
			_disable_enemy(enemy)
			var health := enemy.get_node_or_null("Health") as HealthComponent
			if health != null:
				health.died.connect(_on_enemy_died)
	# Si no queda ninguno vivo (todos derrotados), el encuentro está cerrado.
	if _alive == 0:
		queue_free()

func _collect_enemies() -> Array[Node]:
	var found: Array[Node] = []
	for child in get_children():
		if child is Node2D and child.has_method("is_in_group") and child.is_in_group("enemies"):
			found.append(child)
	return found

func _disable_enemy(enemy: Node) -> void:
	enemy.visible = false
	if enemy is CollisionObject2D:
		enemy.collision_layer = 0
		enemy.collision_mask = 0
	var ai := enemy.get_node_or_null("AI") as Node
	if ai != null and ai.has_method("set"):
		ai.set("enabled", false)
	var hurtbox := enemy.get_node_or_null("Hurtbox") as Area2D
	if hurtbox != null:
		hurtbox.active = false
		hurtbox.monitoring = false
	var hitbox := enemy.get_node_or_null("Hitbox") as Hitbox
	if hitbox != null:
		hitbox.set_active(false)

func _on_body_entered(body: Node2D) -> void:
	if _awakened or not body.is_in_group("player"):
		return
	_awakened = true
	Audio.play_sfx("ambush")
	Feel.screen_shake(0.22)
	Feel.flash(self, Color(1.0, 0.25, 0.25), 0.25)
	for enemy in _enemies:
		if is_instance_valid(enemy):
			_wake_enemy(enemy)
	ambush_started.emit()

func _wake_enemy(enemy: Node) -> void:
	enemy.visible = true
	if enemy is CollisionObject2D:
		enemy.collision_layer = 1
		enemy.collision_mask = 1
	var ai := enemy.get_node_or_null("AI") as Node
	if ai != null and ai.has_method("set"):
		ai.set("enabled", true)
	var hurtbox := enemy.get_node_or_null("Hurtbox") as Area2D
	if hurtbox != null:
		hurtbox.active = true
		hurtbox.monitoring = true
	var hitbox := enemy.get_node_or_null("Hitbox") as Hitbox
	if hitbox != null:
		hitbox.set_active(hitbox.start_active)

func _on_enemy_died() -> void:
	_killed += 1
	if _killed < _alive:
		return
	# Todos derrotados: registrar y cerrar el encuentro para siempre.
	for e in _enemies:
		if is_instance_valid(e):
			Progress.register_enemy_defeated(_room_id(), e.name)
	ambush_cleared.emit()
	queue_free()

## Sube por el árbol hasta la sala (Room) a la que pertenece el encuentro.
func _room_id() -> String:
	var current: Node = get_parent()
	while current != null:
		if current is Room:
			return current.room_id
		current = current.get_parent()
	return ""
