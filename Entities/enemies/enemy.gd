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
	else:
		push_warning("Enemy '%s' sin HealthComponent" % name)

func _on_died() -> void:
	# TODO: drops, partículas, sonido
	queue_free()
