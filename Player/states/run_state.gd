class_name PlayerRunState
extends PlayerState

func physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	player.velocity.x = move_toward(player.velocity.x, direction * player.movement_speed, 1200.0 * delta)
	player.move_and_slide()
	if direction != 0.0:
		player.facing = Vector2(direction, 0.0)
	if direction == 0.0:
		state_machine.change_to(&"idle")
	if Input.is_action_just_pressed("jump"):
		state_machine.change_to(&"jump")
	if Input.is_action_just_pressed("dash") and Progress.has_ability("dash"):
		state_machine.change_to(&"dash")
	if Input.is_action_just_pressed("attack"):
		state_machine.change_to(&"attack")
