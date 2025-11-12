# Sistema Narrativo - Expediente Kōrin

## Estructura

```
narrative/
├── models/              # Modelos de datos
│   ├── dialogue_data.dart       # Estructura de diálogos
│   └── interactable_data.dart   # Objetos interactuables
├── components/          # Componentes reutilizables
│   ├── dialogue_box.dart        # Caja de diálogo estilo RPG
│   ├── dialogue_system.dart     # Gestor de secuencias
│   └── interactable_object.dart # Objetos con los que interactuar
└── screens/             # Pantallas/escenas
    ├── menu_screen.dart         # Menú principal
    ├── house_scene.dart         # Capítulo 1: Casa de Dan
    └── [futuros capítulos]
```

## Cómo agregar un nuevo capítulo

### 1. Crear nueva escena
```dart
// lib/narrative/screens/chapter2_scene.dart
import 'package:flutter/material.dart';
import '../models/dialogue_data.dart';
import '../components/dialogue_system.dart';

class Chapter2Scene extends StatefulWidget {
  const Chapter2Scene({Key? key}) : super(key: key);

  @override
  State<Chapter2Scene> createState() => _Chapter2SceneState();
}

class _Chapter2SceneState extends State<Chapter2Scene> {
  // Tu lógica aquí
}
```

### 2. Crear diálogos
```dart
final myDialogue = DialogueSequence(
  id: 'unique_id',
  dialogues: [
    DialogueData(
      speakerName: 'Dan',
      text: 'Texto del diálogo...',
      avatarPath: 'assets/avatars/dan.png',
      type: DialogueType.normal,
    ),
    // Más diálogos...
  ],
  onComplete: () {
    // Acción al terminar la secuencia
  },
);
```

### 3. Crear objetos interactuables
```dart
InteractableData(
  id: 'unique_id',
  name: 'Nombre del objeto',
  position: Vector2(x, y),
  size: Vector2(width, height),
  type: InteractableType.generic,
  dialogue: myDialogue,
  isOneTime: true, // Solo se puede interactuar una vez
)
```

## Tipos de diálogo

- `DialogueType.normal` - Diálogo estándar con avatar
- `DialogueType.internal` - Monólogo interno (sin avatar, cursiva)
- `DialogueType.phone` - Llamada telefónica
- `DialogueType.system` - Mensaje del sistema/radio
- `DialogueType.thought` - Pensamiento rápido

## Tipos de objetos interactuables

- `InteractableType.generic` - Objeto genérico
- `InteractableType.phone` - Teléfono (trigger especial)
- `InteractableType.photo` - Foto (memoria)
- `InteractableType.door` - Puerta (transición)
- `InteractableType.furniture` - Mueble (ambiente)
- `InteractableType.document` - Documento (lore)
- `InteractableType.npc` - Personaje (futuro)

## Transición a combate

Para transicionar del modo narrativo al modo combate:

```dart
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (context) => const MyApp(), // Juego de combate
  ),
);
```

## Assets

### Avatares
Coloca los avatares en: `assets/avatars/`
- `dan.png` - Avatar de Dan
- `marcus.png` - Avatar de Marcus
- `mel.png` - Avatar de Mel
- etc.

Los avatares se cargan automáticamente. Si no existe la imagen, se muestra un icono placeholder.

## Escalabilidad

### Para agregar nuevos capítulos:
1. Crear nueva escena en `lib/narrative/screens/`
2. Definir diálogos y objetos interactuables
3. Agregar transición desde el capítulo anterior

### Para agregar nuevas mecánicas narrativas:
1. Extender modelos en `lib/narrative/models/`
2. Crear nuevos componentes en `lib/narrative/components/`
3. Reutilizar en múltiples escenas

### Para agregar sistema de guardado:
1. Crear `lib/narrative/services/save_system.dart`
2. Guardar estado de capítulos completados
3. Guardar estado de objetos interactuados
4. Habilitar botón "Continuar" en menú

## Ejemplo completo

Ver `house_scene.dart` para un ejemplo completo de:
- Movimiento del jugador
- Múltiples objetos interactuables
- Secuencias de diálogo
- Transición a combate
- HUD contextual
