extends Control
## Pantalla de mapa del mundo (placeholder).
## TODO: renderizar el grafo de WorldMap (salas visitadas, gates cerrados).

func _ready() -> void:
	$CloseButton.pressed.connect(queue_free)
