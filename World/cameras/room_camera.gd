class_name RoomCamera
extends Camera2D
## Cámara del jugador limitada a los límites de la sala actual.
## RoomStreamer.configure_camera() la configura con los bounds del grafo
## (data/map/world_map.json). Vive como hijo del jugador y lo sigue.

@export var view_offset: Vector2 = Vector2(0, -48)
## Amplitud máxima del shake (píxeles) cuando el trauma llega a 1.0.
@export var shake_max_offset: float = 14.0

var _trauma: float = 0.0
var _base_offset: Vector2 = Vector2.ZERO

func setup(room_bounds: Dictionary) -> void:
	var left: float = room_bounds.get("left", 0.0)
	var top: float = room_bounds.get("top", 0.0)
	var right: float = room_bounds.get("right", left + 1024.0)
	var bottom: float = room_bounds.get("bottom", top + 600.0)
	# Los límites de Camera2D son coordenadas absolutas del mundo.
	limit_left = int(left)
	limit_top = int(top)
	limit_right = int(right)
	limit_bottom = int(bottom)
	_base_offset = view_offset
	offset = view_offset

## Añade sacudida (0.0-1.0, acumulable). Decae sola con el tiempo.
func add_shake(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
	if _trauma <= 0.0:
		return
	_trauma = maxf(_trauma - delta * 2.5, 0.0)
	var power := _trauma * _trauma
	offset = _base_offset + Vector2(
		randf_range(-1.0, 1.0) * shake_max_offset * power,
		randf_range(-1.0, 1.0) * shake_max_offset * power
	)
