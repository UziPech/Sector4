# Kohaa Test Level - Guía Rápida

## Cómo Testear el Nivel

### 1. Modificar el Main para Cargar el Nivel

En `lib/main.dart` o donde se inicialice el juego, añade el nivel de test de Kohaa:

```dart
import 'package:Sector4/game/levels/kohaa_test_level.dart';

// En el método onLoad del juego:
final testLevel = KohaaTestLevel();
world.add(testLevel);
```

### 2. Secuencia del Test

1. **Inicio**: Dan aparece en el centro de la arena
2. **Diálogo Intro**: Se muestra la conversación con Kohaa
3. **Irracionales**: Hay 3 enemigos débiles para practicar
4. **Boss Spawn**: Kohaa aparece después del diálogo
5. **Combate**: Derrota a Kohaa con las armas de Dan
6. **Diálogo Derrota**: Mel explica la resurrección de Kijin
7. **Tumba Roja**: Aparece la tumba especial de Kohaa
8. **Resurrección** (con Mel):
   - Cambia a Mel
   - Acércate a la tumba roja
   - Presiona `E` (requiere 2 slots libres)
   - Observa el efecto rosa/púrpura
   - Kohaa se convierte en aliada permanente

### 3. Cosas a Probar

- ✅ Diálogos intro y derrota
- ✅ Mecánicas del boss (dash, enfermeros al 50% HP)
- ✅ Tumba roja con indicador "(2 slots)"
- ✅ Resurrección consume 2 slots
- ✅ Aliada Kijin no expira por tiempo
- ✅ IA de separación (no se apila con otros aliados)
- ✅ Al morir, libera 2 slots automáticamente

### 4. Comandos de Debug

Si necesitas debugging:
```dart
// Ver slots disponibles
debugPrint('Slots: ${resurrectionManager.resurrectionsRemaining}');

// Verificar estado de Kohaa
debugPrint('Kohaa HP: ${kohaa.health}/${kohaa.healthPercent}');
```

### 5. Notas

- **Visual**: Los sprites son círculos actualmente (placeholders)
- **Imágenes**: Los diálogos usan las imágenes AI generadas
- **Arena**: Simple, solo paredes para testing enfocado
- **Cámara**: Asegúrate de que la cámara siga al jugador

## Assets Generados

- `assets/avatars/dialogue_body/kohaa_dialogue_complete.png`
- `assets/avatars/dialogue_icons/kohaa_avatar.png`
