extends CanvasLayer
## HUD del juego. Se suscribe a las señales de Progress, RoomStreamer y
## la salud del jugador para reflejar el estado sin consultar nada directo.

@onready var room_label: Label = $Panel/RoomLabel
@onready var abilities_label: Label = $Panel/AbilitiesLabel
@onready var health_label: Label = $Panel/HealthLabel

func _ready() -> void:
	Progress.room_visited.connect(_on_room_visited)
	Progress.ability_unlocked.connect(_on_ability_unlocked)
	_refresh()
	# El jugador se crea en el bootstrap justo después de mostrar el HUD.
	call_deferred("_refresh_health")

func _refresh() -> void:
	if not RoomStreamer.current_room_id.is_empty():
		var room := WorldMap.get_room(RoomStreamer.current_room_id)
		room_label.text = "Sala: %s" % room.get("display_name", RoomStreamer.current_room_id)
	else:
		room_label.text = "Sala: -"
	var names := PackedStringArray()
	for ability_id in Progress.unlocked_abilities:
		var definition := Abilities.get_definition(ability_id)
		names.append(definition.display_name if definition else ability_id)
	abilities_label.text = "Habilidades: %s" % ", ".join(names)

func _refresh_health() -> void:
	var player := RoomStreamer.player
	if player == null:
		return
	var health := player.get_node_or_null("Health") as HealthComponent
	if health == null:
		return
	if not health.health_changed.is_connected(_on_health_changed):
		health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.health, health.max_health)

func _on_health_changed(current: int, max_health: int) -> void:
	health_label.text = "Vida: %d/%d" % [current, max_health]

func _on_room_visited(_room_id: String) -> void:
	_refresh()

func _on_ability_unlocked(_ability_id: String, _level: int) -> void:
	_refresh()
