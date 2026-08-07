class_name PlayerJumpState
extends PlayerState

func enter(_message: Dictionary = {}) -> void:
	if player.is_on_floor():
		player.velocity.y = player.jump_velocity
	# TODO: animación de salto

func physics_process(delta: float) -> void:
	player.velocity.y += player.get_gravity().y * delta
	var direction := Input.get_axis("move_left", "move_right")
	player.velocity.x = move_toward(player.velocity.x, direction * player.movement_speed, 900.0 * delta)
	player.move_and_slide()
	if direction != 0.0:
		player.facing = Vector2(direction, 0.0)
	if player.is_on_floor():
		state_machine.change_to(&"idle")
	if Input.is_action_just_pressed("dash") and Progress.has_ability("dash"):
		state_machine.change_to(&"dash")
	if Input.is_action_just_pressed("attack"):
		state_machine.change_to(&"attack")
