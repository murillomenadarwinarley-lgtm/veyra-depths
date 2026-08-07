class_name GameOverState
extends State
## Game over: congela el árbol y muestra la pantalla de muerte.

const GAME_OVER_SCENE := "res://UI/menus/game_over.tscn"

func enter(_message: Dictionary = {}) -> void:
	Game.show_ui(GAME_OVER_SCENE)
	state_machine.get_tree().paused = true

func exit() -> void:
	state_machine.get_tree().paused = false
	Game.hide_ui()
