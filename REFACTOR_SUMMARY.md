# Resumen de Refactorización - Expediente Kōrin

## Fecha: 15 de Noviembre 2025

### Objetivo
Limpiar y reorganizar el proyecto para una arquitectura modular y escalable, preparando la base para la demo.

---

## Archivos Eliminados ❌

### Prototipos obsoletos:
- `lib/korin_game.dart` - Prototipo roto de Tiled
- `lib/korin_game_example.dart` - Versión con controles (standalone)
- `lib/korin_game_widget.dart` - Widget wrapper obsoleto
- `lib/test_korin_game.dart` - Test del prototipo
- `lib/main_backup.dart` - Backup antiguo
- `lib/main_with_tiled.dart` - Versión experimental

### Assets obsoletos:
- `assets/tiles/kenney_roguelike-rpg-pack/` - Tilesets no utilizados
- Mapa `.tmx` antiguo mal implementado

---

## Nueva Estructura Creada ✅

```
lib/
├─ main.dart (LIMPIO - solo app + menú + overlay)
├─ narrative/ (INTACTO - sistema narrativo completo)
│   ├─ screens/
│   ├─ components/
│   ├─ models/
│   └─ services/
└─ game/ (NUEVO - motor modular)
    ├─ expediente_game.dart (motor principal)
    ├─ components/
    │   ├─ player.dart (Dan con movimiento + disparo)
    │   ├─ mel.dart (companion con habilidades)
    │   └─ mutados/ (preparado para enemigos)
    ├─ systems/
    │   └─ map_loader.dart (carga mapas por capítulo)
    └─ ui/
        └─ game_hud.dart (HUD con vida + cooldowns)
```

```
assets/
└─ tiles/
    ├─ capitulo_1/ (casa de Dan)
    └─ capitulo_2/ (búnker)
```

---

## Características del Nuevo Motor

### ExpedienteKorinGame (lib/game/expediente_game.dart)
- ✅ Carga modular de mapas por capítulo
- ✅ Sistema de cámara que sigue al jugador
- ✅ Gestión de colisiones con Flame
- ✅ Soporte para transiciones entre capítulos
- ✅ Game Over con overlay

### PlayerCharacter (lib/game/components/player.dart)
- ✅ Movimiento WASD + flechas
- ✅ Sistema de disparo con cooldown
- ✅ Vida + invencibilidad temporal
- ✅ Colisiones con paredes del mapa
- ✅ Efecto de parpadeo al recibir daño

### MelCharacter (lib/game/components/mel.dart)
- ✅ Sigue al jugador automáticamente
- ✅ Habilidad "Soporte Vital" (tecla E)
  - Curación completa
  - Cooldown de 15 segundos
  - Indicador visual de recarga
- 🔜 Invocación de esencias (pendiente)
- 🔜 Mimetismo de habilidades (pendiente)

### MapLoader (lib/game/systems/map_loader.dart)
- ✅ Registro de mapas por capítulo
- ✅ Carga de colisiones desde Tiled
- ✅ Posiciones de spawn configurables
- 🔜 Carga de entidades (enemigos, triggers)

### GameHUD (lib/game/ui/game_hud.dart)
- ✅ Barra de vida de Dan
- ✅ Estado de Mel (disponible/recargando)
- ✅ Barra de progreso de cooldown
- ✅ Estilo visual coherente (monospace, negro/blanco)
- ✅ Indicador dinámico de controles (cambia según contexto)

### Sistema de Skip de Diálogo (lib/narrative/components/dialogue_system.dart)
- ✅ Método `skipDialogue()` salta toda la secuencia
- ✅ Atajo ESC para saltar diálogos durante gameplay
- ✅ HUD muestra "ESC: Saltar diálogo" cuando está activo
- ✅ Ejecuta `onComplete` igual que si terminara naturalmente
- ✅ No rompe la lógica del juego

### Sistema de Habitaciones (lib/narrative/systems/room_manager.dart)
- ✅ 4 habitaciones: Sala, Pasillo, Emma, Estudio
- ✅ Transiciones con pantalla negra (fade 400ms)
- ✅ Puertas con detección automática
- ✅ Cooldown de 0.5s para evitar transiciones múltiples
- ✅ Límites por Container (no se sale de la habitación)
- ✅ HUD muestra nombre de habitación actual

---

## Flujo del Juego Actual

1. **MenuScreen** → Menú principal (narrativa intacta)
2. **HouseScene** (Capítulo 1) → Exploración + diálogos
3. **BunkerScene** (Capítulo 2) → Encuentro con Mel
4. **ExpedienteKorinGame** → Combate con mapas de Tiled
5. **GameOverOverlay** → Reintentar o volver al menú

---

## Próximos Pasos Recomendados

### Corto plazo (Demo):
1. **Crear mapas en Tiled:**
   - `assets/tiles/capitulo_1/casa_dan.tmx` (exploración narrativa)
   - `assets/tiles/capitulo_2/bunker.tmx` (primer combate)

2. **Implementar enemigos básicos:**
   - `lib/game/components/mutados/resonante.dart` (Sector 3)
   - `lib/game/components/mutados/kijin.dart` (Sector 4)

3. **Sistema de disparo:**
   - `lib/game/components/bullet.dart` (proyectiles de Dan)
   - Colisiones bala-enemigo

4. **Triggers de diálogo in-game:**
   - `lib/game/systems/dialogue_trigger.dart`
   - Conectar con `DialogueOverlay` existente

### Mediano plazo (Post-demo):
- Sistema de oleadas de enemigos
- Habilidades avanzadas de Mel (esencias, mimetismo)
- Boss fights (Singularidades)
- Sistema de progresión/puntuación

---

## Compatibilidad

- ✅ Flutter Web
- ✅ Windows Desktop
- ✅ Controles: WASD + Espacio (disparar) + E (curar)
- ✅ Sistema narrativo intacto
- ✅ Flame 1.33.0 + flame_tiled 1.20.0

---

## Notas Técnicas

### Colisiones:
- Usa `PolygonHitbox` y `RectangleHitbox` de Flame
- Capa "collisions" en Tiled para paredes
- Pushback automático en `PlayerCharacter`

### Mapas:
- Tile size: 16x16 px (configurable en `MapLoader`)
- Formato: `.tmx` (Tiled Map Editor)
- Capas requeridas: `collisions`, `entities` (opcional)

### Arquitectura:
- Separación clara: narrativa (Flutter widgets) vs combate (Flame components)
- Sistema modular permite agregar capítulos sin romper lo existente
- Cada componente es independiente y testeable

---

## Comandos Útiles

```bash
# Limpiar y reconstruir
flutter clean
flutter pub get

# Ejecutar en web
flutter run -d chrome

# Ejecutar en Windows
flutter run -d windows
```

---

## Créditos
- Motor: Flame (https://flame-engine.org/)
- Mapas: Tiled (https://www.mapeditor.org/)
- Narrativa: Sistema custom con DialogueSystem
