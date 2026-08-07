extends Control
## Pantalla de game over: reintentar o volver al menú principal.

func _ready() -> void:
	$RetryButton.pressed.connect(_on_retry_pressed)
	$MainMenuButton.pressed.connect(_on_main_menu_pressed)

func _on_retry_pressed() -> void:
	Game.retry()

func _on_main_menu_pressed() -> void:
	Game.go_to_main_menu()
