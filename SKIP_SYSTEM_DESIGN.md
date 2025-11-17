# Sistema de Skip - Diseño Mejorado

## Problema actual
- El botón "SKIPEAR" salta **todo el capítulo** y regresa al menú
- No permite saltar **solo los diálogos** y continuar explorando
- No funciona bien después del primer diálogo

## Solución propuesta

### 1. Dos tipos de skip diferentes

#### A) Skip de Diálogo (nuevo)
**Función:** Saltar la secuencia de diálogo actual y continuar jugando
- **Tecla:** `ESC` o `Space` durante el diálogo
- **Botón:** "Saltar Diálogo" (pequeño, en la esquina del cuadro de diálogo)
- **Comportamiento:**
  - Cierra el `DialogueOverlay` inmediatamente
  - Llama al callback `onComplete` como si hubiera terminado naturalmente
  - Marca interactables como completados (ej. teléfono)
  - Permite continuar explorando

#### B) Skip de Capítulo (actual, mejorado)
**Función:** Saltar todo el capítulo y ir directo al combate/siguiente escena
- **Botón:** "SKIPEAR CAPÍTULO" (esquina superior derecha)
- **Comportamiento:**
  - Muestra confirmación
  - Marca capítulo como completado
  - Va directo a la siguiente escena (combate, no menú)

---

## Implementación técnica

### 1. Agregar método `skipDialogue()` en `DialogueSystem`

```dart
class _DialogueSystemState extends State<DialogueSystem> {
  int _currentDialogueIndex = 0;
  
  // Nuevo método para saltar
  void skipDialogue() {
    setState(() {
      _currentDialogueIndex = widget.sequence.dialogues.length;
    });
    
    // Llamar callbacks inmediatamente
    widget.sequence.onComplete?.call();
    widget.onSequenceComplete?.call();
  }
  
  // ... resto del código
}
```

### 2. Exponer método público en `DialogueOverlay`

```dart
class DialogueOverlay {
  static OverlayEntry? _currentOverlay;
  static _DialogueSystemState? _currentState;
  
  static void show(...) {
    // Guardar referencia al state
    _currentOverlay = OverlayEntry(
      builder: (context) => Material(
        child: DialogueSystem(
          key: _dialogueKey,
          // ...
        ),
      ),
    );
  }
  
  // Nuevo método público
  static void skipCurrent() {
    _currentState?.skipDialogue();
    dismiss();
  }
}
```

### 3. Botón de skip en `DialogueBox`

Agregar un pequeño botón "Saltar" en la esquina del cuadro de diálogo:

```dart
// En DialogueBox
Stack(
  children: [
    // Contenido del diálogo
    Container(...),
    
    // Botón de skip
    Positioned(
      top: 8,
      right: 8,
      child: IconButton(
        icon: Icon(Icons.skip_next, color: Colors.white70),
        onPressed: () {
          DialogueOverlay.skipCurrent();
        },
      ),
    ),
  ],
)
```

### 4. Atajo de teclado en `HouseScene`

```dart
// En HouseScene, dentro del KeyboardListener
onKeyEvent: (event) {
  if (event is KeyDownEvent) {
    // Skip diálogo con ESC
    if (event.logicalKey == LogicalKeyboardKey.escape && _isDialogueActive) {
      DialogueOverlay.skipCurrent();
      setState(() {
        _isDialogueActive = false;
      });
      return;
    }
    
    _pressedKeys.add(event.logicalKey);
  }
  // ...
}
```

### 5. Integración con el teléfono

```dart
// En el interactable del teléfono
InteractableData(
  id: 'phone',
  dialogue: DialogueSequence(
    id: 'phone_dialogue',
    dialogues: [...],
    onComplete: () {
      // Esto se llama tanto si termina natural como si se salta
      setState(() {
        _phoneCallCompleted = true;
        _isDialogueActive = false;
      });
      
      // Transición al combate después de 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        _transitionToCombat();
      });
    },
  ),
)
```

---

## Flujo de usuario

### Escenario 1: Jugador lee todo
1. Interactúa con el teléfono
2. Lee todos los diálogos (click o auto-advance)
3. Termina la secuencia → `onComplete` se llama
4. Transición al combate

### Escenario 2: Jugador salta diálogos
1. Interactúa con el teléfono
2. Lee el primer diálogo
3. Presiona `ESC` o click en "Saltar"
4. Diálogo se cierra → `onComplete` se llama
5. Transición al combate

### Escenario 3: Jugador salta todo el capítulo
1. Click en "SKIPEAR CAPÍTULO"
2. Confirma
3. Va directo al combate (sin explorar)

---

## Ventajas

✅ **Flexibilidad:** Jugador decide cuánto leer
✅ **No rompe la lógica:** `onComplete` siempre se llama
✅ **Intuitivo:** ESC es estándar para cerrar/saltar
✅ **Visual:** Botón pequeño en el diálogo es claro
✅ **Consistente:** Funciona igual para todos los interactables

---

## Próximos pasos

1. Modificar `DialogueSystem` para exponer `skipDialogue()`
2. Agregar botón de skip en `DialogueBox`
3. Conectar atajo ESC en `HouseScene`
4. Actualizar `SkipButton` para ir al combate (no al menú)
5. Testear con el teléfono y otros interactables

---

**Estado:** Diseño completo, listo para implementar
**Prioridad:** Alta (bloqueante para la demo)
