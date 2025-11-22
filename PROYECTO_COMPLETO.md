# 📘 EXPEDIENTE KŌRIN - Documentación Completa del Proyecto
> **Versión**: 0.2.0  
> **Última Actualización**: Noviembre 2025  
> **Motor**: Flame Engine (Flutter)

---

## 📋 Índice Rápido

1. [Estado Actual](#estado-actual)
2. [Arquitectura del Juego](#arquitectura)
3. [Sistemas Implementados](#sistemas-implementados)
4. [Enemigos y Bosses](#enemigos-y-bosses)
5. [Mecánicas de Combate](#mecánicas-de-combate)
6. [Sistema Narrativo](#sistema-narrativo)
7. [Roadmap Futuro](#roadmap-futuro)
8. [Referencia Técnica](#referencia-técnica)

---

## 🎮 ESTADO ACTUAL

### ✅ Sistemas Funcionales

**Core:**
- Motor Flame con colisiones, cámara, HUD
- Dual character system (Dan/Mel)
- Sistema de 3 vidas con diálogos
- Weapon system con cambio dinámico

**Combate:**
- Yurei Kohaa boss (3000 HP, 3 fases)
- Sistema de resurrecciones (slots)
- Aliados temporales y permanentes (Kijin)
- Habilidad compartida (Dash de Mel con Kijin vivo)

**Niveles:**
- KohaaTestLevel (arena de prueba)
- BunkerBossLevel
- ExteriorMapLevel

**Narrativa:**
- Sistema de diálogos con overlays
- Contexto según rol (Dan/Mel)
- Diálogos de muerte/resurrección

---

## 🏗️ ARQUITECTURA

### Estructura de Directorios

```
lib/
├── game/
│   ├── components/
│   │   ├── enemies/         # Enemigos y bosses
│   │   ├── effects/         # Efectos visuales
│   │   ├── player.dart      # Dan/Mel
│   │   └── mel.dart         # Companion
│   ├── levels/              # Niveles de prueba
│   ├── systems/             # Managers (resurrecciones, spawns)
│   └── expediente_game.dart # Motor principal
├── combat/                  # Sistema de armas
└── narrative/               # Diálogos y escenas

assets/
├── avatars/                 # Diálogos
└── tiles/                   # Mapas Tiled
```

### Jerarquía de Componentes

```
ExpedienteKorinGame
├── World
│   ├── PlayerCharacter (Dan o Mel)
│   ├── MelCharacter (companion)
│   ├── Enemies
│   │   ├── IrrationalEnemy
│   │   ├── YureiKohaa (boss)
│   │   └── AlliedEnemy / RedeemedKijinAlly
│   └── ResurrectionManager
└── Camera Viewport
    ├── GameHUD
    └── Overlays (Diálogos, GameOver)
```

---

## ⚙️ SISTEMAS IMPLEMENTADOS

### 1. Sistema de Roles

**Dan (Guerrero):**
- HP: 100
- Velocidad: 200
- Armas: Pistola + Cuchillo
- Rol: DPS y combate directo

**Mel (Soporte Mágico):**
- HP: 80
- Velocidad: 180
- Regeneración: 2 HP cada 3s
- Arma: Mano Mutante (drenaje 30%)
- Habilidades:
  - Resucitar enemigos (E)
  - Dash compartido si hay Kijin vivo (SHIFT)

### 2. Sistema de Resurrecciones

**Mecánica:**
- Máximo: 2 slots por defecto
- Irracionales: 1 slot, duran 45s
- Kijin: 2 slots, NO expiran
- Manager automático de slots

**Tipos de Tumba:**
| Tipo | Color | Duración | Costo |
|------|-------|----------|-------|
| Irracional | Púrpura | 5s | 1 slot |
| Kijin | Rojo | 10s | 2 slots |
| Aliado muerto | Púrpura | 8s | 1 slot |
| Kijin redimido | Púrpura | 5 min | 2 slots |

### 3. Habilidad Compartida (NUEVO)

**Dash de Mel con Kijin:**
- Requisito: Tener RedeemedKijinAlly vivo
- Control: SHIFT
- Preparación: 0.6s (invulnerable)
- Dash: 0.3s a velocidad 600
- Cooldown: 8s
- Risk/Reward: Si Kijin muere, pierde habilidad

---

## 👹 ENEMIGOS Y BOSSES

### Categoría 1: Irracionales (Sector 2)
```dart
HP: 50 | Velocidad: 100 | Daño: 10
- IA: Perseguir jugador
- Al morir: Tumba púrpura 5s
- Pueden aturdirse <30% HP
```

### Categoría 2: Kijin (Sector 4)

**Yurei Kohaa - "La Novia Escarlata"**

**Stats:**
```dart
HP: 3000 | Velocidad: 150 | Daño: 25
Tipo: Boss Kijin (Categoría 2)
```

**Fases de Combate:**

**Fase 1 (100-66% HP): Agresión**
- Dash attack (preparación invulnerable 0.8s)
- IA táctica (60% Dan, 40% aliados)
- Spawn enfermeros a 80% HP

**Fase 2 (60% HP): Cambio de Fase**
- AOE explosion (200 radio, 30 daño)
- Spawn 2 enfermeros
- Se cura 750 HP (25% del máximo)

**Fase 3 (<30% HP): Explosión Defensiva**
- AOE 250 radio, 40 daño
- Empuje + curación 100 HP
- Cooldown 12s

**Al Derrotar:**
- Tumba Roja Kijin (10s)
- Puede ser resucitada por Mel (2 slots)

### RedeemedKijinAlly (Kohaa Aliada)

**Stats:**
```dart
HP: 120 | Velocidad: 160 | Daño: 30
Slots: 2 | Expiración: NUNCA (solo muerte)
```

**Habilidades:**
- Dash attack (6s cooldown, daño doble)
- IA de separación (evita apilamiento)
- Targeting inteligente (irracionales + bosses)
- Spawn 2 enfermeros aliados a 50% HP (duran 10 min)

**Al Morir:**
- Libera 2 slots
- Tumba 5 minutos
- Revivible múltiples veces

**Habilidad Compartida para Mel:**
- Otorga Dash (SHIFT) mientras esté viva
- Mismo sistema de invulnerabilidad
- Mayor movilidad para Mel

### Categoría 3: Singularidades

**On-Oyabun - "El Padrino de la Venganza"** (DISEÑADO, NO IMPLEMENTADO)

```dart
HP: 8000 | 3 Fases | 8+ Mecánicas Únicas
Ubicación: Sala del Reactor
Tiempo estimado: 15-20 min
```

**Resumen de Mecánicas:**
- Fase 1: Duelo honorable con katana + Duel Stance
- Fase 2: 3 armas simultáneas + katanas flotantes + QTE
- Fase 3: 6 armas + berserker + seppuku
- Final: Muerte honorable (F) → Resucitable (4 slots)

Ver `on_oyabun_design.md` para diseño completo.

---

## ⚔️ MECÁNICAS DE COMBATE

### Sistema de Armas (Dan)

**Cuchillo del Diente Caótico:**
- Daño: 100
- Cooldown: 0.5s
- Rango: Cuerpo a cuerpo

**Pistola Estándar:**
- Daño: 20
- Munición: 20
- Cooldown: 0.25s
- Recarga: R

**Controles:**
- WASD/Flechas: Movimiento
- Espacio: Atacar
- Q: Cambiar arma
- R: Recargar

### Sistema de Armas (Mel)

**Mano Mutante:**
- Daño: 40
- Cooldown: 0.8s
- Drenaje: 30% de vida
- Rango: 60 unidades

**Controles:**
- WASD/Flechas: Movimiento
- Espacio: Atacar
- E: Resucitar tumba cercana
- SHIFT: Dash (si hay Kijin vivo)

### Sistema de Invencibilidad

**Dan:**
- Duración: 1s tras recibir daño
- Visual: Parpadeo

**Mel:**
- Regeneración pasiva: 2 HP/3s
- Duración i-frames: 1s
- Dash preparation: Invulnerable 0.6s

---

## 📖 SISTEMA NARRATIVO

### Estructura de Capítulos

**Capítulo 1: El Llamado**
- Locación: Casa de Dan (USA)
- Objetivo: Explorar, recibir llamada de Marcus
- Transición: Al búnker (Japón)

**Capítulo 2: El Búnker**
- Locación: Búnker de Osaka
- Zonas: 9 habitaciones + Exterior
- Encuentro: Mel (primer companion)
- Boss: Mini-combate tutorial

**Capítulo 3: Sector 4 - Universidad** (Planificado)
- Boss final del búnker: On-Oyabun
- Infiltración al campus
- Búsqueda de Emma

### Sistema de Diálogos

**Componentes:**
```dart
DialogueSequence {
  id: String
  dialogues: List<DialogueData>
  onComplete: Function
}

DialogueData {
  speakerName: String
  text: String
  avatarPath: String?
  type: DialogueType (normal/system/internal)
  canSkip: bool
  autoAdvanceDelay: Duration?
}
```

**Overlay:**
- Pausa el juego
- Fondo oscurecido (vignette)
- Avatar + nombre + texto
- Click/Espacio para avanzar
- ESC para saltar (si canSkip)

---

## 🗺️ ROADMAP FUTURO

### Corto Plazo (1-2 meses)

**Sistemas Pendientes:**
- [ ] Mapas Tiled definitivos (casa + búnker)
- [ ] Sistema de destructibles con drops
- [ ] Resonantes con objetos obsesivos
- [ ] UI mejorada (cooldowns, minimapa)

**Assets:**
- [ ] Sprites finales (actualmente círculos)
- [ ] Avatares pequeños para diálogos
- [ ] Avatar de Emma

### Medio Plazo (3-6 meses)

**Capítulo 3: Universidad**
- [ ] Mapas del campus
- [ ] Resonantes académicos (profesores/estudiantes)
- [ ] Primer Kijin como mini-boss
- [ ] Pistas sobre Emma

**On-Oyabun Boss:**
- [ ] Implementar Fase 1 (Duel Stance)
- [ ] Implementar Fase 2 (QTE + katanas)
- [ ] Implementar Fase 3 (Berserker)
- [ ] Mecánica final honorable
- [ ] Sistema de resurrección (4 slots)

### Largo Plazo (6+ meses)

**Capítulo 4: El Descenso**
- [ ] Encuentro con Emma (mutando)
- [ ] Dilema moral
- [ ] Revelación de Mel
- [ ] Boss: Singularidad final

**Finales Múltiples:**
- [ ] Redención (Emma salvada, Mel sacrificada)
- [ ] Caída (Dan muta, Mel lo detiene)
- [ ] Sacrificio (Dan se sacrifica)
- [ ] Verdad (twist narrativo)

---

## 🔧 REFERENCIA TÉCNICA

### Comandos de Testing

**Cargar nivel de Kohaa:**
```dart
// En main.dart o expediente_game.dart
final testLevel = KohaaTestLevel();
world.add(testLevel);
```

**Iniciar con boss mode:**
```dart
ExpedienteKorinGame(startInBossMode: true)
```

**Seleccionar rol:**
```dart
ExpedienteKorinGame(selectedRole: PlayerRole.mel)
```

### Stats Balance Reference

| Entidad | HP | Velocidad | Daño | Slots |
|---------|-----|-----------|------|-------|
| Dan | 100 | 200 | Variable | - |
| Mel | 80 | 180 | 40 | - |
| Irracional | 50 | 100 | 10 | - |
| Aliado Normal | 60 | 130 | 18 | 1 |
| Kohaa Boss | 3000 | 150 | 25 | - |
| Kohaa Aliada | 120 | 160 | 30 | 2 |
| On-Oyabun | 8000 | 120-200 | 40+ | - |
| Oyabun Aliado | 300 | 180 | 60 | 4 |

### Archivos Críticos

**Core:**
- `lib/game/expediente_game.dart` - Motor principal
- `lib/game/components/player.dart` - Dan/Mel con habilidades
- `lib/main.dart` - Entry point

**Enemigos:**
- `lib/game/components/enemies/yurei_kohaa.dart` - Boss Kijin
- `lib/game/components/enemies/redeemed_kijin_ally.dart` - Aliada
- `lib/game/components/enemies/irracional.dart` - Básico

**Sistemas:**
- `lib/game/systems/resurrection_system.dart` - Manager de slots
- `lib/combat/weapon_system.dart` - Armas
- `lib/narrative/components/dialogue_system.dart` - Diálogos

**Niveles:**
- `lib/game/levels/kohaa_test_level.dart` - Arena de prueba

### Debugging Tips

**Ver slots disponibles:**
```dart
debugPrint('Slots: ${resurrectionManager.resurrectionsRemaining}');
```

**Verificar Kijin vivo:**
```dart
final kijins = game.world.children.query<RedeemedKijinAlly>();
for (final k in kijins) {
  if (!k.isDead) debugPrint('Kijin alive: HP ${k.health}');
}
```

**Teleport player:**
```dart
player.position = Vector2(400, 300);
```

---

## 🎯 CHECKLIST DE FEATURES

### Sistemas Core
- [x] Motor Flame funcional
- [x] Dual character (Dan/Mel)
- [x] Sistema de colisiones
- [x] Cámara que sigue jugador
- [x] HUD con vida y cooldowns
- [x] Sistema de vidas (3 max)

### Combate
- [x] Weapon system
- [x] Enemigos básicos (Irracional)
- [x] Boss Kijin (Kohaa)
- [x] Sistema de resurrecciones
- [x] Aliados temporales
- [x] Aliados permanentes (Kijin)
- [x] Habilidad compartida (Dash)
- [ ] Más tipos de armas
- [ ] Destructibles con drops
- [ ] Resonantes (objeto obsesivo)

### Narrativa
- [x] Sistema de diálogos
- [x] Overlays funcionales
- [x] Diálogos contextuales por rol
- [x] Secuencias con auto-advance
- [ ] Capítulo 1 completo
- [ ] Capítulo 2 completo
- [ ] Interactables del búnker

### Niveles
- [x] Kohaa Test Level
- [x] Bunker Boss Level
- [x] Exterior Map Level
- [ ] Mapas Tiled definitivos
- [ ] Casa de Dan completa
- [ ] Búnker 9 habitaciones
- [ ] Universidad (Sector 4)

### Bosses
- [x] Yurei Kohaa (implementado)
- [x] Sistema de resurrección Kijin
- [ ] On-Oyabun (diseñado, no implementado)
- [ ] Otros Kijin
- [ ] Singularidad final

---

## 📚 DOCUMENTOS RELACIONADOS

**En este repositorio:**
- `CURRENT_STATE.md` - Estado técnico actual
- `WORK_LOG.md` - Registro de cambios
- `LORE_Y_CONTEXTO.md` - Narrativa completa
- `KOHAA_TEST_GUIDE.md` - Guía de testing Kohaa

**En artifacts (.gemini):**
- `resumen_yurei_kohaa.md` - Sistema Kohaa completo
- `on_oyabun_design.md` - Diseño On-Oyabun (25+ páginas)

---

## 🎨 INSPIRACIONES DE DISEÑO

**Gameplay:**
- Hotline Miami (combate frenético + muerte rápida)
- Hades (sistema de resurrecciones/aliados)
- Sekiro (combate con timing, bosses honorables)

**Narrativa:**
- Silent Hill (horror psicológico)
- The Last of Us (relación protector-protegido)
- Spec Ops: The Line (cuestionamiento moral)

**Arte:**
- Minimalista (placeholders OK)
- Estética cyber-japonesa
- Color coding por tipo (rojo=boss, verde=aliado, púrpura=tumba)

---

## 💡 NOTAS DEL DESARROLLADOR

### Filosofía de Diseño

1. **Narrativa Integrada**: Cada mecánica cuenta una historia
2. **Risk/Reward**: Decisiones tácticas significativas
3. **Respeto a la Dificultad**: Justo pero letal
4. **Progresión Horizontal**: Más opciones, no solo stats

### Lecciones Aprendidas

**Kohaa Implementation:**
- Sistema de fases genérico reutilizable
- Separación de IA por estado
- Invulnerabilidad durante preparación = feedback claro
- Resurrecciones añaden replay value

**Sistema de Slots:**
- Balance entre cantidad y calidad de aliados
- Manager centralizado evita bugs
- Costos diferenciados (1 vs 2 vs 4) crean decisiones

**Habilidad Compartida:**
- Conecta narrativa con gameplay
- Risk/reward (mantener vivo Kijin = buff)
- Diferenciación de roles (solo Mel)

### Próximas Prioridades

1. Assets visuales básicos (mejorar de círculos)
2. Mapas Tiled para Capítulo 1-2
3. Pulir balance de Kohaa
4. Prototipar On-Oyabun Fase 1

---

**Versión del Documento**: 1.0  
**Mantenido por**: Equipo Expediente Kōrin  
**Última Revisión**: Noviembre 2025
