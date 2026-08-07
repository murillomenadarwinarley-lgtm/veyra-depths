class_name PlayerIdleState
extends PlayerState

func enter(_message: Dictionary = {}) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0.0, 240.0)
	# TODO: animación de idle

func physics_process(_delta: float) -> void:
	if Input.get_axis("move_left", "move_right") != 0.0:
		state_machine.change_to(&"run")
	if Input.is_action_just_pressed("jump"):
		state_machine.change_to(&"jump")
	if Input.is_action_just_pressed("dash") and Progress.has_ability("dash"):
		state_machine.change_to(&"dash")
	if Input.is_action_just_pressed("attack"):
		state_machine.change_to(&"attack")
