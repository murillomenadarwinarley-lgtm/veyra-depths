class_name PlayerJumpState
extends PlayerState

func physics_process(delta: float) -> void:
	var axis := player.get_move_axis()
	# Salto de pared: pegado a una pared y presionando hacia ella. Tiene
	# prioridad sobre el salto normal; el doble salto sigue disponible.
	if Input.is_action_just_pressed("jump") and player.is_on_wall() and not player.is_on_floor():
		var wall_normal := player.get_wall_normal()
		if axis * wall_normal.x < 0.0 and Progress.has_ability("wall_jump"):
			player.do_wall_jump(signf(wall_normal.x))
			return
	if Input.is_action_just_pressed("jump") and not player.is_on_floor() and player.can_coyote_jump():
		player.do_jump()
		return
	if Input.is_action_just_pressed("jump") and player.can_double_jump():
		player.do_air_jump()
		return
	player.apply_gravity(delta)
	if axis != 0.0:
		player.facing = Vector2(axis, 0.0)
	# Deslizamiento de pared: presionando contra la pared, la caída se
	# frena hasta wall_slide_speed (control para encadenar saltos). Es
	# parte del kit de wall_jump: sin la habilidad, la pared no frena nada.
	if player.is_on_wall() and not player.is_on_floor() \
			and axis * player.get_wall_normal().x < 0.0 and Progress.has_ability("wall_jump"):
		player.velocity.y = minf(player.velocity.y, player.wall_slide_speed)
	player.velocity.x = move_toward(player.velocity.x, axis * player.movement_speed, 900.0 * delta)
	player.move_and_slide()
	if player.is_on_floor():
		player.velocity.y = 0.0
		if player.consume_jump_buffer():
			player.do_jump()
		else:
			state_machine.change_to(&"idle")
		return
	if Input.is_action_just_pressed("dash") and player.can_dash() and Progress.has_ability("dash"):
		state_machine.change_to(&"dash")
	elif Input.is_action_just_pressed("attack") and player.can_attack():
		state_machine.change_to(&"attack")
	elif Input.is_action_just_pressed("spell") and Progress.get_soul() >= Progress.SPELL_COST:
		state_machine.change_to(&"spell")
