extends Node
## Gestor de audio (autoload "Audio").
## Define los buses y expone la API de reproducción.
## El mapeo sfx_id/track_id -> streams se añadirá en data/audio/ cuando
## existan assets; aquí queda la interfaz estable.

signal music_changed(track_id: String)

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const BUS_UI := "UI"

var _music_player: AudioStreamPlayer
var _current_track: String = ""

func _ready() -> void:
	_ensure_buses()
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)

func _ensure_buses() -> void:
	for bus_name in [BUS_MUSIC, BUS_SFX, BUS_UI]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

func set_bus_volume(bus_name: String, volume_db: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index != -1:
		AudioServer.set_bus_volume_db(index, volume_db)

func get_bus_volume(bus_name: String) -> float:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return -80.0
	return AudioServer.get_bus_volume_db(index)

func play_sfx(sfx_id: String, _position: Vector2 = Vector2.INF) -> void:
	# TODO: tabla sfx_id -> AudioStream en data/audio/
	pass

func play_music(track_id: String, _fade_seconds: float = 1.0) -> void:
	if track_id == _current_track:
		return
	_current_track = track_id
	music_changed.emit(track_id)
	# TODO: cargar data/audio/music/<track_id>.{ogg,mp3} y reproducir con fade

func stop_music() -> void:
	_current_track = ""
	_music_player.stop()
