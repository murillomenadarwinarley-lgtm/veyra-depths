extends Control
## Menú principal: "Continuar" carga la última partida si existe,
## "Jugar" arranca una partida nueva, "Salir" cierra el juego.

func _ready() -> void:
	$ContinueButton.pressed.connect(_on_continue_pressed)
	$StartButton.pressed.connect(_on_start_pressed)
	$QuitButton.pressed.connect(_on_quit_pressed)
	$ContinueButton.visible = Saves.has_save()

func _on_continue_pressed() -> void:
	if Saves.load_game() == OK:
		Game.start_playing()

func _on_start_pressed() -> void:
	Game.start_playing()

func _on_quit_pressed() -> void:
	get_tree().quit()
