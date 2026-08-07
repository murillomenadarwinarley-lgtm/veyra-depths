class_name RangedAttackComponent
extends AttackComponent
## Variante de AttackComponent para enemigos a distancia: en lugar de
## activar una hitbox propia, instancia y dispara un Projectile hacia la
## dirección que le pasa la IA. No requiere tocar ai_component.gd.
## Todos los parámetros son @export para ajustar la dificultad por escena.

@export var projectile_scene: PackedScene
## Velocidad del proyectil lanzado (0.0 usa la del propio Projectile).
@export var projectile_speed: float = 300.0
## Daño del proyectil (los valores del Projectile se sobrescriben al
## disparar, así el atacante controla su dificultad).
@export var projectile_damage: int = 1
@export var projectile_knockback: float = 150.0
@export var projectile_knockback_vertical: float = 0.0
@export var projectile_life_time: float = 3.0
## Offset del cañón respecto al centro del enemigo (el signo X se invierte
## según la dirección de disparo).
@export var muzzle_offset: Vector2 = Vector2(36, -6)

## El ataque a distancia no usa hitbox propia: no hay que avisar si falta.
func _requires_hitbox() -> bool:
	return false

## Punto de extensión del ataque: dispara el proyectil hacia `direction`
## en lugar de activar la hitbox.
func _do_hit(direction: Vector2) -> void:
	if projectile_scene == null:
		push_warning("RangedAttackComponent: entidad '%s' sin projectile_scene asignado" % (_actor.name if _actor else "?"))
		return
	var projectile: Projectile = projectile_scene.instantiate()
	var dir := direction.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2(_movement.facing.x, 0.0) if _movement else Vector2.RIGHT
	var offset := muzzle_offset
	offset.x *= 1.0 if dir.x >= 0.0 else -1.0
	projectile.global_position = _actor.global_position + offset
	projectile.damage = projectile_damage
	projectile.knockback_strength = projectile_knockback
	projectile.knockback_vertical = projectile_knockback_vertical
	projectile.invulnerability_duration = invulnerability_duration
	projectile.life_time = projectile_life_time
	_actor.get_parent().add_child(projectile)
	projectile.setup(dir, projectile_speed)
