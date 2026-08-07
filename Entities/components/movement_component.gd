class_name MovementComponent
extends Node
## Componente de movimiento reutilizable.
## Opera sobre el nodo padre (la entidad) usando CharacterBody2D o
## Node2D según lo que exponga la entidad.

@export var max_speed: float = 120.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0

var facing: Vector2 = Vector2.RIGHT

func setup(actor: Node2D) -> void:
	# TODO: guardar referencia al actor si no es el padre.
	pass
