class_name PauseState
extends State
## Pausa: congela el árbol y muestra el menú de pausa.

const PAUSE_MENU_SCENE := "res://UI/menus/pause_menu.tscn"

func enter(_message: Dictionary = {}) -> void:
	Game.show_ui(PAUSE_MENU_SCENE)
	state_machine.get_tree().paused = true

func exit() -> void:
	state_machine.get_tree().paused = false
	Game.hide_ui()

func unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		Game.toggle_pause()
