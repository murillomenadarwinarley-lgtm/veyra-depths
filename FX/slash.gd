extends Node2D
## Efecto de arco de ataque: rota, crece y se desvanece en ~0.15s.
## Se dispara con play() y se libera solo al terminar.

const DURATION := 0.16

func play() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.35, 1.35), DURATION).from(Vector2(0.8, 0.8))
	tween.parallel().tween_property(self, "modulate:a", 0.0, DURATION)
	tween.parallel().tween_property(self, "rotation", rotation + deg_to_rad(18.0), DURATION)
	tween.tween_callback(queue_free)
