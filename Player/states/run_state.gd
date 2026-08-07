class_name PlayerRunState
extends PlayerState

func physics_process(delta: float) -> void:
	var axis := player.get_move_axis()
	if player.consume_jump_buffer() or (Input.is_action_just_pressed("jump") and player.can_coyote_jump()):
		player.do_jump()
		state_machine.change_to(&"jump")
		return
	if axis != 0.0:
		player.facing = Vector2(axis, 0.0)
	player.velocity.x = move_toward(player.velocity.x, axis * player.movement_speed, 1200.0 * delta)
	if not player.is_on_floor():
		player.apply_gravity(delta)
	player.move_and_slide()
	if not player.is_on_floor():
		state_machine.change_to(&"jump")
	elif axis == 0.0:
		state_machine.change_to(&"idle")
	elif Input.is_action_just_pressed("dash") and player.can_dash() and Progress.has_ability("dash"):
		state_machine.change_to(&"dash")
	elif Input.is_action_just_pressed("attack"):
		state_machine.change_to(&"attack")
