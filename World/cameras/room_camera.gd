class_name RoomCamera
extends Camera2D
## Cámara del jugador limitada a los límites de la sala actual.
## RoomStreamer.configure_camera() la configura con los bounds del grafo
## (data/map/world_map.json). Vive como hijo del jugador y lo sigue.

@export var view_offset: Vector2 = Vector2(0, -48)

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
	offset = view_offset
