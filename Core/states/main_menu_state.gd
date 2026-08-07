class_name MainMenuState
extends State
## Menú principal: muestra la escena de menú y espera "Jugar".

const MAIN_MENU_SCENE := "res://UI/menus/main_menu.tscn"

func enter(_message: Dictionary = {}) -> void:
	state_machine.get_tree().paused = false
	Game.hide_ui()
	Game.show_ui(MAIN_MENU_SCENE)
