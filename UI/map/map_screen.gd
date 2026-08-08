extends Control
## Pantalla de mapa del mundo: renderiza el grafo de WorldMap.
## - Salas visitadas: rectángulo relleno con borde (la actual resaltada).
## - Conexiones entre salas visitadas: línea entre sus puertas.
## - Puertas con requisito pendiente: candado rojo en la puerta.
## - El jugador: punto cian que sigue su posición real.
## La apertura pausa el juego (Game.toggle_map); el marcador se actualiza
## porque el nodo vive bajo el autoload Game (PROCESS_MODE_ALWAYS).

const MARGIN := 80.0
const COLOR_BG := Color(0.07, 0.08, 0.1, 1.0)
const COLOR_ROOM_FILL := Color(0.16, 0.18, 0.23, 1.0)
const COLOR_ROOM_BORDER := Color(0.45, 0.5, 0.6, 1.0)
const COLOR_CURRENT := Color(0.3, 0.85, 1.0, 1.0)
const COLOR_PATH := Color(0.4, 0.44, 0.5, 1.0)
const COLOR_LOCK := Color(1.0, 0.3, 0.35, 1.0)
const COLOR_PLAYER := Color(0.0, 1.0, 1.0, 1.0)

var _world_bounds: Rect2 = Rect2()
var _scale := 1.0
var _screen_origin := Vector2.ZERO

func _ready() -> void:
	$CloseButton.pressed.connect(Game.toggle_map)
	_compute_layout()

func _process(_delta: float) -> void:
	queue_redraw()

## Ajusta escala y origen para que todas las salas quepan con margen.
func _compute_layout() -> void:
	var min_left := INF
	var min_top := INF
	var max_right := -INF
	var max_bottom := -INF
	for room in WorldMap.get_all_rooms():
		var b: Dictionary = room.get("bounds", {})
		min_left = minf(min_left, b.get("left", 0.0))
		min_top = minf(min_top, b.get("top", 0.0))
		max_right = maxf(max_right, b.get("right", 1920.0))
		max_bottom = maxf(max_bottom, b.get("bottom", 1080.0))
	if min_left == INF:
		return
	_world_bounds = Rect2(min_left, min_top, max_right - min_left, max_bottom - min_top)
	var target := Rect2(MARGIN, MARGIN, size.x - MARGIN * 2.0, size.y - MARGIN * 2.0)
	_scale = minf(target.size.x / _world_bounds.size.x, target.size.y / _world_bounds.size.y)
	_screen_origin = target.position + (target.size - _world_bounds.size * _scale) / 2.0

## Coordenadas de mundo (bounds del JSON) a pantalla.
func world_to_screen(world_pos: Vector2) -> Vector2:
	return _screen_origin + (world_pos - _world_bounds.position) * _scale

## Rectángulo en pantalla de una sala (bounds del JSON).
func room_screen_rect(room: Dictionary) -> Rect2:
	var b: Dictionary = room.get("bounds", {})
	var tl := world_to_screen(Vector2(b.get("left", 0.0), b.get("top", 0.0)))
	var br := world_to_screen(Vector2(b.get("right", 1920.0), b.get("bottom", 1080.0)))
	return Rect2(tl, br - tl)

## Punto en mundo de una puerta según su dirección (north/south/east/west).
func gate_point(room: Dictionary, gate_id: String) -> Vector2:
	var b: Dictionary = room.get("bounds", {})
	var left: float = b.get("left", 0.0)
	var top: float = b.get("top", 0.0)
	var right: float = b.get("right", 1920.0)
	var bottom: float = b.get("bottom", 1080.0)
	var cx := (left + right) / 2.0
	var cy := (top + bottom) / 2.0
	if "north" in gate_id:
		return Vector2(cx, top)
	if "south" in gate_id:
		return Vector2(cx, bottom)
	if "east" in gate_id:
		return Vector2(right, cy)
	if "west" in gate_id:
		return Vector2(left, cy)
	return Vector2(cx, cy)

## La puerta de `room` que conecta con `from_room_id` (la de vuelta).
func matching_gate(room: Dictionary, from_room_id: String) -> String:
	for gate in room.get("gates", []):
		if gate.get("to_room", "") == from_room_id:
			return gate.get("id", "")
	return ""

## Datos de render de salas: solo las visitadas, con flags de estado.
func collect_rooms() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for room in WorldMap.get_all_rooms():
		var room_id: String = room.get("id", "")
		if not Progress.rooms_visited.has(room_id):
			continue
		out.append({
			"id": room_id,
			"rect": room_screen_rect(room),
			"current": room_id == RoomStreamer.current_room_id,
		})
	return out

## Conexiones visibles entre salas visitadas (puntos de puerta en pantalla).
func collect_connections() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for room in WorldMap.get_all_rooms():
		var room_id: String = room.get("id", "")
		if not Progress.rooms_visited.has(room_id):
			continue
		for gate in room.get("gates", []):
			var to_id: String = gate.get("to_room", "")
			if not Progress.rooms_visited.has(to_id):
				continue
			var to_room := WorldMap.get_room(to_id)
			var to_gate_id := matching_gate(to_room, room_id)
			out.append({
				"from": world_to_screen(gate_point(room, gate.get("id", ""))),
				"to": world_to_screen(gate_point(to_room, to_gate_id)),
			})
	return out

## Puertas de salas visitadas con requisito aún pendiente.
func collect_locks() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for room in WorldMap.get_all_rooms():
		var room_id: String = room.get("id", "")
		if not Progress.rooms_visited.has(room_id):
			continue
		for gate in room.get("gates", []):
			if WorldMap.can_traverse(gate):
				continue
			out.append({
				"from_room": room_id,
				"to_room": gate.get("to_room", ""),
				"point": world_to_screen(gate_point(room, gate.get("id", ""))),
			})
	return out

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BG)
	for conn in collect_connections():
		draw_line(conn["from"], conn["to"], COLOR_PATH, 4.0)
	for room in collect_rooms():
		draw_rect(room["rect"], COLOR_ROOM_FILL)
		draw_rect(room["rect"], COLOR_CURRENT if room["current"] else COLOR_ROOM_BORDER,
			false, 3.0 if room["current"] else 1.5)
	for lock in collect_locks():
		var pt: Vector2 = lock["point"]
		draw_arc(pt + Vector2(0.0, -6.0), 5.0, PI, TAU, 16, COLOR_LOCK, 2.5)
		draw_rect(Rect2(pt + Vector2(-6.0, -3.0), Vector2(12.0, 9.0)), COLOR_LOCK)
	var player := RoomStreamer.player
	if player != null:
		var p := world_to_screen(player.global_position)
		draw_circle(p, 6.0, COLOR_PLAYER)
		draw_arc(p, 9.0, 0.0, TAU, 16, COLOR_PLAYER, 1.5)
