# Registro de avances - Noviembre 2025

## Sesión 1: Sistema de habitaciones y skip de diálogos

### 1. Arquitectura narrativamente modular
- Reorganicé el `HouseScene` para que ahora maniobre habitaciones individuales usando `RoomManager`, con puertas, límites por `Container` y transiciones con fade a negro.
- Documenté el sistema en `ROOM_SYSTEM_IMPLEMENTATION.md` para tener referencia rápida de cada habitación, sus interactables y la lógica de transición.

### 2. Sistema de diálogo mejorado
- Implementé `skipDialogue()` en `DialogueSystem` y lo expuse mediante `DialogueOverlay.skipCurrent()` con una clave global dinámica.
- Añadí soporte para la tecla `ESC` en el juego para cerrar cualquier diálogo activo sin romper la secuencia; el HUD cambia a "ESC: Saltar diálogo" cuando hay diálogo.
- Eliminé el botón de skip del gameplay (queda reservado para el menú de capítulos) y documenté el flujo en `SKIP_DIALOGUE_IMPLEMENTATION.md`.

### 3. Interacciones táctiles y telefonía
- Implementé `_tryInteract()` en `HouseScene` para detectar objetos dentro del radio, ejecutar diálogos y activar lógicas específicas (línea telefónica → transición al búnker).
- El teléfono ahora marca `_phoneCallCompleted`, muestra la secuencia y dispara transición al Capítulo 2.

---

## Sesión 2: Implementación completa del Búnker (Capítulo 2)

### 1. Diseño del búnker
- Creé `BUNKER_DESIGN.md` con el diseño completo de 9 habitaciones basado en imagen de referencia IA.
- Definí flujo narrativo: Exterior → Vestíbulo → Exploración → Laboratorio (Mel) → Centro de Comando → Mini-combate → Sector 4.

### 2. BunkerRoomManager implementado
**Archivo:** `lib/narrative/systems/bunker_room_manager.dart`

**9 habitaciones creadas:**
0. **Exterior** - Spawn inicial, vista del búnker, área de mini-combate futuro
1. **Vestíbulo** - Entrada/salida, panel de seguridad, casilleros
2. **Pasillo Principal** - Hub central con puertas a todas las áreas
3. **Armería** - Estante de armas, mesa de trabajo
4. **Biblioteca/Archivos** - Documentos sobre Resonantes, terminal con info de Emma
5. **Laboratorio Central** ⭐ - Mel en cápsula, diálogo principal del capítulo
6. **Centro de Comando** ⭐ - Consola principal con briefing de Marcus
7. **Dormitorio** - Área opcional con cama
8. **Comedor** - Área opcional con mesa

**Características:**
- Cada habitación tiene interactables con diálogos
- Puertas conectan todas las habitaciones lógicamente
- Spawn points específicos para cada transición
- Colores de fondo únicos por tipo de habitación

### 3. BunkerScene implementado
**Archivo:** `lib/narrative/screens/bunker_scene.dart`

**Sistema completo de exploración:**
- ✅ Sistema de habitaciones igual que HouseScene
- ✅ Transiciones con fade (400ms) y cooldown (0.5s)
- ✅ Movimiento con WASD/Flechas
- ✅ Interacción con tecla E
- ✅ Skip de diálogos con ESC
- ✅ HUD dinámico que muestra capítulo, habitación y objetivo
- ✅ Monólogo inicial de llegada al búnker
- ✅ Detección de interactables clave (Mel, consola de comando)
- ✅ Transición automática al combate después del briefing

**Objetivos dinámicos:**
- Exterior: "Entrar al búnker"
- Interior: "Encontrar a Mel"
- Después de Mel: "Ir al Centro de Comando"
- Después del briefing: "Prepararse para el combate"

### 4. Conexión de capítulos
- Actualicé `HouseScene` para que `_transitionToCombat()` vaya a `BunkerScene` en lugar de `MyApp`
- Flujo completo: Casa de Dan → Búnker → MyApp (Combate en Sector 4)

### 5. Documentación actualizada
- `GAMEPLAY_KNOWLEDGE.md` - Base de conocimiento con diseño completo del búnker
- `BUNKER_DESIGN.md` - Diseño detallado de las 9 habitaciones y flujo narrativo
- `README.md`, `CURRENT_STATE.md`, `REFACTOR_SUMMARY.md` - Actualizados con nueva info

---

## Sesión 3: Sistema de cámara y mapa exterior amplio

### 1. Correcciones realizadas
- ✅ Agregados tipos de enum faltantes (RoomType, InteractableType)
- ✅ Implementado método `normalized()` en Vector2
- ✅ Corregido diálogo de Mel (primer encuentro con Dan)
- ✅ Agregado enum `CameraMode` a RoomData

### 2. Sistema de cámara implementado
- ✅ Creada memoria persistente sobre sistema de cámara dual
- ✅ Actualizado `GAMEPLAY_KNOWLEDGE.md` con especificaciones
- ✅ Definidos dos modos: fixed (habitaciones) y follow (mapas grandes)
- ✅ Implementado método `_buildRoomWithCamera()` en BunkerScene
- ✅ Cámara que sigue al jugador con límites del mapa
- ✅ Cámara fija para habitaciones pequeñas

### 3. Mapa exterior amplio creado
- ✅ Habitación 'exterior_large' (2000x1500) con CameraMode.follow
- ✅ Interactables: señal de carretera, vehículo abandonado
- ✅ Puerta a la entrada del búnker
- ✅ Spawn inicial en el mapa grande
- ✅ Diálogo inicial actualizado
- ✅ Objetivos dinámicos actualizados

### 4. Flujo completo implementado
```
Casa de Dan → Mapa Exterior Amplio (cámara sigue) → Entrada Búnker → 
Vestíbulo → 9 Habitaciones → Laboratorio (Mel) → Centro de Comando → Combate
```

### 5. Sistema de diálogos rediseñado (estilo visual mejorado)
- ✅ Estructura de assets: `dialogue_icons/`, `full_body/`, `DialogueBody/`
- ✅ **Caja de diálogo elegante**: Bordes sutiles con feedback visual (amarillo cuando listo)
- ✅ **Ancho adaptativo**: Caja deja 350px de espacio a la derecha cuando hay personaje
- ✅ **Avatar pequeño mejorado**: 70x70px, borde delgado, sin cuadro blanco grueso
- ✅ **Personaje grande**: 400x500px sin cuadro feo, encima de la caja de diálogo
- ✅ **Tamaño y posición personalizados por personaje**:
  - **Dan**: 350x450px, offset derecho 50px (más pequeño, más lejos)
  - **Mel**: 420x520px, offset derecho 20px (más grande, más cerca)
  - **Marcus**: 380x480px, offset derecho 30px (tamaño medio, posición media)
- ✅ **Coherencia visual**: Todos los personajes se ven uniformes y bien posicionados
- ✅ **Vignette cinematográfico**: Gradiente radial que oscurece la pantalla
- ✅ **UX mejorada**: 
  - Toda la caja es clickeable
  - Cursor cambia a pointer cuando se puede avanzar
  - Indicador "Toca para continuar" solo en primeros 3 diálogos
  - Después solo borde amarillo (más limpio)
  - Indicador con animación de pulso
  - Indicador movido a la izquierda (no tapado por el personaje)
- ✅ **Función helper**: Conversión automática de avatar a DialogueBody
- ✅ **Z-index correcto**: Vignette → Caja → Personaje
- ✅ Agregado campo `spritePath` para interactables

## Pendientes para próxima sesión

### Sistema de cámara en HouseScene
- [ ] Implementar método `_buildRoomWithCamera()` en HouseScene
- [ ] Aplicar el mismo sistema de cámara dual

### Imágenes temporales de personajes
- [x] Crear placeholders visuales para Dan, Mel, Marcus
- [x] Integrar con el sistema de diálogos
- [ ] Agregar imagen para Emma (cuando aparezca en diálogos)

### Mejorar mapa exterior
- [ ] Agregar más interactables al mapa exterior amplio
- [ ] Agregar elementos visuales (árboles, rocas, etc.)

### Fase de mini-combate (Exterior del búnker)
- [ ] Implementar cambio de modo: exploración → combate
- [ ] Spawn de Resonante menor
- [ ] Spawn de objeto obsesivo (destructible)
- [ ] Mecánica: Resonante invulnerable hasta destruir objeto
- [ ] Controles de combate: WASD + Espacio (disparar) + E (Mel)
- [ ] Mel como companion con habilidad de curación
- [ ] Transición a MyApp después de derrotar al Resonante

### Testing y pulido
- [ ] Probar flujo completo: Casa → Búnker → Combate
- [ ] Ajustar diálogos según sea necesario
- [ ] Verificar que todos los interactables funcionen
- [ ] Pulir transiciones y animaciones

### Futuro: Mapas Tiled
- [ ] Crear mapas `.tmx` para cada habitación
- [ ] Integrar con `MapLoader`
- [ ] Reemplazar placeholders visuales con assets reales
