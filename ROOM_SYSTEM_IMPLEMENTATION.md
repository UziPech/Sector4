# Sistema de Habitaciones - Implementación Completa

## ✅ Lo que se implementó

### 1. Sistema de Habitaciones (`RoomManager`)
**Archivo:** `lib/narrative/systems/room_manager.dart`

- Gestor centralizado de todas las habitaciones de la casa de Dan
- Cada habitación tiene:
  - ID único
  - Nombre descriptivo
  - Color de fondo
  - Tamaño (700×500 px por defecto)
  - Lista de interactables
  - Lista de puertas
  - Posición de spawn del jugador

**Habitaciones definidas:**
1. **Sala de Estar** (`living_room`) - Habitación inicial
   - Interactable: Foto de familia (diálogo sobre Sarah)
   - Puerta: Hacia el pasillo

2. **Pasillo** (`hallway`) - Conecta todas las habitaciones
   - Sin interactables (solo transición)
   - 3 puertas: Sala, Habitación Emma, Estudio

3. **Habitación de Emma** (`emma_room`)
   - Interactable: Escritorio (diálogo sobre Emma)
   - Puerta: Hacia el pasillo

4. **Estudio** (`study`)
   - Interactable: Teléfono (llamada de Marcus → transición a combate)
   - Puerta: Hacia el pasillo

---

### 2. Modelo de Datos
**Archivos:**
- `lib/narrative/models/room_data.dart` - Estructura de habitaciones y puertas
- `lib/narrative/models/interactable_data.dart` - Actualizado con tipo `desk`

**Clases principales:**
- `RoomData`: Define una habitación completa
- `DoorData`: Define áreas de transición entre habitaciones
- `RoomType`: Enum para tipos de habitación

---

### 3. Transiciones con Pantalla Negra
**Implementado en:** `lib/narrative/screens/house_scene.dart`

**Características:**
- **Fade out/in suave**: 400ms de duración con `AnimationController`
- **Detección automática**: Cuando Dan entra en el área de una puerta
- **Bloqueo de input**: No se puede mover durante la transición
- **Reposicionamiento**: Dan aparece en el spawn point de la nueva habitación

**Flujo de transición:**
1. Dan entra en área de puerta (hitbox)
2. Fade out a negro (0.4s)
3. Cambio de habitación + reposición del jugador
4. Fade in desde negro (0.4s)
5. Control restaurado

---

### 4. Límites de Habitación (Container)
**Implementado con:**
- `Container` de tamaño fijo (700×500 px)
- Borde visual marrón (4px)
- Clamp de posición del jugador dentro de los límites

**Ventajas:**
- Dan no puede salirse de la habitación actual
- Cada cuarto tiene su propio espacio delimitado
- Visualmente claro dónde están los límites

---

## 🎮 Cómo funciona

### Flujo del jugador:
1. **Inicio**: Dan aparece en la Sala de Estar
2. **Exploración**: Puede interactuar con la foto de familia
3. **Transición**: Se acerca a la puerta amarilla → pantalla negra → aparece en el Pasillo
4. **Navegación**: Desde el pasillo puede ir a:
   - Habitación de Emma (arriba)
   - Estudio (abajo)
   - Sala de Estar (izquierda)
5. **Objetivo**: Llegar al Estudio e interactuar con el teléfono
6. **Final**: Tras la llamada → transición al combate (Capítulo 2)

---

## 🔧 Componentes técnicos

### RoomManager
```dart
RoomManager()
  - _rooms: Map<String, RoomData>
  - _currentRoomId: String
  + currentRoom: RoomData
  + changeRoom(roomId): void
```

### Transición
```dart
_transitionController: AnimationController (400ms)
_fadeAnimation: Animation<double> (0.0 → 1.0)
_isTransitioning: bool (bloquea movimiento)
```

### Detección de puertas
```dart
_checkDoorCollisions()
  → Para cada puerta en la habitación actual
  → Si Dan está en el área de la puerta
  → Activar transición a targetRoomId
```

### Límites de movimiento
```dart
newPosition.x.clamp(padding, roomWidth - padding)
newPosition.y.clamp(padding, roomHeight - padding)
```

---

## 🎨 Visuales

### Habitaciones:
- **Sala**: Marrón oscuro (#2C1810)
- **Pasillo**: Marrón muy oscuro (#1A1410)
- **Habitación Emma**: Azul grisáceo (#2C2C3E)
- **Estudio**: Azul oscuro (#1C1C28)

### Puertas:
- Color: Marrón semi-transparente
- Borde: Amarillo (2px)
- Label: Texto amarillo con nombre del destino

### Jugador:
- Círculo azul con borde blanco
- Icono de persona
- Tamaño: 40px

---

## 📝 HUD Actualizado

Muestra:
- **Capítulo**: "CAPÍTULO 1: EL LLAMADO"
- **Habitación actual**: Nombre dinámico (ej. "Sala de Estar")
- **Objetivo**: Cambia según progreso
  - Antes del teléfono: "Explorar la casa"
  - Después del teléfono: "Ir a Japón"

---

## 🚀 Ventajas del sistema

### Sin mapas Tiled (por ahora):
✅ No necesitas diseñar mapas completos en Tiled
✅ Puedes iterar rápidamente en las habitaciones
✅ Fácil de testear y mostrar

### Escalable:
✅ Agregar nueva habitación = agregar entrada en `RoomManager`
✅ Cambiar layout = modificar coordenadas en código
✅ Fácil migración a Tiled cuando esté listo

### Narrativa integrada:
✅ Cada habitación tiene sus propios interactables
✅ Diálogos contextuales por ubicación
✅ Flujo natural de exploración

---

## 🔮 Próximos pasos sugeridos

### Corto plazo:
1. **Agregar más interactables** en cada habitación (muebles, objetos ambientales)
2. **Sonidos de transición** (puerta abriéndose, pasos)
3. **Efectos visuales** en las puertas (brillo, partículas)

### Mediano plazo:
1. **Migrar a Tiled**: Crear `.tmx` para cada habitación
2. **Objetos destructibles**: Mesas, estanterías que se rompen
3. **Inventario visual**: Mostrar items recogidos

### Largo plazo:
1. **Aplicar el mismo sistema al búnker** (Capítulo 2)
2. **Transiciones más complejas** (cámara pan, zoom)
3. **Habitaciones dinámicas** (cambios según eventos)

---

## 🎯 Cómo agregar una nueva habitación

```dart
// En RoomManager._initializeRooms()
_rooms['nueva_habitacion'] = RoomData(
  id: 'nueva_habitacion',
  name: 'Nueva Habitación',
  type: RoomType.livingRoom, // o crear nuevo tipo
  backgroundColor: const Color(0xFF123456),
  playerSpawnPosition: const Vector2(350, 250),
  roomSize: const Size(700, 500),
  interactables: [
    // Agregar interactables aquí
  ],
  doors: [
    const DoorData(
      id: 'door_to_somewhere',
      position: Vector2(650, 200),
      size: Vector2(50, 100),
      targetRoomId: 'otra_habitacion',
      label: 'Salida',
    ),
  ],
);
```

---

## 📊 Estadísticas

- **Habitaciones**: 4 (Sala, Pasillo, Emma, Estudio)
- **Puertas**: 6 (bidireccionales)
- **Interactables**: 3 (Foto, Escritorio, Teléfono)
- **Diálogos**: 3 secuencias completas
- **Transiciones**: Suaves (400ms fade)
- **Tamaño habitación**: 700×500 px
- **Límites**: Container con clamp

---

## ✨ Resultado final

**Ahora tienes:**
- ✅ Sistema de habitaciones funcional
- ✅ Transiciones suaves con pantalla negra
- ✅ Límites claros por habitación
- ✅ Navegación intuitiva con puertas
- ✅ HUD dinámico que muestra ubicación
- ✅ Sin necesidad de mapas Tiled (por ahora)
- ✅ Fácil de mostrar y testear

**Puedes ejecutar el juego y:**
1. Ver el monólogo inicial de Dan
2. Explorar la sala e interactuar con la foto
3. Ir al pasillo (transición negra)
4. Visitar la habitación de Emma
5. Ir al estudio y llamar a Marcus
6. Transición automática al combate

---

**Estado:** ✅ Completamente funcional  
**Fecha:** Noviembre 2025  
**Próximo:** Aplicar el mismo sistema al búnker (Capítulo 2)
