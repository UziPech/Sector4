# Sistema de Historia y Progreso

## Descripción
Sistema completo de gestión de capítulos con tarjetas visuales, progreso persistente y funcionalidad de skip.

## Componentes

### 1. SaveSystem (`services/save_system.dart`)
Servicio de guardado usando SharedPreferences para rastrear:
- Capítulos completados
- Capítulos skipeados
- Último capítulo jugado
- Estado de desbloqueo de capítulos

**Métodos principales:**
- `markChapterCompleted(int)` - Marcar capítulo como completado
- `markChapterSkipped(int)` - Marcar capítulo como skipeado
- `isChapterUnlocked(int)` - Verificar si un capítulo está desbloqueado
- `getCompletedChapters()` - Obtener lista de capítulos completados

### 2. StoryScreen (`screens/story_screen.dart`)
Pantalla de historia con tarjetas de capítulos que muestra:
- **Tarjetas de capítulos** con título, descripción y estado
- **Estados visuales:**
  - ✅ COMPLETADO (verde) - Capítulo jugado completamente
  - ⏭️ SKIPEADO (naranja) - Capítulo skipeado
  - 🔒 BLOQUEADO (gris) - Capítulo no desbloqueado
  - Desbloqueado - Listo para jugar
- **Botones de acción:**
  - JUGAR/REJUGAR - Iniciar o repetir el capítulo
  - SKIPEAR - Saltar el capítulo (desbloquea el siguiente)

### 3. SkipButton (`components/skip_button.dart`)
Botón reutilizable para skipear capítulos durante el gameplay:
- Posicionado en la esquina superior derecha
- Muestra diálogo de confirmación
- Marca el capítulo como skipeado
- Regresa al menú principal

### 4. ChapterInfo (`models/chapter_info.dart`)
Modelo de datos para definir capítulos:
```dart
ChapterInfo(
  number: 1,
  title: 'Capítulo 1: El Despertar',
  description: 'Dan despierta en su casa...',
  sceneBuilder: HouseScene.new,
)
```

## Integración en Escenas

Cada escena debe:

1. **Importar dependencias:**
```dart
import '../components/skip_button.dart';
import '../services/save_system.dart';
```

2. **Agregar botón de skip en el UI:**
```dart
const SkipButton(chapterNumber: 1),
```

3. **Registrar progreso al completar:**
```dart
void _transitionToNext() async {
  await SaveSystem.markChapterCompleted(1);
  // ... navegación
}
```

## Flujo de Usuario

1. **Menú Principal** → Botón "HISTORIA"
2. **Pantalla de Historia** → Ver todos los capítulos como tarjetas
3. **Seleccionar capítulo** → JUGAR o SKIPEAR
4. **Durante gameplay** → Botón SKIPEAR en esquina superior derecha
5. **Al completar** → Progreso guardado automáticamente

## Sistema de Desbloqueo

- Capítulo 1 siempre desbloqueado
- Capítulos siguientes se desbloquean al completar o skipear el anterior
- Los capítulos skipeados se pueden rejugar en cualquier momento

## Agregar Nuevos Capítulos

1. Crear nueva escena en `screens/`
2. Agregar a la lista de capítulos en `StoryScreen`:
```dart
ChapterInfo(
  number: 3,
  title: 'Capítulo 3: Título',
  description: 'Descripción...',
  sceneBuilder: NewScene.new,
),
```
3. Agregar `SkipButton(chapterNumber: 3)` en la escena
4. Registrar progreso al completar

## Características

- ✅ Progreso persistente entre sesiones
- ✅ Tarjetas visuales con estados claros
- ✅ Sistema de skip solicitado por usuarios
- ✅ Rejugar capítulos completados
- ✅ Desbloqueo progresivo de capítulos
- ✅ Confirmación antes de skipear
- ✅ Integración limpia con escenas existentes
