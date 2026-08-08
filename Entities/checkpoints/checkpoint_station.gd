class_name CheckpointStation
extends Area2D
## Estación de guardado (estilo banco de Hollow Knight): al tocarla, cura
## al jugador, fija el checkpoint de reaparición en su Spawn y guarda la
## partida. El cristal se enciende y se reactiva al salir de su zona.

const HINT_TEXT := "Punto de guardado"
const SAVED_TEXT := "¡Partida guardada!"
const DIM_COLOR := Color(0.35, 0.5, 0.6, 1.0)
const LIT_COLOR := Color(0.2, 1.0, 1.0, 1.0)

@onready var crystal: Polygon2D = $Crystal

var hint_text: String = HINT_TEXT
var _hint_alpha := 1.0
var _lit := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _draw() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(-70.0, -52.0), hint_text,
		HORIZONTAL_ALIGNMENT_CENTER, 140.0, 16, Color(1, 1, 1, _hint_alpha))

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_activate()

## La estación se rearma al salir: volver a pisarla vuelve a guardar.
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_lit = false

func _activate() -> void:
	if _lit:
		return
	_lit = true
	var room := get_parent() as Room
	var room_id := room.room_id if room != null else RoomStreamer.current_room_id
	# El Spawn es hijo de la estación, que a su vez cuelga de la sala:
	# "CheckpointStation/Spawn" es un path válido para position_player_at_spawn.
	var marker_path := "%s/Spawn" % name
	if room == null or not (room.get_node_or_null(marker_path) is Marker2D):
		marker_path = "PlayerSpawn"
	Progress.set_checkpoint(room_id, marker_path)
	var player := RoomStreamer.player
	if player != null:
		player.health.heal(player.health.max_health)
	Saves.save_game()
	crystal.color = LIT_COLOR
	hint_text = SAVED_TEXT
	queue_redraw()
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_method(_set_hint_alpha, 1.0, 0.0, 0.4)
	tween.tween_callback(func() -> void:
		hint_text = HINT_TEXT
		_hint_alpha = 1.0
		queue_redraw())

func _set_hint_alpha(alpha: float) -> void:
	_hint_alpha = alpha
	queue_redraw()
