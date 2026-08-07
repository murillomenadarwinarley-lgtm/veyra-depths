class_name TouchControls
extends CanvasLayer
## Controles táctiles: joystick virtual (movimiento) y botones de acción.
## Todos simulan las acciones del Input Map, así que no hay lógica de
## juego duplicada. Se muestran solo en dispositivos táctiles.

const ACTIONS := ["move_left", "move_right", "jump", "dash", "attack", "down", "focus", "spell"]

func _ready() -> void:
	$Buttons/JumpButton.button_down.connect(_on_jump_down)
	$Buttons/JumpButton.button_up.connect(_on_jump_up)
	$Buttons/DashButton.button_down.connect(_on_dash_down)
	$Buttons/DashButton.button_up.connect(_on_dash_up)
	$Buttons/AttackButton.button_down.connect(_on_attack_down)
	$Buttons/AttackButton.button_up.connect(_on_attack_up)
	$Buttons/DownButton.button_down.connect(_on_down_down)
	$Buttons/DownButton.button_up.connect(_on_down_up)
	$Buttons/FocusButton.button_down.connect(_on_focus_down)
	$Buttons/FocusButton.button_up.connect(_on_focus_up)
	$Buttons/SpellButton.button_down.connect(_on_spell_down)
	$Buttons/SpellButton.button_up.connect(_on_spell_up)

func _exit_tree() -> void:
	release_all()

## Libera todas las acciones por si un dedo sigue "presionando" cuando
## los controles se ocultan (pausa, game over, volver al menú).
func release_all() -> void:
	for action in ACTIONS:
		Input.action_release(action)

func _on_jump_down() -> void:
	Input.action_press("jump")

func _on_jump_up() -> void:
	Input.action_release("jump")

func _on_dash_down() -> void:
	Input.action_press("dash")

func _on_dash_up() -> void:
	Input.action_release("dash")

func _on_attack_down() -> void:
	Input.action_press("attack")

func _on_attack_up() -> void:
	Input.action_release("attack")

func _on_down_down() -> void:
	Input.action_press("down")

func _on_down_up() -> void:
	Input.action_release("down")

func _on_focus_down() -> void:
	Input.action_press("focus")

func _on_focus_up() -> void:
	Input.action_release("focus")

func _on_spell_down() -> void:
	Input.action_press("spell")

func _on_spell_up() -> void:
	Input.action_release("spell")
