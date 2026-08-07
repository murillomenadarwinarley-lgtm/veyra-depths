class_name TouchControls
extends CanvasLayer
## Controles táctiles: joystick virtual (movimiento) y botones de acción.
## Todos simulan las acciones del Input Map, así que no hay lógica de
## juego duplicada. Se muestran solo en dispositivos táctiles.

const ACTIONS := ["move_left", "move_right", "jump", "dash", "attack"]

func _ready() -> void:
	$Buttons/JumpButton.button_down.connect(_on_jump_down)
	$Buttons/JumpButton.button_up.connect(_on_jump_up)
	$Buttons/DashButton.button_down.connect(_on_dash_down)
	$Buttons/DashButton.button_up.connect(_on_dash_up)
	$Buttons/AttackButton.button_down.connect(_on_attack_down)
	$Buttons/AttackButton.button_up.connect(_on_attack_up)

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
