class_name Enemy
extends Entity
## Base de enemigos. No hereda lógica: monta componentes y los cablea.
## Cada enemigo concreto es una escena con sus componentes y valores.

func _ready() -> void:
	add_to_group("enemies")
	var health := get_component(HealthComponent) as HealthComponent
	if health:
		health.died.connect(_on_died)
	else:
		push_warning("Enemy '%s' sin HealthComponent" % name)
	# La hitbox de contacto hereda los parámetros del AttackComponent,
	# que es la fuente de verdad del ataque del enemigo.
	var attack := get_component(AttackComponent) as AttackComponent
	var hitbox := get_node_or_null("Hitbox") as Hitbox
	if attack and hitbox:
		hitbox.damage = attack.damage
		hitbox.cooldown = attack.cooldown
		hitbox.invulnerability_duration = attack.invulnerability_duration
	elif hitbox == null:
		push_warning("Enemy '%s' sin Hitbox de contacto" % name)

func _on_died() -> void:
	# TODO: drops, partículas, sonido
	queue_free()
