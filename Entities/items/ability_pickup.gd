class_name AbilityPickup
extends Area2D
## Orbe de habilidad: al tocarlo concede la habilidad indicada (una vez).
## Si la habilidad ya se tiene, el orbe no aparece al cargar la sala
## (se poda en _ready, como los enemigos derrotados).

const COLOR_DASH := Color(0.3, 0.9, 1.0, 1.0)
const COLOR_JUMP := Color(0.75, 1.0, 0.55, 1.0)

@export var ability_id: String = "dash"

@onready var crystal: Polygon2D = $Crystal

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if Progress.has_ability(ability_id):
		queue_free()
		return
	if ability_id == "double_jump":
		crystal.color = COLOR_JUMP

## Flotación suave del cristal.
func _process(_delta: float) -> void:
	crystal.position.y = sin(Time.get_ticks_msec() / 350.0) * 4.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not Progress.has_ability(ability_id):
		Progress.grant_ability(ability_id)
		Audio.play_sfx("pickup")
		Feel.burst(global_position, crystal.color)
		queue_free()
