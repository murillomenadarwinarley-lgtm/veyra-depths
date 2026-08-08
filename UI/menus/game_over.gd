extends Control
## Pantalla de game over: reintentar o volver al menú principal.
## Indica dónde reaparecerá el jugador (último checkpoint tocado).

func _ready() -> void:
	$RetryButton.pressed.connect(_on_retry_pressed)
	$MainMenuButton.pressed.connect(_on_main_menu_pressed)
	var checkpoint_room := Progress.get_checkpoint_room()
	var room := WorldMap.get_room(checkpoint_room)
	if not room.is_empty():
		$RespawnLabel.text = "Reaparecerás en: %s" % room.get("display_name", checkpoint_room)
	else:
		$RespawnLabel.text = "Reaparecerás en la sala actual"

func _on_retry_pressed() -> void:
	Game.retry()

func _on_main_menu_pressed() -> void:
	Game.go_to_main_menu()
