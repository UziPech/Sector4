# Fix: Sistema de Movimiento en HouseScene

## Problema Detectado
El jugador no se podía mover en la escena de la casa (Capítulo 1).

## Causa Raíz
1. **FocusNode no persistente**: Se creaba un nuevo `FocusNode` en cada rebuild
2. **Sin loop de actualización**: El movimiento solo se actualizaba cuando había eventos de teclado
3. **Focus no capturado**: El widget no capturaba correctamente el foco del teclado

## Solución Implementada

### 1. FocusNode Persistente
```dart
// Antes (INCORRECTO)
return KeyboardListener(
  focusNode: FocusNode()..requestFocus(),  // Se crea cada vez
  ...
)

// Después (CORRECTO)
late FocusNode _focusNode;

@override
void initState() {
  super.initState();
  _focusNode = FocusNode();  // Se crea una sola vez
  ...
}

@override
void dispose() {
  _focusNode.dispose();  // Se limpia correctamente
  super.dispose();
}
```

### 2. Loop de Movimiento con Timer
```dart
Timer? _movementTimer;

void _startMovementLoop() {
  // Actualizar movimiento 60 veces por segundo
  _movementTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
    if (mounted) {
      _updatePlayerPosition();
    }
  });
}
```

### 3. Widget Focus Correcto
```dart
return Scaffold(
  body: Focus(
    focusNode: _focusNode,
    autofocus: true,
    onKeyEvent: (node, event) {
      _handleKeyEvent(event);
      return KeyEventResult.handled;
    },
    child: Stack(...),
  ),
);
```

## Cambios en el Código

### Archivo: `lib/narrative/screens/house_scene.dart`

**Imports añadidos:**
```dart
import 'dart:async';  // Para Timer
```

**Variables de estado añadidas:**
```dart
late FocusNode _focusNode;
Timer? _movementTimer;
```

**Métodos añadidos:**
```dart
void _startMovementLoop() {
  _movementTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
    if (mounted) {
      _updatePlayerPosition();
    }
  });
}

@override
void dispose() {
  _focusNode.dispose();
  _movementTimer?.cancel();
  super.dispose();
}
```

**Modificaciones en `_updatePlayerPosition()`:**
```dart
void _updatePlayerPosition() {
  if (_isDialogueActive || DialogueOverlay.isActive) return;
  if (_pressedKeys.isEmpty) return;  // Optimización: no actualizar si no hay teclas presionadas
  
  setState(() {
    // ... lógica de movimiento
  });
}
```

**Modificaciones en `build()`:**
```dart
// Cambio de KeyboardListener a Focus dentro de Scaffold
return Scaffold(
  body: Focus(
    focusNode: _focusNode,
    autofocus: true,
    onKeyEvent: (node, event) {
      _handleKeyEvent(event);
      return KeyEventResult.handled;
    },
    child: Stack(...),
  ),
);
```

## Cómo Probar

1. **Ejecutar el juego:**
   ```bash
   flutter run -d chrome
   # o
   flutter run -d windows
   ```

2. **Navegar al Capítulo 1:**
   - Menú Principal → Nuevo Juego

3. **Probar movimiento:**
   - Presiona **W/A/S/D** o **Flechas** para mover a Dan
   - El personaje (círculo azul) debe moverse suavemente
   - Acércate a objetos (se resaltan en amarillo)
   - Presiona **E** para interactuar

## Comportamiento Esperado

- ✅ Dan se mueve suavemente con WASD o flechas
- ✅ El movimiento es continuo mientras mantienes presionada una tecla
- ✅ Los objetos se resaltan cuando estás cerca
- ✅ El indicador "E" aparece cuando puedes interactuar
- ✅ El movimiento se detiene durante los diálogos

## Notas Técnicas

### Frecuencia de Actualización
- **16ms** = ~60 FPS
- Ajustable cambiando `Duration(milliseconds: 16)`

### Velocidad de Movimiento
- Actual: `5.0` píxeles por frame
- Ajustable en `_playerSpeed`

### Límites del Mundo
- X: 0 - 750
- Y: 0 - 550
- Ajustable en `_updatePlayerPosition()`

## Mejoras Futuras

### 1. Movimiento Diagonal Normalizado
Actualmente el movimiento diagonal es más rápido. Solución:
```dart
if (dx != 0 && dy != 0) {
  // Normalizar para movimiento diagonal
  final length = sqrt(dx * dx + dy * dy);
  dx = dx / length;
  dy = dy / length;
}
```

### 2. Aceleración/Desaceleración
Para movimiento más suave:
```dart
Vector2 _velocity = Vector2.zero();
final acceleration = 0.5;
final friction = 0.9;

// En _updatePlayerPosition()
_velocity.x += dx * acceleration;
_velocity.y += dy * acceleration;
_velocity *= friction;
position += _velocity;
```

### 3. Colisiones con Paredes
Detectar colisiones con los límites de las habitaciones:
```dart
bool _isWall(double x, double y) {
  // Verificar si la posición está dentro de una pared
  return false;
}

// En _updatePlayerPosition()
if (!_isWall(newX, newY)) {
  _playerPosition = Vector2(newX, newY);
}
```

### 4. Animación de Sprites
Cambiar el círculo azul por sprites animados:
```dart
// Agregar estados de animación
enum PlayerState { idle, walkUp, walkDown, walkLeft, walkRight }
PlayerState _currentState = PlayerState.idle;

// Actualizar estado según dirección
if (dy < 0) _currentState = PlayerState.walkUp;
else if (dy > 0) _currentState = PlayerState.walkDown;
// etc.
```

## Problemas Conocidos

### En Web
- El foco puede perderse si haces clic fuera del canvas
- **Solución temporal**: Haz clic en el juego para recuperar el foco

### En Móvil
- No hay controles táctiles implementados aún
- **Solución futura**: Agregar joystick virtual (similar al juego de combate)

## Testing Checklist

- [x] Movimiento con WASD funciona
- [x] Movimiento con flechas funciona
- [x] Movimiento se detiene durante diálogos
- [x] Interacción con E funciona
- [x] Los objetos se resaltan correctamente
- [ ] Movimiento en móvil (pendiente)
- [ ] Colisiones con paredes (pendiente)
- [ ] Animación de sprites (pendiente)

## Referencias

- [Flutter Focus Documentation](https://api.flutter.dev/flutter/widgets/Focus-class.html)
- [Dart Timer Documentation](https://api.dart.dev/stable/dart-async/Timer-class.html)
- [Flutter Game Development](https://docs.flutter.dev/development/ui/advanced/gestures)
