class_name PlayerIdleState
extends PlayerState

func enter(_message: Dictionary = {}) -> void:
	player.velocity.x = 0.0
	# TODO: animación de idle

func physics_process(_delta: float) -> void:
	# move_and_slide mantiene fresco is_on_floor() (cae a jump si no hay suelo).
	player.move_and_slide()
	if not player.is_on_floor():
		state_machine.change_to(&"jump")
		return
	if player.consume_jump_buffer():
		player.do_jump()
		state_machine.change_to(&"jump")
		return
	if player.get_move_axis() != 0.0:
		state_machine.change_to(&"run")
	elif Input.is_action_just_pressed("jump") and player.can_coyote_jump():
		player.do_jump()
		state_machine.change_to(&"jump")
	elif Input.is_action_just_pressed("dash") and player.can_dash() and Progress.has_ability("dash"):
		state_machine.change_to(&"dash")
	elif Input.is_action_just_pressed("attack") and player.can_attack():
		state_machine.change_to(&"attack")
	elif Input.is_action_just_pressed("spell") and Progress.get_soul() >= Progress.SPELL_COST:
		state_machine.change_to(&"spell")
	elif Input.is_action_pressed("focus") and Progress.get_soul() >= Progress.FOCUS_COST:
		state_machine.change_to(&"focus")
