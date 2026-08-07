class_name VirtualJoystick
extends Control
## Joystick virtual: simula las acciones move_left/move_right del Input
## Map (con Input.action_press/action_release), de modo que los estados
## del jugador no distinguen entre teclado, mando y táctil.

@export var radius: float = 60.0
@export var deadzone: float = 0.25

var _active := false
var _touch_index := -1
var _knob: Control

func _ready() -> void:
	_knob = get_node("Knob")
	_center_knob()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not _active:
			_active = true
			_touch_index = event.index
			_update(event.position)
		elif not event.pressed and event.index == _touch_index:
			_reset()
	elif event is InputEventScreenDrag and _active and event.index == _touch_index:
		_update(event.position)

func _update(pos: Vector2) -> void:
	var center := size * 0.5
	var offset := pos - center
	offset = offset.limit_length(radius)
	_knob.position = center + offset - _knob.size * 0.5
	var axis := offset.x / radius
	if absf(axis) < deadzone:
		axis = 0.0
	if axis > 0.0:
		Input.action_press("move_right", 1.0)
		Input.action_release("move_left")
	elif axis < 0.0:
		Input.action_press("move_left", 1.0)
		Input.action_release("move_right")
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")

func _reset() -> void:
	_active = false
	_touch_index = -1
	_center_knob()
	Input.action_release("move_left")
	Input.action_release("move_right")

func _center_knob() -> void:
	if _knob == null:
		return
	_knob.position = size * 0.5 - _knob.size * 0.5
