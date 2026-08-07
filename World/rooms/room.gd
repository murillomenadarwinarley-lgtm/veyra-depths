class_name Room
extends Node2D
## Base de toda sala. La identificación (room_id) debe coincidir con la
## entrada del grafo en data/map/world_map.json.
## Las puertas son Area2D en el grupo "room_gate" con metadata "gate_id";
## al cruzarlas el jugador, se delega en RoomStreamer.enter_gate().

@export var room_id: String = ""

func _ready() -> void:
	add_to_group("rooms")
	_connect_gates()

func _connect_gates() -> void:
	for child in find_children("*", "Area2D", true, false):
		var gate := child as Area2D
		if gate != null and gate.is_in_group("room_gate"):
			gate.body_entered.connect(_on_gate_body_entered.bind(gate))

func _on_gate_body_entered(body: Node2D, gate: Area2D) -> void:
	if body.is_in_group("player"):
		RoomStreamer.enter_gate(room_id, gate.get_meta("gate_id"))
