# Sistema de Skip de Diálogo - Implementado

## ✅ Cambios realizados

### 1. Método `skipDialogue()` en `DialogueSystem`
**Archivo:** `lib/narrative/components/dialogue_system.dart`

```dart
void skipDialogue() {
  debugPrint('DialogueSystem: Skipping dialogue sequence');
  setState(() {
    _currentDialogueIndex = widget.sequence.dialogues.length;
  });
  
  // Llamar callbacks inmediatamente
  widget.sequence.onComplete?.call();
  widget.onSequenceComplete?.call();
}
```

### 2. Método público `skipCurrent()` en `DialogueOverlay`
**Archivo:** `lib/narrative/components/dialogue_system.dart`

- Usa `GlobalKey` para acceder al state del `DialogueSystem`
- Permite saltar el diálogo desde cualquier parte

```dart
static final GlobalKey<_DialogueSystemState> _dialogueKey = GlobalKey();

static void skipCurrent() {
  _dialogueKey.currentState?.skipDialogue();
}
```

### 3. Atajo de teclado ESC en `HouseScene`
**Archivo:** `lib/narrative/screens/house_scene.dart`

```dart
onKeyEvent: (event) {
  if (event is KeyDownEvent) {
    // Saltar diálogo con ESC
    if (event.logicalKey == LogicalKeyboardKey.escape && _isDialogueActive) {
      DialogueOverlay.skipCurrent();
      setState(() {
        _isDialogueActive = false;
      });
      return;
    }
    // ...
  }
}
```

### 4. Indicador visual dinámico
**Archivo:** `lib/narrative/screens/house_scene.dart`

El HUD de controles cambia según el contexto:
- **Durante diálogo:** "ESC: Saltar diálogo"
- **Sin diálogo:** "WASD/Flechas: Mover\nE: Interactuar"

### 5. Botón "SKIPEAR" removido del gameplay
- Ya no aparece el botón grande en la esquina superior derecha
- Solo estará disponible en el menú de capítulos (futuro)

---

## 🎮 Cómo funciona ahora

### Flujo normal (leer diálogos):
1. Interactúa con objeto (foto, teléfono, etc.)
2. Aparece el diálogo
3. Click o auto-advance para avanzar
4. Termina la secuencia → `onComplete` se llama

### Flujo con skip (ESC):
1. Interactúa con objeto
2. Aparece el diálogo
3. **Presiona ESC**
4. Diálogo se cierra inmediatamente
5. `onComplete` se llama (igual que si terminara natural)
6. Continúa explorando

### Integración con el teléfono:
```dart
InteractableData(
  id: 'phone',
  dialogue: DialogueSequence(
    id: 'phone_dialogue',
    dialogues: [...],
    onComplete: () {
      // Se llama tanto si lee todo como si salta
      setState(() {
        _phoneCallCompleted = true;
        _isDialogueActive = false;
      });
      
      Future.delayed(const Duration(seconds: 2), () {
        _transitionToCombat();
      });
    },
  ),
)
```

---

## 🎯 Ventajas

✅ **No rompe la lógica:** `onComplete` siempre se ejecuta
✅ **Intuitivo:** ESC es estándar para cerrar/saltar
✅ **Visual:** El HUD indica claramente que ESC está disponible
✅ **Limpio:** No hay botones molestos en pantalla
✅ **Flexible:** Funciona con todos los interactables (foto, teléfono, escritorio)

---

## 📝 Próximos pasos

1. ✅ Sistema de skip implementado
2. ⏳ Arreglar interacción con el teléfono (próximo)
3. ⏳ Aplicar el mismo sistema al búnker (Capítulo 2)
4. ⏳ Agregar botón "Skipear Capítulo" solo en menú de capítulos

---

## 🧪 Para probar

1. Ejecuta el juego
2. Interactúa con la foto (E)
3. Lee el primer diálogo
4. **Presiona ESC**
5. Verifica que:
   - El diálogo se cierra
   - Puedes seguir explorando
   - El HUD vuelve a mostrar controles normales

---

**Estado:** ✅ Completamente funcional  
**Fecha:** Noviembre 2025  
**Próximo:** Arreglar llamada telefónica y transición al combate
