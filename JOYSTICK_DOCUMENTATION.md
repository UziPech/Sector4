# Documentación del Joystick Virtual - Expediente Kōrin

## Descripción General
El proyecto utiliza una implementación personalizada de un **Joystick Virtual Flotante** para el control de movimiento en dispositivos móviles. A diferencia de los componentes estándar de Flame, esta solución se implementa a nivel de Flutter (UI) utilizando `Listener` y `Stack`, lo que permite una mayor flexibilidad y consistencia visual entre las secciones narrativas y de juego.

## Características Técnicas
- **Tipo:** Flotante (aparece donde el usuario toca).
- **Activación:** Solo se activa en la mitad izquierda de la pantalla (`screenSize.width / 2`).
- **Input:** Captura eventos de puntero (`onPointerDown`, `onPointerMove`, `onPointerUp`).
- **Visuales:**
  - **Base:** Círculo semitransparente (`Colors.white.withOpacity(0.2)`).
  - **Knob (Botón):** Círculo sólido (`Colors.white.withOpacity(0.8)`) con sombra.
- **Lógica de Movimiento:**
  - Calcula el vector delta entre el origen del toque y la posición actual.
  - Normaliza el vector si excede el radio máximo (`_joystickRadius = 60.0`).
  - Envía un `Vector2` normalizado (0.0 a 1.0) al sistema de juego.

## Implementación en el Código

### 1. Lógica de UI (Captura de Input)
La lógica de captura y renderizado se encuentra duplicada (por diseño de consistencia) en los contenedores de cada escena:

*   **Narrativa (Capítulo 1):** `lib/narrative/screens/house_scene.dart`
*   **Narrativa (Capítulo 2):** `lib/narrative/screens/bunker_scene.dart`
*   **Gameplay (Combate):** `lib/main.dart` (Clase `_MyAppState`)

### 2. Conexión con el Motor (Flame)
En la fase de combate, el joystick se comunica con el motor del juego a través de:

*   **`lib/game/expediente_game.dart`**:
    *   Variable `Vector2 joystickInput`: Almacena el vector actual.
    *   Método `updateJoystickInput(Vector2 input)`: Recibe actualizaciones desde la UI.

### 3. Consumo del Input (Jugador)
El personaje procesa el input en su bucle de actualización:

*   **`lib/game/components/player.dart`**:
    *   Método `_updateMovement`: Combina el input del teclado (WASD/Flechas) con el `game.joystickInput`.
    *   Prioridad: Si se usa el teclado, se suma al joystick; si no, el joystick tiene control total.

## Cobertura Actual (Dónde funciona)

| Capítulo | Sección | Estado | Archivo Principal |
| :--- | :--- | :--- | :--- |
| **Capítulo 1** | **Casa (Narrativa)** | ✅ Implementado | `house_scene.dart` |
| **Capítulo 2** | **Búnker (Narrativa)** | ✅ Implementado | `bunker_scene.dart` |
| **Capítulo 2** | **Final (Combate/Boss)** | ✅ Implementado | `main.dart` (wrapper) |

### Detalles de Cobertura
- **Narrativa:** El joystick permite mover al personaje por las habitaciones para interactuar con objetos (puertas, notas).
- **Combate:** El joystick controla el movimiento del personaje (Dan/Mel) mientras que las acciones (atacar, dash) se realizan mediante botones en pantalla (o teclado si está disponible). *Nota: Actualmente el combate requiere botones táctiles adicionales para atacar/dash si no se usa teclado, pero el movimiento ya es 100% funcional con el joystick.*
