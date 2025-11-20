# Plan de Implementación: Sistema de Selección de Rol

## Resumen
Implementar un sistema de selección de rol (Dan vs Mel) que se activa después de derrotar al resonante, con mecánicas diferenciadas y un mapa exterior donde aparecen irracionales débiles.

---

## Parte 1: Análisis del sistema actual

### Sistema de diálogos existente
- **`DialogueSystem`** (`lib/narrative/components/dialogue_system.dart`):
  - Maneja secuencias de diálogo con `DialogueSequence` y `DialogueData`.
  - Usa `DialogueOverlay.show()` para mostrar diálogos sobre cualquier pantalla.
  - Soporta skip con botón "SALTAR" en la esquina superior derecha.
  - Renderiza avatares grandes (`dialogue_body`) a la derecha y caja de texto a la izquierda.
  
- **`DialogueBox`** (`lib/narrative/components/dialogue_box.dart`):
  - Efecto typewriter con velocidad configurable (20 chars/seg).
  - Muestra avatar pequeño (70×70) en la caja de diálogo.
  - Indicador "Toca para continuar" con animación de pulso.
  - Soporta diferentes tipos: `normal`, `internal`, `phone`, `system`, `thought`.

- **`DialogueData`** (`lib/narrative/models/dialogue_data.dart`):
  - Modelo simple: `speakerName`, `text`, `avatarPath`, `type`, `canSkip`, `autoAdvanceDelay`.

### Sistema de combate actual
- **`PlayerCharacter`** (`lib/game/components/player.dart`):
  - Dan con 100 HP, velocidad 200.
  - Sistema de armas: `WeaponInventory` con cuchillo y pistola.
  - Invencibilidad temporal (1s) al recibir daño.
  - Movimiento con WASD/flechas, ataque con Espacio, cambio de arma con Q.

- **`MelCharacter`** (`lib/game/components/mel.dart`):
  - Companion que sigue a Dan a 80px de distancia.
  - Habilidad de curación (E): restaura 100 HP con cooldown de 15s.
  - Renderizada como círculo cyan.
  - No es jugable actualmente.

- **`ExpedienteKorinGame`** (`lib/game/expediente_game.dart`):
  - Motor principal con sistema de capítulos.
  - Carga mapas Tiled por capítulo.
  - Maneja Game Over y restart.

---

## Parte 2: Nuevos componentes a crear

### 1. Pantalla de selección de rol
**Archivo**: `lib/narrative/screens/role_selection_screen.dart`

**Funcionalidad**:
- Pantalla Flutter que aparece después del diálogo post-resonante.
- Muestra dos tarjetas rectangulares con información de cada rol:
  - **Dan**: Cuchillo y pistola, juego directo.
  - **Mel**: Mano mutante, regeneración, 2 resurrecciones.
- Al seleccionar, guarda la elección y transiciona al mapa exterior.

**Estructura visual**:
```
┌─────────────────────────────────────────┐
│  [Fondo oscuro con vignette]            │
│                                         │
│  ┌──────────────┐   ┌──────────────┐   │
│  │     DAN      │   │     MEL      │   │
│  │              │   │              │   │
│  │ [Silueta]    │   │ [Silueta]    │   │
│  │              │   │              │   │
│  │ HP: 100      │   │ HP: 200      │   │
│  │ Armas: 2     │   │ Regen: +2/s  │   │
│  │              │   │ Revivir: 2   │   │
│  └──────────────┘   └──────────────┘   │
│                                         │
│  [Botón CONFIRMAR]                      │
└─────────────────────────────────────────┘
```

**Datos a guardar**:
- Enum `PlayerRole { dan, mel }` en un servicio de estado global.

---

### 2. Modelo de datos para rol seleccionado
**Archivo**: `lib/game/models/player_role.dart`

```dart
enum PlayerRole { dan, mel }

class RoleSelection {
  static PlayerRole? selectedRole;
  
  static void selectRole(PlayerRole role) {
    selectedRole = role;
  }
  
  static PlayerRole get currentRole => selectedRole ?? PlayerRole.dan;
}
```

---

### 3. Modificar `PlayerCharacter` para soportar rol Mel
**Archivo**: `lib/game/components/player.dart`

**Cambios necesarios**:
- Agregar parámetro `PlayerRole role` al constructor.
- Si `role == PlayerRole.mel`:
  - `_maxHealth = 200.0`
  - Agregar regeneración pasiva: `+2 HP cada 2 segundos`.
  - Deshabilitar armas convencionales.
  - Agregar habilidad de "mano mutante" (ataque cuerpo a cuerpo que drena vida).
- Si `role == PlayerRole.dan`:
  - Mantener comportamiento actual (100 HP, armas).

**Pseudo-código para regeneración**:
```dart
double _regenTimer = 0.0;
static const double _regenInterval = 2.0;
static const double _regenAmount = 2.0;

void update(double dt) {
  super.update(dt);
  
  if (role == PlayerRole.mel && !_isDead) {
    _regenTimer += dt;
    if (_regenTimer >= _regenInterval) {
      heal(_regenAmount);
      _regenTimer = 0.0;
    }
  }
  
  // ... resto del código
}
```

---

### 4. Sistema de resurrecciones para Mel
**Archivo**: `lib/game/systems/resurrection_system.dart`

**Funcionalidad**:
- Cuando un enemigo muere, crear una "tumba" (componente visual).
- Si el jugador es Mel y tiene resurrecciones disponibles, mostrar prompt "Presiona E para revivir".
- Al presionar E cerca de la tumba:
  - Consumir 1 resurrección (máximo 2).
  - Revivir al enemigo como aliado temporal.
  - Actualizar contador en HUD.

**Componentes**:
```dart
class EnemyTomb extends PositionComponent {
  final String enemyType;
  double lifetime = 5.0; // Desaparece después de 5s
  
  // Render: círculo luminoso con holograma
}

class ResurrectionManager extends Component {
  int resurrectionsUsed = 0;
  static const int maxResurrections = 2;
  
  bool canResurrect() => resurrectionsUsed < maxResurrections;
  
  void resurrect(EnemyTomb tomb) {
    if (!canResurrect()) return;
    
    resurrectionsUsed++;
    // Crear enemigo aliado
    spawnAllyFromTomb(tomb);
  }
}
```

---

### 5. Enemigo: Irracional ligero
**Archivo**: `lib/game/components/enemies/irracional.dart`

**Características**:
- HP bajo (30-50).
- Ataque cuerpo a cuerpo (5-10 daño).
- Velocidad lenta (100).
- Al morir, crear `EnemyTomb`.

**Comportamiento**:
- Persigue al jugador.
- Ataca al contacto.
- Puede ser derribado (aturdido) sin matarlo.

---

### 6. Mapa exterior (Tiled)
**Archivo**: `assets/tiles/capitulo_3/exterior_bunker.tmx`

**Especificaciones**:
- Dimensiones: 200 px × 200 px (ajustar según tile size, ej. 32×32 = 6.25×6.25 tiles, redondear a 7×7 o escalar).
- Capas:
  - `ground`: Suelo base.
  - `walls`: Paredes y obstáculos.
  - `spawns`: Puntos de aparición de irracionales.
  - `exit`: Zona de salida.

**Zonas**:
- Entrada al búnker (spawn del jugador).
- Corredores laterales con sombras.
- Sector central con humo y drones caídos.

---

### 7. HUD para Mel
**Archivo**: `lib/game/ui/mel_hud.dart`

**Elementos adicionales**:
- Contador de resurrecciones: "Revivir: 1/2" con iconos.
- Barra de regeneración (opcional, puede ser partículas en la barra de HP).

---

## Parte 3: Flujo de implementación

### Fase 1: Diálogos y selección de rol
1. Crear diálogo post-resonante en `BunkerBossLevel` que se activa al derrotar al jefe.
2. Crear `RoleSelectionScreen` con las dos tarjetas.
3. Implementar navegación: diálogo → selección → mapa exterior.

### Fase 2: Modificar sistema de jugador
1. Agregar `PlayerRole` enum y servicio de selección.
2. Modificar `PlayerCharacter` para soportar stats de Mel.
3. Implementar regeneración pasiva para Mel.
4. Crear habilidad de "mano mutante" (ataque que drena vida).

### Fase 3: Sistema de resurrecciones
1. Crear `EnemyTomb` component.
2. Crear `ResurrectionManager`.
3. Modificar enemigos para crear tumba al morir.
4. Implementar detección de proximidad y prompt "Presiona E".
5. Implementar lógica de resurrección y creación de aliado.

### Fase 4: Enemigos y mapa
1. Crear enemigo `Irracional` con comportamiento básico.
2. Diseñar mapa exterior en Tiled (200×200 px).
3. Configurar spawns de irracionales en el mapa.
4. Implementar oleadas o spawn continuo.

### Fase 5: HUD y polish
1. Actualizar HUD para mostrar contador de resurrecciones (Mel).
2. Agregar efectos visuales para regeneración.
3. Agregar efectos para resurrección (partículas verdes).
4. Testear balance (HP, daño, cooldowns).

---

## Parte 4: Consideraciones técnicas

### Compatibilidad con sistema de diálogos
- Usar `DialogueOverlay.show()` para mostrar diálogos antes de la selección.
- La selección de rol debe ser una pantalla Flutter normal, no un overlay de Flame.
- Después de seleccionar, transicionar al `ExpedienteKorinGame` con el rol elegido.

### Gestión de estado
- Crear un servicio singleton para `RoleSelection` que persista durante la sesión.
- Pasar el rol seleccionado al constructor de `PlayerCharacter`.

### Colisiones y detección de proximidad
- Usar `CollisionCallbacks` para detectar cuando el jugador está cerca de una tumba.
- Mostrar prompt solo si `distance < 50px` y `canResurrect()`.

### Balance de gameplay
- **Dan**: Mayor daño, menor supervivencia.
- **Mel**: Mayor supervivencia (200 HP + regen), menor daño directo, utilidad táctica (resurrecciones).

---

## Parte 5: Archivos a crear/modificar

### Crear nuevos archivos:
1. `lib/narrative/screens/role_selection_screen.dart`
2. `lib/game/models/player_role.dart`
3. `lib/game/systems/resurrection_system.dart`
4. `lib/game/components/enemies/irracional.dart`
5. `lib/game/components/enemy_tomb.dart`
6. `lib/game/ui/mel_hud.dart`
7. `assets/tiles/capitulo_3/exterior_bunker.tmx`

### Modificar archivos existentes:
1. `lib/game/components/player.dart` - Agregar soporte para rol Mel.
2. `lib/game/components/mel.dart` - Convertir en jugable o deprecar.
3. `lib/game/expediente_game.dart` - Pasar rol seleccionado al crear jugador.
4. `lib/game/ui/game_hud.dart` - Mostrar contador de resurrecciones si es Mel.
5. `lib/game/levels/bunker_boss_level.dart` - Agregar diálogo post-victoria.

---

## Parte 6: Próximos pasos inmediatos

1. **Definir diálogos**: Escribir el texto exacto del diálogo post-resonante y las descripciones de las tarjetas.
2. **Diseñar UI de tarjetas**: Mockup visual de la pantalla de selección.
3. **Crear mapa en Tiled**: Diseñar el layout 200×200 px con zonas definidas.
4. **Implementar `RoleSelectionScreen`**: Primera pantalla funcional.

---

## Notas adicionales

- **Reutilización**: El sistema de selección de rol debe ser escalable para futuros capítulos donde se agreguen más roles o variantes.
- **Narrativa**: Los diálogos deben mantener el tono introspectivo y cyber-noir establecido en los capítulos anteriores.
- **Testing**: Probar ambos roles extensivamente para asegurar balance y diversión.

---

Este plan está listo para ser ejecutado por fases. ¿Quieres que comencemos con la Fase 1 (diálogos y selección de rol) o prefieres que primero definamos los textos de los diálogos?
