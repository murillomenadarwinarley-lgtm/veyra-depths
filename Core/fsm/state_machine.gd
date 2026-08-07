class_name StateMachine
extends Node
## Máquina de estados genérica y reutilizable.
## Registra estados por id (StringName) y permite transiciones con
## change_to(id, message). El primer estado registrado se entra solo.
## La usa el autoload Game (flujo de juego) y el Player (FSM de estados).

signal state_changed(from: StringName, to: StringName)

var _states: Dictionary = {}
var _current: State = null
var current_name: StringName = &""

func add_state(id: StringName, state: State) -> void:
	_states[id] = state

func change_to(id: StringName, message: Dictionary = {}) -> bool:
	if not _states.has(id):
		push_warning("StateMachine.change_to: estado desconocido '%s'" % id)
		return false
	if _current != null:
		_current.exit()
	state_changed.emit(current_name, id)
	_current = _states[id]
	current_name = id
	_current.enter(message)
	return true

func get_state(id: StringName) -> State:
	return _states.get(id)

func has_state(id: StringName) -> bool:
	return _states.has(id)

func _process(delta: float) -> void:
	if _current != null:
		_current.process(delta)

func _physics_process(delta: float) -> void:
	if _current != null:
		_current.physics_process(delta)

func _unhandled_input(event: InputEvent) -> void:
	if _current != null:
		_current.unhandled_input(event)
