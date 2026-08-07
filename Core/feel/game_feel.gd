extends Node
## Autoload "Feel": feedback de impacto global.
## Hitstop (congelar el tiempo brevemente al golpear), sacudida de cámara,
## partículas de efectos y flashes de daño. API sin estado:
## Feel.hitstop(), Feel.screen_shake(), Feel.dust(), Feel.sparks(),
## Feel.slash(), Feel.burst(), Feel.flash().

const EFFECT_HIT_SPARKS := preload("res://FX/hit_sparks.tscn")
const EFFECT_DUST := preload("res://FX/dust.tscn")
const EFFECT_DEATH_BURST := preload("res://FX/death_burst.tscn")
const EFFECT_SLASH := preload("res://FX/slash.tscn")

var _hitstop_frames_left: int = 0
var _base_colors: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## El hitstop se cuenta en frames de física (60 Hz fijos): con
## time_scale = 0 los relojes del motor se congelan, así que no se usa
## Time/OS; el contador avanza porque la iteración de física no se detiene.
func _physics_process(_delta: float) -> void:
	if _hitstop_frames_left > 0:
		_hitstop_frames_left -= 1
		if _hitstop_frames_left == 0:
			Engine.time_scale = 1.0

## Congela el juego `seconds` (p. ej. 0.06 al conectar un golpe).
## El tiempo real no se detiene: la cámara de shake sigue viva en ese
## intervalo y el sonido del golpe suena mientras el mundo está quieto.
func hitstop(seconds: float) -> void:
	Engine.time_scale = 0.0
	_hitstop_frames_left = maxi(_hitstop_frames_left, int(seconds * 60.0))

## Sacudida de cámara (0.0-1.0). Se acumula y decae sola.
func screen_shake(amount: float) -> void:
	var cam := _camera()
	if cam != null:
		cam.add_shake(amount)

## Polvo al aterrizar / correr.
func dust(at: Vector2) -> void:
	spawn_effect(EFFECT_DUST, at)

## Chispas al conectar un golpe.
func sparks(at: Vector2) -> void:
	spawn_effect(EFFECT_HIT_SPARKS, at)

## Arco del ataque del jugador, orientado a `rotation`.
func slash(at: Vector2, rotation_rad: float) -> void:
	var effect := spawn_effect(EFFECT_SLASH, at, Color.WHITE, rotation_rad)
	if effect != null and effect.has_method("play"):
		effect.play()

## Explosión de partículas de muerte (color del enemigo).
func burst(at: Vector2, color: Color) -> void:
	spawn_effect(EFFECT_DEATH_BURST, at, color)

## Parpadeo de daño: el visual se tiñe del color y vuelve a su base.
func flash(entity: Node, color: Color = Color.WHITE, duration: float = 0.15) -> void:
	var visual := entity.get_node_or_null("Visual") as Polygon2D
	if visual == null:
		return
	if not _base_colors.has(visual):
		_base_colors[visual] = visual.color
	var base: Color = _base_colors[visual]
	var tween := visual.create_tween()
	tween.tween_property(visual, "color", color, duration * 0.35)
	tween.tween_property(visual, "color", base, duration * 0.65)

func _camera() -> RoomCamera:
	var player: Node2D = RoomStreamer.player
	if player == null:
		return null
	return player.get_node_or_null("Camera2D") as RoomCamera

## Instancia un efecto en el mundo y se encarga de que se libere solo
## (CPUParticles2D one-shot: vía finished; otros: que lo haga su script).
func spawn_effect(scene: PackedScene, at: Vector2, color: Color = Color.WHITE, rotation_rad: float = 0.0) -> Node2D:
	var world := RoomStreamer.get_world_root()
	if world == null:
		return null
	var effect := scene.instantiate() as Node2D
	effect.global_position = at
	effect.rotation = rotation_rad
	world.add_child(effect)
	if effect is CPUParticles2D:
		var particles := effect as CPUParticles2D
		particles.color = color
		particles.emitting = false
		particles.finished.connect(particles.queue_free)
		particles.emitting = true
	return effect

