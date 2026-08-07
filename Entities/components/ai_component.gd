class_name AIComponent
extends Node
## Componente de IA reutilizable (máquina de estados interna).
## Estados genéricos; la lógica de cada uno se implementa en el script
## del enemigo suscribiéndose a state_changed o por overriding.

enum AIState { IDLE, PATROL, CHASE, ATTACK }

signal state_changed(old_state: AIState, new_state: AIState)

@export var starting_state: AIState = AIState.IDLE

var current_state: AIState = AIState.IDLE

func _ready() -> void:
	current_state = starting_state

func set_state(new_state: AIState) -> void:
	if current_state == new_state:
		return
	var old := current_state
	current_state = new_state
	state_changed.emit(old, new_state)
