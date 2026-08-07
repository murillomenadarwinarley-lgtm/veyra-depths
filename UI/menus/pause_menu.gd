extends Control
## Menú de pausa: continuar o volver al menú principal.

func _ready() -> void:
	$ResumeButton.pressed.connect(_on_resume_pressed)
	$MainMenuButton.pressed.connect(_on_main_menu_pressed)

func _on_resume_pressed() -> void:
	Game.toggle_pause()

func _on_main_menu_pressed() -> void:
	Game.go_to_main_menu()
