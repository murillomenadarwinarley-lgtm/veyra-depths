class_name Platform
## Utilidades de plataforma y detección de dispositivo.

## True en dispositivos con pantalla táctil (móviles Android/iOS y web
## móvil); false en escritorio. Determina si se muestran los controles
## táctiles (UI/touch/).
static func is_touch_device() -> bool:
	return OS.has_feature("touch") or OS.has_feature("mobile")
