class_name State
extends RefCounted
## Estado base de una máquina de estados (FSM).
## Compartido por la máquina de flujo del juego (Game) y por el jugador.
## Los estados son objetos ligeros (RefCounted), no Nodes: los gestiona
## un StateMachine que les reenvía process / physics_process / input.

var state_machine: StateMachine
var actor: Node

func _init(machine: StateMachine, owner_node: Node) -> void:
	state_machine = machine
	actor = owner_node

func enter(_message: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func process(_delta: float) -> void:
	pass

func physics_process(_delta: float) -> void:
	pass

func unhandled_input(_event: InputEvent) -> void:
	pass
