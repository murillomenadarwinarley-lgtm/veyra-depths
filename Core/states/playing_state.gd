class_name PlayingState
extends State
## Juego en curso: HUD visible y el mundo activo.
## Bootstrap del mundo la primera vez (RoomStreamer.bootstrap()).

const HUD_SCENE := "res://UI/hud/hud.tscn"

func enter(_message: Dictionary = {}) -> void:
	state_machine.get_tree().paused = false
	Game.hide_ui()
	Game.show_ui(HUD_SCENE)
	if RoomStreamer.player == null:
		RoomStreamer.bootstrap()
	elif RoomStreamer.current_room_id.is_empty():
		RoomStreamer.enter_room(WorldMap.start_room_id)

func unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		Game.toggle_pause()
	elif event.is_action_pressed("map"):
		Game.toggle_map()
