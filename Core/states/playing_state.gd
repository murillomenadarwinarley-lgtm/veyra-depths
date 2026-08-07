class_name PlayingState
extends State
## Juego en curso: HUD visible y el mundo activo.
## Bootstrap del mundo la primera vez (RoomStreamer.bootstrap()).
## En dispositivos táctiles se añaden los controles touch (UI/touch/).

const HUD_SCENE := "res://UI/hud/hud.tscn"
const TOUCH_CONTROLS_SCENE := preload("res://UI/touch/touch_controls.tscn")

var _touch_controls: Node = null

func enter(_message: Dictionary = {}) -> void:
	state_machine.get_tree().paused = false
	Game.hide_ui()
	Game.show_ui(HUD_SCENE)
	if Platform.is_touch_device():
		_touch_controls = TOUCH_CONTROLS_SCENE.instantiate()
		Game.add_child(_touch_controls)
	if RoomStreamer.player == null:
		RoomStreamer.bootstrap()
	elif RoomStreamer.current_room_id.is_empty():
		RoomStreamer.enter_room(WorldMap.start_room_id)

func exit() -> void:
	if _touch_controls != null:
		_touch_controls.queue_free()
		_touch_controls = null

func unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		Game.toggle_pause()
	elif event.is_action_pressed("map"):
		Game.toggle_map()
