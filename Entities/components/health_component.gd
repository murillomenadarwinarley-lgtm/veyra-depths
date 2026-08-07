class_name HealthComponent
extends Node
## Componente de salud reutilizable (jugador, enemigos, NPCs, jefes).

signal health_changed(current: int, max_health: int)
signal damaged(amount: int, source: Node)
signal died

@export var max_health: int = 5

var health: int = 0

func _ready() -> void:
	health = max_health

func take_damage(amount: int, source: Node = null) -> void:
	if health <= 0:
		return
	health = maxi(0, health - amount)
	damaged.emit(amount, source)
	health_changed.emit(health, max_health)
	if health == 0:
		died.emit()

func heal(amount: int) -> void:
	health = mini(max_health, health + amount)
	health_changed.emit(health, max_health)

## Fija la salud exacta (p. ej. al cargar partida) y emite el cambio.
func set_health(value: int) -> void:
	health = clampi(value, 0, max_health)
	health_changed.emit(health, max_health)

func die() -> void:
	if health > 0:
		var remaining := health
		health = 0
		damaged.emit(remaining, null)
		health_changed.emit(health, max_health)
	died.emit()

func is_dead() -> bool:
	return health <= 0

func reset() -> void:
	health = max_health
	health_changed.emit(health, max_health)
