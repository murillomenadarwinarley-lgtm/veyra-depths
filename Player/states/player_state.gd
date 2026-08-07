class_name PlayerState
extends State
## Base de todos los estados del jugador. Ofrece acceso tipado al actor.

var player: Player

func _init(machine: StateMachine, owner_node: Node) -> void:
	super(machine, owner_node)
	player = owner_node as Player
