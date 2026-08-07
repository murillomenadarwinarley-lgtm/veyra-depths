# Veyra Depths

Metroidvania 2D estilo Silksong hecho en **Godot 4** (4.3+ recomendado).

Este repositorio contiene el **esqueleto de arquitectura**: sin lógica de
gameplay completa, pero con todas las infraestructuras montadas y
funcionales para escalar a un juego grande:

- **Mapa en datos**: el grafo de salas, puertas y requisitos vive en
  `data/map/world_map.json`, nunca hardcodeado.
- **Streaming de salas**: solo se mantienen en memoria la sala actual y sus
  vecinas; el resto se carga/descarga dinámicamente.
- **Habilidades centralizadas**: catálogo en `data/abilities/abilities.json`
  + registro `Abilities` + estado `Progress`. Ningún `if tiene_dash` suelto.
- **Composición en entidades**: enemigos = `Entity` + componentes
  (Salud, Movimiento, IA, Ataque), no herencia profunda.

## Requisitos

- Godot 4.3 o superior (editor estándar; el proyecto usa GL Compatibility
  si lo activas en `[rendering]`).
- Abrir el proyecto con `godot --editor --path .` y pulsar F5.

## Estructura de carpetas

```
veyra-depths/
├── project.godot            # autoloads e inputs registrados
├── Core/                    # máquina de estados del juego
│   ├── main.tscn            # escena raíz (placeholder)
│   ├── game_state.gd        # autoload "Game": menú/juego/pausa/game over
│   ├── fsm/                 # State + StateMachine genéricos (reutilizables)
│   └── states/              # main_menu, playing, pause, game_over
├── Player/                  # controlador del jugador + FSM de estados
│   ├── player.tscn
│   ├── player.gd            # registra estados, expone datos básicos
│   └── states/              # idle, run, jump, dash, attack, hurt
├── World/
│   ├── map/                 # MapGraph (Resource) + autoload "WorldMap"
│   ├── rooms/               # room.gd (base) + salas concretas
│   ├── streaming/           # autoload "RoomStreamer"
│   └── cameras/             # RoomCamera (límites por sala, desde datos)
├── Entities/                # composición: componentes, no herencia
│   ├── entity.gd            # base genérica con get_component()
│   ├── components/          # health, movement, ai, attack
│   └── enemies/             # enemy.gd + enemigos concretos (crawler)
├── Systems/
│   ├── abilities/           # AbilityDefinition + autoload "Abilities"
│   ├── inventory/           # autoload "Inventory"
│   ├── progress/            # autoload "Progress" (progreso del jugador)
│   ├── save/                # autoload "Saves" (user://saves/)
│   ├── audio/               # autoload "Audio" (buses y API)
│   └── data/                # JsonLoader (utilidad JSON)
├── UI/
│   ├── hud/                 # HUD en juego
│   ├── map/                 # pantalla de mapa (WIP)
│   └── menus/               # main menu, pausa, game over
└── data/
    ├── map/world_map.json   # GRAFO DEL MUNDO (fuente de verdad)
    └── abilities/abilities.json  # CATÁLOGO DE HABILIDADES
```

## Autoloads (singletons)

Orden de carga en `project.godot` (importante: los que dependen de otros van
después):

| Nombre | Archivo | Responsabilidad |
|---|---|---|
| `Audio` | `Systems/audio/audio_manager.gd` | Buses (Music/SFX/UI), API de reproducción |
| `Abilities` | `Systems/abilities/ability_registry.gd` | Catálogo de definiciones de habilidades |
| `Inventory` | `Systems/inventory/inventory.gd` | Items del jugador (id -> cantidad) |
| `Progress` | `Systems/progress/player_progress.gd` | **Progreso**: habilidades, salas, jefes, stats |
| `Saves` | `Systems/save/save_manager.gd` | Guardado/carga en `user://saves/` |
| `WorldMap` | `World/map/world_map.gd` | Grafo del mundo en memoria + comprobación de puertas |
| `RoomStreamer` | `World/streaming/room_streamer.gd` | Streaming de salas + jugador |
| `Game` | `Core/game_state.gd` | FSM de flujo: menú -> juego -> pausa/game over |

`Progress` es el **progreso del jugador**: habilidades desbloqueadas
(con nivel), salas visitadas, jefes derrotados, playtime y muertes.
Todo lo demás lee/escribe aquí y se serializa con `to_dict()` /
`load_from_dict()` para el guardado.

## Convención de nombres

| Elemento | Convención | Ejemplo |
|---|---|---|
| Carpetas y scripts | `snake_case` | `player_progress.gd`, `World/streaming/` |
| Clases (`class_name`) | `PascalCase` | `HealthComponent`, `RoomCamera` |
| Escenas | `snake_case` | `main_menu.tscn`, `hollow_cavern.tscn` |
| Nodos | `PascalCase` | `GateNorth`, `PlayerSpawn` |
| Señales | `snake_case`, verbo en pasado | `ability_unlocked`, `room_entered` |
| Constantes | `SCREAMING_SNAKE_CASE` | `DASH_DURATION`, `SAVE_DIR` |
| Variables y métodos | `snake_case` | `current_room_id`, `enter_gate()` |
| Estados FSM | `<algo>_state.gd` | `dash_state.gd`, `pause_state.gd` |
| Componentes | `<algo>_component.gd` | `health_component.gd` |

Reglas generales:

- **Un `class_name` por script** en Core/Player/World/Entities/Systems/UI
  (los autoloads no necesitan `class_name`).
- Los **estados FSM son `RefCounted`**, no Nodes: los crea el `StateMachine`
  con `add_state(&"id", Estado.new(machine, actor))`.
- Los **autoloads se referencian por su nombre global** (`Progress`,
  `RoomStreamer`, `Game`...), sin preload.
- Los **ids** (salas, puertas, habilidades, jefes, items) son strings
  `snake_case` definidos en los JSON de `data/`.

## Cómo añadir una sala nueva

1. **Crear la escena** en `World/rooms/rooms/<sala>.tscn` con:
   - Nodo raíz `Node2D` con script `room.gd` y `room_id = "mi_sala"`.
   - Un marcador `PlayerSpawn` (Marker2D) con la posición de aparición.
   - Una `Area2D` por puerta, en el grupo `room_gate`, con metadata
     `gate_id = "gate_norte"`. `room.gd` conecta `body_entered`
     automáticamente y delega en `RoomStreamer.enter_gate()`.
2. **Registrar la sala en el grafo**: añadir una entrada a
   `data/map/world_map.json`:
   ```json
   {
     "id": "mi_sala",
     "scene": "res://World/rooms/rooms/mi_sala.tscn",
     "display_name": "Mi Sala",
     "music": "mi_tema",
     "bounds": { "left": 0, "top": 0, "right": 1920, "bottom": 1080 },
     "gates": [
       { "id": "gate_norte", "to_room": "room_crossroads",
         "requires_ability": "", "requires_boss": "" },
       { "id": "gate_este", "to_room": "room_secreta",
         "requires_ability": "dash", "requires_boss": "" }
     ]
   }
   ```
   - `requires_ability`: id de habilidad del catálogo de habilidades; si el
     jugador no la tiene, la puerta no deja pasar (`WorldMap.can_traverse()`).
   - `requires_boss`: id de jefe; la puerta se abre al derrotarlo
     (`Progress.defeat_boss(id)`).
3. **Nada más**: el streaming, la cámara (bounds) y el mapa usan el JSON.

> La conexión entre salas **solo** vive en el JSON. Las `Area2D` de las
> salas solo aportan la posición física de la puerta y su `gate_id`.

## Cómo añadir una habilidad

1. Añadir la entrada a `data/abilities/abilities.json`:
   ```json
   { "id": "dash", "display_name": "Dash", "category": "movilidad",
     "description": "...", "max_level": 1 }
   ```
   Campo opcional `effect_script`: path a un script con efectos al
   desbloquearse (se aplicará desde `Progress.grant_ability()`).
2. Desbloquearla en el juego con `Progress.grant_ability("dash")`.
3. Consultarla desde cualquier sitio con `Progress.has_ability("dash")`
   (estados del jugador, puertas del mapa, UI...).
4. Las puertas del mapa que la requieran: `"requires_ability": "dash"` en
   `world_map.json`.

## Cómo añadir un enemigo (composición)

1. Crear la escena en `Entities/enemies/<enemigo>.tscn`: raíz `Node2D` con
   `enemy.gd` + los componentes que necesite como hijos:
   - `HealthComponent` (vida), `MovementComponent` (velocidad),
     `AIComponent` (IDLE/PATROL/CHASE/ATTACK), `AttackComponent` (daño).
2. Ajustar los `@export` de cada componente en la escena.
3. La lógica específica del enemigo (patrones de IA) va en un script
   propio que extienda `Enemy` o que se suscriba a las señales de los
   componentes (`AIComponent.state_changed`, `HealthComponent.died`).
4. Instanciar el enemigo dentro de la sala donde vive.

## Cómo añadir un estado de juego nuevo

1. Crear `Core/states/<estado>_state.gd` extendiendo `State`.
2. Registrarlo en `Core/game_state.gd` (`add_state(&"mi_estado", ...)`).
3. (Opcional) Crear su UI en `UI/menus/` y mostrarla con
   `Game.show_ui("res://UI/menus/<estado>.tscn")`.

## Notas de arquitectura

- **Streaming**: `RoomStreamer` carga la sala actual + vecinas del grafo
  (`STREAM_RADIUS = 1`) y libera el resto con `queue_free()`.
- **Guardado**: partidas en `user://saves/slot_<n>.json` (JSON legible).
  `Saves.save_game(slot)` hace snapshot de `Progress` + sala actual.
- **Pausa**: `Game` usa `process_mode = ALWAYS` para que los menús
  sigan respondiendo con el árbol en pausa.
- **Cámara**: `RoomCamera` se configura desde los `bounds` del JSON de cada
  sala (limita la vista a la sala actual).
- **TODO pendiente**: animaciones, hitboxes, arte, audio assets
  (`data/audio/`), mapa del mundo renderizado, guardado por slots en UI.
