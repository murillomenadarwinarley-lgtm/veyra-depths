extends Node
## Gestor de audio (autoload "Audio").
## Define los buses y expone la API de reproducción (play_sfx, play_music).
## Los SFX se sintetizan en runtime (AudioStreamWAV generado por código):
## sin assets todavía, pero con sonido real. Cuando existan assets en
## data/audio/, play_sfx puede pasar a una tabla de streams sin romper
## la API.

signal music_changed(track_id: String)

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const BUS_UI := "UI"

const SFX_POOL_SIZE := 8
const MIX_RATE := 22050

var _music_player: AudioStreamPlayer
var _current_track: String = ""
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index := 0
var _sfx_streams: Dictionary = {}

func _ready() -> void:
	_ensure_buses()
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)
	_generate_sfx()
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_sfx_pool.append(player)

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

## Reproduce un efecto de sonido. `_position` queda reservado para
## audio posicional cuando existan assets; los SFX sintetizados suenan
## sin espacialización por ahora.
func play_sfx(sfx_id: String, _position: Vector2 = Vector2.INF) -> void:
	var stream: AudioStream = _sfx_streams.get(sfx_id)
	if stream == null:
		push_warning("Audio.play_sfx: sfx desconocido '%s'" % sfx_id)
		return
	var player := _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_pool.size()
	player.stream = stream
	player.play()

func play_music(track_id: String, _fade_seconds: float = 1.0) -> void:
	if track_id == _current_track:
		return
	_current_track = track_id
	music_changed.emit(track_id)
	# TODO: cargar data/audio/music/<track_id>.{ogg,mp3} y reproducir con fade

func stop_music() -> void:
	_current_track = ""
	_music_player.stop()

## -- Síntesis procedural de SFX (placeholder hasta tener assets) --

func _generate_sfx() -> void:
	_sfx_streams["hit"] = _noise_burst(0.07, 0.85, 55.0, 0.35)
	_sfx_streams["hurt"] = _tone(240.0, 90.0, 0.16, 0.9, 18.0, "square")
	_sfx_streams["whoosh"] = _noise_burst(0.16, 0.5, 22.0, 0.5)
	_sfx_streams["dash"] = _noise_burst(0.22, 0.45, 16.0, 0.45)
	_sfx_streams["land"] = _tone(120.0, 70.0, 0.09, 0.7, 30.0)
	_sfx_streams["jump"] = _tone(260.0, 480.0, 0.09, 0.35, 20.0)
	_sfx_streams["death"] = _tone(300.0, 60.0, 0.28, 0.8, 10.0, "square")
	_sfx_streams["roar"] = _tone(90.0, 40.0, 0.5, 0.9, 24.0, "square")
	_sfx_streams["pickup"] = _tone(660.0, 990.0, 0.14, 0.6, 14.0)
	_sfx_streams["dive"] = _tone(90.0, 40.0, 0.18, 0.9, 22.0, "square")
	_sfx_streams["ambush"] = _tone(90.0, 380.0, 0.4, 0.85, 9.0, "square")

## Ruido blanco con paso-bajo de un polo y decaimiento exponencial.
func _noise_burst(duration: float, volume: float, decay: float, lowpass: float) -> AudioStreamWAV:
	var count := int(duration * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var prev := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		var white := randf() * 2.0 - 1.0
		prev += (white - prev) * clampf(lowpass, 0.0, 1.0)
		samples[i] = prev * exp(-t * decay) * volume
	return _make_wav(samples)

## Tono con barrido de frecuencia y decaimiento exponencial.
func _tone(freq_start: float, freq_end: float, duration: float, volume: float, decay: float, wave: String = "sine") -> AudioStreamWAV:
	var count := int(duration * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		var freq := lerpf(freq_start, freq_end, t / duration)
		phase += TAU * freq / MIX_RATE
		var raw: float
		match wave:
			"square":
				raw = 1.0 if sin(phase) >= 0.0 else -1.0
			"triangle":
				raw = 2.0 * absf(2.0 * (phase / TAU - floorf(phase / TAU + 0.5))) - 1.0
			_:
				raw = sin(phase)
		samples[i] = raw * exp(-t * decay) * volume
	return _make_wav(samples)

func _make_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	stream.data = bytes
	return stream
