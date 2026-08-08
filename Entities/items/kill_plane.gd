extends Area2D
## Plano de muerte bajo los pozos de las salas: al caer sobre él, el
## jugador muere (game over) y reaparece en su último checkpoint.
## Las salas añaden su CollisionShape2D con el ancho del pozo.

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(body.health.health)
