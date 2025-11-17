# Base de conocimiento: gameplay y transiciones

## 1. HouseScene (Capítulo 1 - Casa de Dan)
- El jugador controla a Dan con WASD/Flechas y pulsa `E` para interactuar.
- Cada habitación se limita con un `Container`; puertas amarillas son `DoorData` con detección automática.
- La transición entre habitaciones usa un fade a negro (400 ms) y aplica un cooldown de 0.5 s para evitar rebotes.
- El HUD muestra el capítulo, la habitación actual y cambia de mensaje según el estado del diálogo (`ESC: Saltar diálogo`).
- Los diálogos se muestran con `DialogueOverlay`; se puede saltar con ESC gracias a `DialogueSystem.skipDialogue()`.
- El teléfono (Estudio) dispara una secuencia con Marcus; su `onComplete` marca `_phoneCallCompleted` y llama a `_transitionToCombat()` tras 2 segundos.

## 2. Capítulo 2: Búnker (BunkerScene) - DISEÑO COMPLETO
### Estructura: 9 habitaciones
0. **Exterior** - Spawn inicial, vista del búnker, AQUÍ sucede el mini-combate
1. **Vestíbulo** - Primera habitación interior, puerta de salida al exterior
2. **Pasillo Principal** - Hub central con puertas a todas las áreas
3. **Armería** - Armas y equipo (futuro: pickups)
4. **Biblioteca/Archivos** - Lore sobre Resonantes y Sector 4
5. **Laboratorio Central** ⭐ - Mel en la cápsula, diálogo principal
6. **Centro de Comando** ⭐ - Briefing final, trigger para salir al combate
7. **Dormitorio** - Opcional
8. **Comedor** - Opcional

### Flujo del capítulo:
```
Casa de Dan → Búnker Exterior → Vestíbulo → Exploración → Laboratorio (Mel) 
→ Centro de Comando → Exterior (mini-combate) → MyApp (Sector 4)
```

### Dos fases del BunkerScene:
1. **Fase exploración:** Sistema de habitaciones igual que HouseScene (WASD, E, ESC, transiciones)
2. **Fase mini-combate:** El Exterior cambia a modo combate después del briefing
   - Spawn de Resonante menor + objeto obsesivo
   - Mecánica tutorial: destruir objeto primero, luego derrotar enemigo
   - Mel disponible como companion (tecla E para curar)
   - Al ganar → Transición a MyApp (combate completo en Sector 4)

## 3. Futuras migraciones a Tiled
- Cada habitación puede mapearse a un `.tmx` con puertas como objetos y capas `Entities`/`Triggers`.
- `MapLoader` se actualizará para instanciar interactables, destructibles y pickups desde propiedades (por ejemplo, `dialogueId`, `type=door`).
- Los límites pueden seguir siendo manejados en Flutter hasta que el mapa Tiled los defina.

## 4. Sistema de cámara (pendiente de implementación)

### Dos modos según el tipo de mapa:

**Cámara que sigue a Dan (mapas grandes):**
- Centrada en el jugador, se mueve con él
- Límites del mapa para no ver fuera del área
- Uso: Exterior amplio, áreas abiertas tipo RPG

**Cámara fija (habitaciones pequeñas):**
- Habitación completa visible
- Dan se mueve pero cámara estática
- Uso: Habitaciones del búnker y casa de Dan

**Criterio:** Si roomSize > pantalla → cámara sigue; si roomSize <= pantalla → cámara fija

## 5. Documentos de referencia
- `ROOM_SYSTEM_IMPLEMENTATION.md` – referencia completa de habitaciones y transiciones.
- `SKIP_DIALOGUE_IMPLEMENTATION.md` – detalles del sistema de skip y shortcuts.
- `WORK_LOG.md` – registro cronológico de avances recientes.
- `BUNKER_DESIGN.md` – diseño completo del búnker con 9 habitaciones.
