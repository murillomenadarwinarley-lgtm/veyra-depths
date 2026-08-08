extends Area2D
## Receptor de golpes del bloque de cristal: se une al grupo "hurtbox"
## para que el AttackHitbox del jugador lo detecte, y reenvía el golpe al
## bloque padre (que decide si se rompe según la habilidad equipada).

func receive_hit(hitbox: Hitbox) -> void:
	var block := get_parent()
	if block != null and block.has_method("receive_hit"):
		block.receive_hit(hitbox)
