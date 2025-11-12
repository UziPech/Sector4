# Guía de Implementación - Expediente Kōrin

## ✅ Estado Actual del Proyecto

### Implementado
- ✅ **Sistema de diálogo completo** con efecto typewriter
- ✅ **Menú principal** con opciones (Nuevo Juego, Continuar, Opciones, Salir)
- ✅ **Capítulo 1: Casa de Dan** (escena explorable)
  - Movimiento libre del jugador
  - 4 objetos interactuables con diálogos
  - Monólogo interno de Dan
  - Llamada de Marcus (trigger del teléfono)
  - Transición automática al juego de combate
- ✅ **Sistema de combate** (tu juego original)
  - Top-down shooter
  - Sistema de Mel (curación)
  - Oleadas de enemigos
  - Mundo infinito
- ✅ **Arquitectura escalable** para futuros capítulos

### Estructura de Archivos Creada

```
lib/
├── narrative/                    # NUEVO - Sistema narrativo
│   ├── models/
│   │   ├── dialogue_data.dart           # Modelos de diálogo
│   │   └── interactable_data.dart       # Modelos de objetos
│   ├── components/
│   │   ├── dialogue_box.dart            # Caja de diálogo RPG
│   │   ├── dialogue_system.dart         # Gestor de secuencias
│   │   └── interactable_object.dart     # Objetos interactuables
│   ├── screens/
│   │   ├── menu_screen.dart             # Menú principal
│   │   └── house_scene.dart             # Capítulo 1
│   └── README.md                        # Documentación del sistema
├── combat/                       # NUEVO - Wrapper del combate
│   └── combat_game.dart
├── components/                   # ORIGINAL - Mantener intacto
│   ├── bullet.dart
│   ├── enemy_character.dart
│   └── living_entity.dart
└── main.dart                     # MODIFICADO - Ahora inicia en menú
```

## 🚀 Cómo Ejecutar

### 1. Instalar dependencias
```bash
flutter pub get
```

### 2. Ejecutar en modo debug
```bash
# Desktop (Windows)
flutter run -d windows

# Web
flutter run -d chrome

# Móvil (Android)
flutter run -d android
```

### 3. Flujo del juego
1. **Menú Principal** → Clic en "NUEVO JUEGO"
2. **Capítulo 1: Casa de Dan**
   - Usa WASD o flechas para moverte
   - Acércate a objetos y presiona E para interactuar
   - Lee los diálogos (clic o tap para avanzar)
   - Encuentra el teléfono (verde) y interactúa con él
   - Escucha la llamada de Marcus
3. **Transición automática** al juego de combate
4. **Misión 1: Universidad**
   - Combate con mutados
   - Usa Mel para curarte (E)
   - Sobrevive oleadas

## 📝 Próximos Pasos de Desarrollo

### Paso 1: Agregar Avatares (URGENTE)
Los diálogos están configurados para usar avatares, pero necesitas agregar las imágenes:

**Ubicación:** `assets/avatars/`

**Archivos necesarios:**
- `dan.png` - Avatar de Dan (64x64 px recomendado)
- `marcus.png` - Avatar de Marcus (64x64 px recomendado)

**Formato recomendado:**
- PNG con fondo transparente
- Estilo pixel art o ilustración
- Tamaño: 64x64 o 128x128 píxeles

**Placeholder actual:** Si no existe la imagen, se muestra un icono de persona.

### Paso 2: Crear Capítulo 2 (Encuentro con Mel)

Ver `GAME_DESIGN.md` para el diseño completo del Capítulo 2.

**Archivo a crear:** `lib/narrative/screens/chapter2_scene.dart`

**Estructura base:**
```dart
import 'package:flutter/material.dart';
import '../models/dialogue_data.dart';
import '../components/dialogue_system.dart';

class Chapter2Scene extends StatefulWidget {
  const Chapter2Scene({Key? key}) : super(key: key);

  @override
  State<Chapter2Scene> createState() => _Chapter2SceneState();
}

class _Chapter2SceneState extends State<Chapter2Scene> {
  // Implementar escena del campamento del Sector 4
  // Ver house_scene.dart como referencia
}
```

### Paso 3: Implementar Mecánica de Posesión de Mel

**Archivo a modificar:** `lib/main.dart` (clase `ExpedienteKorinGame`)

**Lógica propuesta:**
```dart
// Cuando Mel "muere"
void onMelDefeat() {
  if (nearbyEnemies.isNotEmpty) {
    final target = nearbyEnemies.first;
    possessEnemy(target);
  }
}

void possessEnemy(EnemyCharacter enemy) {
  enemy.isPossessed = true;
  enemy.attacksEnemies = true; // Cambia de bando
  
  // Después de 10 segundos
  Future.delayed(Duration(seconds: 10), () {
    enemy.removeFromParent();
    respawnMel();
  });
}
```

### Paso 4: Implementar Sistema de Mimetismo

**Archivo a crear:** `lib/components/mimicry_system.dart`

**Estructura:**
```dart
class MimicryAbility {
  final String id;
  final String name;
  final Duration duration;
  final int charges;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;
}

class MimicrySystem {
  MimicryAbility? currentAbility;
  
  void grantAbility(MimicryAbility ability) {
    currentAbility = ability;
    ability.onActivate();
    
    // Temporizador o cargas
  }
}
```

### Paso 5: Crear Primer Jefe (Kijin de Fuego)

**Archivo a crear:** `lib/components/bosses/kijin_boss.dart`

**Extender de:** `EnemyCharacter`

**Fases:**
- Fase 1: 100% - 50% HP
- Fase 2: 50% - 0% HP

Ver `GAME_DESIGN.md` para patrones de ataque detallados.

## 🎨 Guía de Assets

### Avatares de Diálogo
- **Ubicación:** `assets/avatars/`
- **Formato:** PNG, 64x64 o 128x128 px
- **Estilo:** Pixel art o ilustración
- **Necesarios:**
  - `dan.png` - Protagonista (hombre de 40s, cansado, determinado)
  - `marcus.png` - Compañero (hombre de 50s, veterano, serio)
  - `mel.png` - Aliada (joven, misteriosa, ojos brillantes)

### Sprites de Personajes (Futuro)
- **Ubicación:** `assets/sprites/`
- **Formato:** PNG con transparencia
- **Tamaño:** 32x32 o 64x64 px
- **Necesarios:**
  - `dan_idle.png` - Dan parado
  - `dan_walk.png` - Dan caminando (4 frames)
  - `mel_idle.png` - Mel parada
  - `mel_walk.png` - Mel caminando (4 frames)

### Enemigos (Futuro)
- **Ubicación:** `assets/enemies/`
- **Formato:** PNG con transparencia
- **Necesarios:**
  - `mutado_basic.png` - Mutado de bajo nivel
  - `kijin_boss.png` - Jefe Kijin
  - `yuki_onna.png` - Mini-jefe Yuki-Onna

### Audio (Futuro)
- **Ubicación:** `assets/audio/`
- **Formato:** OGG o MP3
- **Necesarios:**
  - `music_menu.ogg` - Música del menú
  - `music_house.ogg` - Música de la casa
  - `music_combat.ogg` - Música de combate
  - `sfx_dialogue.ogg` - Sonido de texto
  - `sfx_shoot.ogg` - Sonido de disparo
  - `sfx_heal.ogg` - Sonido de curación

## 🔧 Configuración de Desarrollo

### Recomendaciones de IDE
- **VS Code** con extensiones:
  - Flutter
  - Dart
  - Flutter Widget Snippets
- **Android Studio** con plugin de Flutter

### Comandos Útiles

```bash
# Análisis de código
flutter analyze

# Formatear código
flutter format .

# Ejecutar tests
flutter test

# Build para producción
flutter build windows
flutter build web
flutter build apk
```

## 📚 Documentación de Referencia

### Archivos de Documentación
- `README.md` - Descripción general del proyecto
- `GAME_DESIGN.md` - Diseño completo del juego (historia, mecánicas, roadmap)
- `lib/narrative/README.md` - Documentación del sistema narrativo
- `IMPLEMENTATION_GUIDE.md` - Esta guía

### Recursos Externos
- [Flame Engine Docs](https://docs.flame-engine.org/)
- [Flutter Docs](https://docs.flutter.dev/)
- [Folklore Japonés](https://yokai.com/) - Para investigación de enemigos

## 🐛 Problemas Conocidos y Soluciones

### Problema: Avatares no se muestran
**Causa:** Las imágenes no existen en `assets/avatars/`
**Solución:** Agregar las imágenes o usar los placeholders (icono de persona)

### Problema: El juego no compila
**Causa:** Dependencias no instaladas
**Solución:** `flutter pub get`

### Problema: Lag en el juego de combate
**Causa:** Demasiados enemigos spawneados
**Solución:** Ajustar `EnemySpawner` en `lib/components/enemy_spawner.dart`

### Problema: Diálogos se saltan muy rápido
**Causa:** Velocidad de typewriter muy alta
**Solución:** Ajustar `typewriterSpeed` en `DialogueBox` (línea 9 de `dialogue_box.dart`)

## 🎯 Checklist de Implementación

### Capítulo 1 (Completado)
- [x] Sistema de diálogo
- [x] Menú principal
- [x] Casa de Dan explorable
- [x] Objetos interactuables
- [x] Monólogo interno
- [x] Llamada de Marcus
- [x] Transición a combate

### Capítulo 2 (Pendiente)
- [ ] Escena del campamento
- [ ] Presentación de Mel
- [ ] Diálogos Dan-Mel
- [ ] Briefing de Marcus
- [ ] Transición a Misión 2

### Sistema de Mel (Pendiente)
- [x] Curación (Soporte Vital)
- [ ] Posesión de enemigos
- [ ] Mimetismo de habilidades
- [ ] UI de habilidades activas

### Jefes (Pendiente)
- [ ] Kijin de Fuego
- [ ] Yuki-Onna
- [ ] Gashadokuro

### Sistemas Generales (Pendiente)
- [ ] Sistema de guardado
- [ ] Coleccionables (pistas)
- [ ] Progresión de personajes
- [ ] Múltiples finales

## 💡 Tips de Desarrollo

### Buenas Prácticas
1. **Mantén el código del combate intacto** - Todo lo narrativo va en `lib/narrative/`
2. **Reutiliza componentes** - `DialogueSystem` y `InteractableObject` son reutilizables
3. **Documenta nuevos capítulos** - Actualiza `GAME_DESIGN.md` con cada adición
4. **Commits frecuentes** - Guarda progreso regularmente
5. **Testea en múltiples plataformas** - Desktop, Web, Móvil

### Flujo de Trabajo Recomendado
1. Diseñar capítulo en `GAME_DESIGN.md`
2. Crear diálogos en texto plano
3. Implementar escena en `lib/narrative/screens/`
4. Agregar assets (avatares, sprites)
5. Testear flujo completo
6. Pulir y optimizar

### Debugging
- Usa `debugPrint()` para logs
- Activa el inspector de Flutter para UI
- Usa breakpoints en VS Code/Android Studio
- Revisa `flutter doctor` para problemas de setup

## 🚢 Preparación para Release

### Checklist Pre-Release
- [ ] Todos los assets finales agregados
- [ ] Audio implementado
- [ ] Sistema de guardado funcional
- [ ] Testeo completo en todas las plataformas
- [ ] Optimización de rendimiento
- [ ] Localización (si aplica)
- [ ] Política de privacidad (si aplica)

### Build de Producción

```bash
# Windows
flutter build windows --release

# Web
flutter build web --release

# Android
flutter build apk --release
flutter build appbundle --release

# iOS (requiere Mac)
flutter build ios --release
```

## 📞 Soporte y Recursos

### Si necesitas ayuda con:
- **Sistema de diálogo:** Ver `lib/narrative/components/dialogue_box.dart`
- **Objetos interactuables:** Ver `lib/narrative/components/interactable_object.dart`
- **Crear nuevos capítulos:** Ver `lib/narrative/screens/house_scene.dart` como ejemplo
- **Mecánicas de combate:** Ver `lib/main.dart` (clase `ExpedienteKorinGame`)
- **Diseño general:** Ver `GAME_DESIGN.md`

### Recursos de Aprendizaje
- [Flame Engine Tutorial](https://docs.flame-engine.org/latest/tutorials/platformer/platformer.html)
- [Flutter Game Development](https://flutter.dev/games)
- [Pixel Art Tutorial](https://lospec.com/pixel-art-tutorials)

---

**¡Buena suerte con el desarrollo de Expediente Kōrin!** 🎮✨
