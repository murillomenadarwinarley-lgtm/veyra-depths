# AGENTS.md — Notas de proyecto

## Flujo de trabajo obligatorio
- **Commit + push tras cada tarea terminada** (el usuario lo pide explícitamente siempre).
- Verificar con smoke tests headless antes de commitear:
  `godot --path . --headless res://<test>.tscn --fixed-fps 60`
- Los tests viven en `/tmp/opencode/` (fuera del repo): se copian a la raíz del proyecto, se ejecutan y se borran antes del commit.
- Si se añade una clase global nueva (class_name), regenerar la caché: `godot --headless --import --path .`.
- Tras añadir un SFX nuevo, actualizar la cuenta de `feel_smoke.gd` (pool de `_sfx_streams`).

## Requisitos de diseño del usuario
- **Sistema de enemigos que aparecen mientras se cruza por los lugares** (encuentros de exploración): debe ser **DIFÍCIL**. Diseñar la dificultad como prioridad (poco margen de error, respuestas claras a los patrones, progresión de dificultad).
- **Armas del personaje**: el usuario quiere que el sistema de armas del personaje sea parte del diseño. Aún sin implementar — cuando se trabaje en armas, añadir una opción de arma mejorada/fuerte además del ataque básico, coherente con la dificultad alta.
- Estilo de referencia: Metroidvania tipo Silksong.
- **Cámara**: zoom FIJO y cercano al jugador (constante `CAMERA_ZOOM` en `room_camera.gd`), nunca atado a los bounds de la sala ni al tamaño del mapa.
- **Jefes**: cada jefe tiene su propia sala-arena SIN enemigos normales (la cripta es el modelo: solo jefe + objetos de la sala). Nunca mezclar jefes con enemigos comunes en el mismo espacio.
- **Gate de progreso por sección**: derrotar al jefe de cada sección desbloquea la siguiente vía `requires_boss` en `world_map.json` (ya operativo en la cripta con "crypt_warden").
- **Sin daño amigo**: los enemigos nunca se dañan entre sí (ni a los jefes); el filtro de equipo vive en `hurtbox.gd` (grupos "player" vs resto).

## Arquitectura (datos aprendidos, no romper)
- **Banda del mundo por sala**: cada sala vive en su banda de Y del mundo (encrucijada y 0..1080, caverna -1080..0, cripta -2160..-1080). Las coordenadas locales de cada escena son sus coordenadas de banda. Los tests deben usar coordenadas de la sala correcta; si no, el jugador cae sobre el suelo de otra sala vecina cargada por streaming.
- Los smoke tests deben borrar `user://saves/slot_0.json` al arrancar (el save restaura la sala guardada y falsifica resultados).
- Habilidades: catálogo en `data/abilities/abilities.json`, registro `Abilities`, concesión vía `Progress.grant_ability`, uso con `Progress.has_ability()`. Nunca strings sueltos en el código.
- Estados del jugador son `RefCounted` (no Nodes): no usar `get_tree()`/`get_parent()` — usar `player.get_tree()` / `player.get_parent()`.
- Estado del jugador: dash (abajo+ataque en aire se convierte en buceo con la habilidad "dive").
- Habilidades actuales: dash, double_jump, dive, wall_jump, crystal_heart.
