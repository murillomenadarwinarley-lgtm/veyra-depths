extends StateMachine
## Máquina de estados del juego (autoload "Game").
## Flujo: main_menu -> playing <-> pause -> game_over.
## process_mode = ALWAYS: sigue procesando input/UI aunque el árbol esté
## en pausa (necesario para que el menú de pausa responda).

var _current_ui: Node = null
var _ui_path: String = ""

const MAP_SCREEN_PATH := "res://UI/map/map_screen.tscn"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_state(&"main_menu", MainMenuState.new(self, self))
	add_state(&"playing", PlayingState.new(self, self))
	add_state(&"pause", PauseState.new(self, self))
	add_state(&"game_over", GameOverState.new(self, self))
	state_changed.connect(_on_state_changed)
	# La transición inicial se difiere un frame: entrar al menú durante
	# el _ready del autoload aún está en pleno setup del árbol.
	await get_tree().process_frame
	change_to(&"main_menu")

func start_playing() -> void:
	change_to(&"playing")

func toggle_pause() -> void:
	if current_name == &"pause":
		change_to(&"playing")
	else:
		change_to(&"pause")

func go_to_main_menu() -> void:
	change_to(&"main_menu")

func trigger_game_over() -> void:
	change_to(&"game_over")

func retry() -> void:
	# TODO: recargar el último guardado (Saves.load_game) antes de volver.
	change_to(&"playing")

func toggle_map() -> void:
	if _ui_path == MAP_SCREEN_PATH:
		hide_ui()
		get_tree().paused = false
	elif current_name == &"playing":
		# Solo se abre desde el estado playing; pausa el mundo para
		# consultar el mapa con tranquilidad (como en Hollow Knight).
		show_ui(MAP_SCREEN_PATH)
		get_tree().paused = true

func show_ui(scene_path: String) -> void:
	hide_ui()
	var scene = load(scene_path)
	if scene is PackedScene:
		_current_ui = scene.instantiate()
		add_child(_current_ui)
		_ui_path = scene_path

func hide_ui() -> void:
	if _current_ui != null:
		_current_ui.queue_free()
		_current_ui = null
	_ui_path = ""

func _on_state_changed(from: StringName, to: StringName) -> void:
	print("[Game] estado: %s -> %s" % [from, to])
