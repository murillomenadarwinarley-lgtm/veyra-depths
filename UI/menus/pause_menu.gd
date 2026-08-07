extends Control
## Menú de pausa: guardar partida, continuar o volver al menú principal.

func _ready() -> void:
	$SaveButton.pressed.connect(_on_save_pressed)
	$ResumeButton.pressed.connect(_on_resume_pressed)
	$MainMenuButton.pressed.connect(_on_main_menu_pressed)

func _on_save_pressed() -> void:
	if Saves.save_game() == OK:
		$StatusLabel.text = "Partida guardada"
	else:
		$StatusLabel.text = "Error al guardar"

func _on_resume_pressed() -> void:
	Game.toggle_pause()

func _on_main_menu_pressed() -> void:
	Game.go_to_main_menu()
