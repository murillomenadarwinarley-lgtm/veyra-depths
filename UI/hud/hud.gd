extends CanvasLayer
## HUD del juego. Se suscribe a las señales de Progress y RoomStreamer
## para reflejar el estado sin consultar nada directamente.

@onready var room_label: Label = $Panel/RoomLabel
@onready var abilities_label: Label = $Panel/AbilitiesLabel

func _ready() -> void:
	Progress.room_visited.connect(_on_room_visited)
	Progress.ability_unlocked.connect(_on_ability_unlocked)
	_refresh()

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

func _on_room_visited(_room_id: String) -> void:
	_refresh()

func _on_ability_unlocked(_ability_id: String, _level: int) -> void:
	_refresh()
