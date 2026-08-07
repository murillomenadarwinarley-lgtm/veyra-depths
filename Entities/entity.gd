class_name Entity
extends Node2D
## Base de toda entidad (enemigos, NPCs).
## Composición: la lógica vive en componentes hijos (Health, Movement, AI,
## Attack), nunca en herencia profunda.

@export var display_name: String = ""

func get_component(component_type: GDScript) -> Node:
	for child in get_children():
		if is_instance_of(child, component_type):
			return child
	return null
