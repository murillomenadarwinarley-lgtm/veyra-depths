extends Control
## Menú principal: "Jugar" arranca la partida, "Salir" cierra el juego.

func _ready() -> void:
	$StartButton.pressed.connect(_on_start_pressed)
	$QuitButton.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	Game.start_playing()

func _on_quit_pressed() -> void:
	get_tree().quit()
