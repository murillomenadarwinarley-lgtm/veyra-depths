class_name Player
extends CharacterBody2D
## Controlador del jugador.
## La lógica de comportamiento vive en el FSM de estados (Player/states/),
## no aquí. Este script solo registra los estados y expone datos básicos.

var movement_speed: float = 240.0
var jump_velocity: float = -520.0
var facing: Vector2 = Vector2.RIGHT

@onready var state_machine: StateMachine = $StateMachine

func _ready() -> void:
	add_to_group("player")
	_register_states()

func _register_states() -> void:
	state_machine.add_state(&"idle", PlayerIdleState.new(state_machine, self))
	state_machine.add_state(&"run", PlayerRunState.new(state_machine, self))
	state_machine.add_state(&"jump", PlayerJumpState.new(state_machine, self))
	state_machine.add_state(&"dash", PlayerDashState.new(state_machine, self))
	state_machine.add_state(&"attack", PlayerAttackState.new(state_machine, self))
	state_machine.add_state(&"hurt", PlayerHurtState.new(state_machine, self))
	state_machine.change_to(&"idle")

func take_damage(amount: int) -> void:
	state_machine.change_to(&"hurt", {"damage": amount})
