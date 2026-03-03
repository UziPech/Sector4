import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../expediente_game.dart';
import '../player.dart';
import '../enemies/redeemed_kijin_ally.dart';
import '../enemies/allied_enemy.dart';
import '../enemies/minions/yakuza_ghost.dart';
import '../enemies/minions/floating_katana.dart';
import '../projectiles/falling_katana.dart';
import '../../../narrative/components/dialogue_system.dart';
import '../effects/screen_flash.dart';
import '../effects/teleport_effect.dart';
import '../effects/explosive_wave.dart'; // Importar onda explosiva
import '../../levels/exterior_map_level.dart'; // Importar nivel exterior para límites
import '../../../narrative/models/dialogue_data.dart';
import '../../models/player_role.dart';

/// æ€¨è¦ªåˆ† ON-OYABUN - "El Padrino de la Venganza"
/// Singularidad (Categoría 3) - Jefe final del exterior
///
/// Fusión de víctima y verdugo, atrapado en un bucle eterno
/// de culpa y venganza. Líder del clan KÅga-gumi que ejecutó
/// la masacre del búnker y las 28 víctimas que se fusionaron con él.
class OnOyabunBoss extends PositionComponent
    with CollisionCallbacks, HasGameReference<ExpedienteKorinGame> {
  // ==================== STATS BASE ====================
  final double maxHealth = 10000.0;
  double health = 10000.0;

  final double baseSpeed = 120.0;
  double currentSpeed = 120.0;

  final double baseDamage = 40.0;

  // Radio de colisión
  final double collisionRadius = 50.0;

  // Objetivo actual
  PositionComponent? target;

  // ==================== ESTADO DE FASES ====================
  BossPhase currentPhase = BossPhase.phase1;

  // Umbrales de HP para transiciones
  final double phase2Threshold = 0.66; // 66% HP (5280 HP)
  final double phase3Threshold = 0.33; // 33% HP (2640 HP)
  // ==================== SISTEMA DE ARMAS ====================
  List<String> activeWeapons = ['katana']; // Solo katana en Fase 1

  // Configuración de armas
  final Map<String, WeaponConfig> weapons = {
    'katana': WeaponConfig(damage: 50, range: 80, cooldown: 1.2),
    'wakizashi': WeaponConfig(damage: 35, range: 60, cooldown: 0.8),
    'tanto': WeaponConfig(damage: 25, range: 200, cooldown: 2.0), // Lanzado
    'pistola': WeaponConfig(damage: 30, range: 400, cooldown: 1.5),
    'cadenas': WeaponConfig(damage: 20, range: 150, cooldown: 3.0),
    'manos': WeaponConfig(damage: 45, range: 50, cooldown: 0.6), // CQC
  };

  Map<String, double> weaponCooldowns = {};

  // ==================== IA Y COMBATE ====================
  Vector2 velocity = Vector2.zero();
  double aiTimer = 0.0;
  double aiUpdateInterval = 0.5; // Actualizar IA cada 0.5s

  String currentAction = 'idle';
  double actionTimer = 0.0;

  // Control de combos (Fase 1)
  bool isPerformingCombo = false;
  int comboStep = 0;
  double comboTimer = 0.0;
  String currentCombo = '';

  // Cooldowns de combos especiales (reducidos para más acción)
  double tsukiCooldown = 0.0;
  double tsubameCooldown = 0.0;
  final double tsukiCooldownDuration = 5.0; // Reducido de 8s a 5s
  final double tsubameCooldownDuration = 4.0; // Reducido de 6s a 4s

  // Duel Stance (mecánica especial)
  bool inDuelStanceCharge = false;
  double duelStanceTimer = 0.0;
  final double duelStanceChargeDuration = 2.0; // Reducido de 2.8s a 2.0s
  final double duelStanceParryWindow =
      0.25; // Aumentado de 0.2s a 0.25s (más justo)
  bool duelStanceParryWindowActive = false;
  double duelStanceCooldown = 0.0;
  final double duelStanceCooldownDuration = 10.0; // Reducido de 15s a 10s

  // Fantasmas Yakuza (spawn a 80% HP)
  bool hasSpawnedYakuzaGhosts = false;

  // Ataques especiales Fase 2 (reducidos para más acción)
  double cadenaCulpaCooldown = 0.0;
  final double cadenaCulpaCooldownDuration = 8.0; // Reducido de 12s a 8s
  double lluviaAceroCooldown = 0.0;
  final double lluviaAceroCooldownDuration = 10.0; // Reducido de 15s a 10s

  // Onda de Curación (nueva habilidad)
  double healingWaveCooldown = 0.0;
  final double healingWaveCooldownDuration = 20.0; // Cada 20 segundos
  final double healingWaveAmount = 300.0; // Se cura 300 HP
  final double healingWaveDamage = 60.0; // Daña 60 HP
  final double healingWaveRadius =
      800.0; // Aumentado de 250 a 800 para mapa exterior
  final double healingWavePushForce =
      80.0; // Reducido de 200 a 80 para evitar bugs

  // Grito de Guerra (habilidad épica)
  double warCryCooldown = 0.0;
  final double warCryCooldownDuration = 35.0; // Cada 35 segundos
  final int warCryGhostCount = 4; // Spawn 4 fantasmas
  bool hasUsedWarCry = false;

  // Spawns adicionales Fase 2
  bool hasSpawnedVictimas = false; // 50% HP
  bool hasSpawnedKatanas = false; // 40% HP

  // ==================== SISTEMA DE TELETRANSPORTACIÓN INTELIGENTE ====================
  // Detecta cuando el jugador huye y se teletransporta
  double _previousDistanceToTarget = 0.0;
  int _consecutiveDistanceIncreases = 0;
  final int _fleeingThreshold = 3; // Reducido de 4 a 3 para mayor sensibilidad
  double _teleportCooldown = 0.0;
  final double _teleportCooldownDuration = 12.0; // Cooldown de 12s
  bool _canTeleport = true;

  // Historial de posiciones del objetivo para predecir movimiento
  final List<Vector2> _targetPositionHistory = [];
  final int _maxHistorySize = 5;

  // ==================== ESTADO GENERAL ====================
  bool isDead = false;
  bool isInvulnerable = false;
  double invulnerabilityTimer = 0.0;
  bool isVulnerable = false;
  bool isKneeling = false;
  bool honorableDeathAvailable = false;

  // Flags de transición
  bool hasTransitionedToPhase2 = false;
  bool hasTransitionedToPhase3 = false;

  // Getters de estado
  bool get inDuelStance => inDuelStanceCharge || duelStanceParryWindowActive;

  // Umbral de muerte honorable
  final double honorableDeathThreshold = 0.10; // 10% HP

  // Sistema de sprites
  SpriteAnimationComponent? _spriteComponent;
  late SpriteAnimation _idleAnimation;
  late SpriteAnimation _walkAnimation;
  late SpriteAnimation _attackAnimation;

  // Cached TextPainters
  TextPainter? _phaseIndicatorPainter;
  BossPhase? _lastPhase;

  // ==================== CONSTRUCTOR ====================
  OnOyabunBoss({required Vector2 position})
    : super(position: position, anchor: Anchor.center);

  // ==================== INICIALIZACIÓN ====================
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Tamaño del jefe (3 metros de alto, el doble del jugador)
    size = Vector2(60, 90); // Width x Height

    // Cargar sprites del boss
    await _loadSprites();

    // Agregar hitbox circular
    add(RectangleHitbox(size: Vector2(60, 90), anchor: Anchor.center));

    // Inicializar cooldowns de armas
    for (final weaponName in weapons.keys) {
      weaponCooldowns[weaponName] = 0.0;
    }

    // Inicializar target al jugador
    target = game.player;

    debugPrint('âš”ï¸ On-Oyabun ha sido invocado! HP: $maxHealth');
    debugPrint(
      'ðŸŽ¯ Target inicial: ${game.player.role == PlayerRole.mel ? "Mel" : "Dan"}',
    );
  }

  /// Carga el spritesheet y configura las animaciones
  Future<void> _loadSprites() async {
    try {
      // [PERF] print('ðŸ” [Oyabun] Intentando cargar sprites...');
      final spriteSheet = await game.images.load(
        'sprites/On_oyabuSpritesComplete.png',
      );
      // [PERF] print('ðŸ” [Oyabun] SpriteSheet cargado: ${spriteSheet.width}x${spriteSheet.height}');

      // Configuración del spritesheet
      // Dimensiones confirmadas: 672x420px = 8x5 frames de 84x84px
      const frameWidth = 84.0;
      const frameHeight = 84.0;
      const framesPerRow = 8;

      // Animación idle (primera fila)
      _idleAnimation = SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: framesPerRow,
          stepTime: 0.2,
          textureSize: Vector2(frameWidth, frameHeight),
          texturePosition: Vector2.zero(),
        ),
      );

      // Animación walk (segunda fila)
      _walkAnimation = SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: framesPerRow,
          stepTime: 0.12,
          textureSize: Vector2(frameWidth, frameHeight),
          texturePosition: Vector2(0, frameHeight),
        ),
      );

      // Animación attack (tercera fila)
      _attackAnimation = SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: framesPerRow,
          stepTime: 0.1,
          textureSize: Vector2(frameWidth, frameHeight),
          texturePosition: Vector2(0, frameHeight * 2),
        ),
      );

      // Crear componente de sprite escalado
      _spriteComponent = SpriteAnimationComponent(
        animation: _idleAnimation,
        size: Vector2(size.x * 1.2, size.y * 1.2), // Escalar component
        anchor: Anchor.center,
      );

      add(_spriteComponent!);
      // [PERF] print('ðŸŽ‰ [Oyabun] Sprite component agregado exitosamente');

      debugPrint('âœ… Sprites de On-Oyabun cargados exitosamente');
    } catch (e, stackTrace) {
      debugPrint('âš ï¸ Error cargando sprites de On-Oyabun: $e');
      debugPrint('   Stack trace: $stackTrace');
      debugPrint('   Usando fallback a renderizado rectangular');
    }
  }

  /// Recibe daño de cualquier fuente
  // (Este método fue movido a la sección de DAÑO Y MUERTE más abajo)

  // ==================== UPDATE LOOP ====================
  @override
  void update(double dt) {
    super.update(dt);

    if (isDead) return;

    // Actualizar animación de sprites según estado
    if (_spriteComponent != null) {
      // Determinar animación según acción
      if (currentAction == 'attacking' || isPerformingCombo) {
        _spriteComponent!.animation = _attackAnimation;
      } else if (velocity.length > 10) {
        _spriteComponent!.animation = _walkAnimation;
      } else {
        _spriteComponent!.animation = _idleAnimation;
      }
    }

    // Actualizar cooldowns de armas
    _updateWeaponCooldowns(dt);

    // Actualizar cooldowns de combos especiales
    if (tsukiCooldown > 0) tsukiCooldown -= dt;
    if (tsubameCooldown > 0) tsubameCooldown -= dt;
    if (duelStanceCooldown > 0) duelStanceCooldown -= dt;
    if (cadenaCulpaCooldown > 0) cadenaCulpaCooldown -= dt;
    if (lluviaAceroCooldown > 0) lluviaAceroCooldown -= dt;
    if (healingWaveCooldown > 0) healingWaveCooldown -= dt;
    if (warCryCooldown > 0) warCryCooldown -= dt;

    // Actualizar cooldown de teletransportación
    if (_teleportCooldown > 0) {
      _teleportCooldown -= dt;
      if (_teleportCooldown <= 0) {
        _canTeleport = true;
      }
    }

    // Actualizar invulnerabilidad temporal
    if (isInvulnerable) {
      invulnerabilityTimer -= dt;
      if (invulnerabilityTimer <= 0) {
        isInvulnerable = false;
      }
    }

    // Verificar transiciones de fase
    _checkPhaseTransitions();

    // Verificar spawn de Fantasmas Yakuza (80% HP en Fase 1)
    if (currentPhase == BossPhase.phase1 && !hasSpawnedYakuzaGhosts) {
      final hpPercent = health / maxHealth;
      if (hpPercent <= 0.80) {
        _spawnYakuzaGhosts();
      }
    }

    // Verificar spawn de Víctimas Espectrales (50% HP en Fase 2)
    if (currentPhase == BossPhase.phase2 && !hasSpawnedVictimas) {
      final hpPercent = health / maxHealth;
      if (hpPercent <= 0.50) {
        _spawnVictimasEspectrales();
      }
    }

    // Verificar spawn de Katanas Flotantes (40% HP en Fase 2)
    if (currentPhase == BossPhase.phase2 && !hasSpawnedKatanas) {
      final hpPercent = health / maxHealth;
      if (hpPercent <= 0.40) {
        _spawnKatanasFlotantes();
      }
    }

    // Actualizar Duel Stance si está activo
    if (inDuelStanceCharge) {
      _updateDuelStance(dt);
      return; // No ejecutar IA normal durante Duel Stance
    }

    // Actualizar combo en progreso
    if (isPerformingCombo) {
      comboTimer += dt;
      _updateCurrentCombo();
      return; // No ejecutar IA normal durante combo
    }

    // IA del jefe (según la fase) - Más agresiva
    if (!inDuelStance && !isKneeling) {
      aiTimer += dt;
      // Actualizar IA más frecuentemente para ser más reactivo
      final aiSpeed = currentPhase == BossPhase.phase1 ? 0.3 : 0.2;
      if (aiTimer >= aiSpeed) {
        _updateAI();
        aiTimer = 0.0;
      }
    }

    // Actualizar posición basada en velocidad
    position += velocity * dt;

    // Aplicar límites del mundo
    position = _constrainPositionToWorldBounds(position);

    // Reducir velocidad gradualmente (fricción)
    velocity *= 0.95;
  }

  // ==================== RENDER ====================
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Renderizar aura según fase (MANTENER)
    _renderAura(canvas);

    // FALLBACK: Si sprites no cargaron, renderizar rectángulo
    if (_spriteComponent == null) {
      _renderBodyFallback(canvas);
    }
    // NOTA: Si sprites cargaron, se renderizan automáticamente por SpriteAnimationComponent

    // Renderizar barra de HP
    _renderHealthBar(canvas);

    // Renderizar indicador de fase
    _renderPhaseIndicator(canvas);
  }

  void _renderAura(Canvas canvas) {
    Color auraColor = Colors.red.withValues(alpha: 0.3);
    double auraIntensity = 1.0;

    switch (currentPhase) {
      case BossPhase.phase1:
        auraColor = Colors.red.withValues(alpha: 0.3);
        auraIntensity = 1.0;
        break;
      case BossPhase.phase2:
        auraColor = Colors.red.withValues(alpha: 0.5);
        auraIntensity = 1.3;
        break;
      case BossPhase.phase3:
        auraColor = Colors.black.withValues(alpha: 0.6);
        auraIntensity = 1.5;
        break;
    }

    final auraPaint = Paint()
      ..color = auraColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      collisionRadius * auraIntensity,
      auraPaint,
    );
  }

  void _renderBodyFallback(Canvas canvas) {
    // FALLBACK: Rectángulo según fase si sprites no cargaron
    Color bodyColor = const Color(0xFF880000);

    switch (currentPhase) {
      case BossPhase.phase1:
        bodyColor = const Color(0xFF880000); // Rojo oscuro
        break;
      case BossPhase.phase2:
        bodyColor = const Color(0xFFAA0000); // Rojo más brillante
        break;
      case BossPhase.phase3:
        bodyColor = const Color(0xFF220000); // Negro rojizo
        break;
    }

    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    // Cuerpo principal
    canvas.drawRect(size.toRect(), bodyPaint);

    // Borde
    final borderPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(size.toRect(), borderPaint);
  }

  void _renderPhaseIndicator(Canvas canvas) {
    if (_phaseIndicatorPainter == null || _lastPhase != currentPhase) {
      _lastPhase = currentPhase;
      _phaseIndicatorPainter = TextPainter(
        text: TextSpan(
          text: 'Fase ${currentPhase.index + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    _phaseIndicatorPainter!.paint(canvas, Offset(5, size.y - 15));
  }

  void _renderHealthBar(Canvas canvas) {
    final barWidth = size.x;
    final barHeight = 4.0;
    final hpPercent = (health / maxHealth).clamp(0.0, 1.0);

    // Fondo de la barra
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, -10, barWidth, barHeight), bgPaint);

    // HP actual
    Color hpColor;
    if (hpPercent > 0.66) {
      hpColor = Colors.green;
    } else if (hpPercent > 0.33) {
      hpColor = Colors.orange;
    } else {
      hpColor = Colors.red;
    }

    final hpPaint = Paint()
      ..color = hpColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, -10, barWidth * hpPercent, barHeight),
      hpPaint,
    );
  }

  // ==================== SISTEMA DE FASES ====================
  void _checkPhaseTransitions() {
    final hpPercent = health / maxHealth;

    // Transición a Fase 2 (66% HP)
    if (hpPercent <= phase2Threshold && !hasTransitionedToPhase2) {
      transitionToPhase2();
    }
    // Transición a Fase 3 (33% HP)
    else if (hpPercent <= phase3Threshold && !hasTransitionedToPhase3) {
      transitionToPhase3();
    }
    // Mecánica final (10% HP)
    else if (hpPercent <= honorableDeathThreshold && !honorableDeathAvailable) {
      enterHonorableDeathState();
    }
  }

  void transitionToPhase2() {
    hasTransitionedToPhase2 = true;
    currentPhase = BossPhase.phase2;

    // Activar 3 armas (katana, wakizashi, cadenas)
    activeWeapons = ['katana', 'wakizashi', 'cadenas'];

    // Aumentar velocidad
    currentSpeed = 180.0;

    debugPrint('âš”ï¸ On-Oyabun: FASE 2 - LA MASACRE');
    debugPrint('   Armas activas: ${activeWeapons.length}');

    // FLASH BLANCO DRAMÁTICO
    _createScreenFlash();

    // ONDA EXPLOSIVA
    _triggerExplosiveWave();

    // Pausar y mostrar diálogos de transición
    Future.delayed(const Duration(milliseconds: 300), () {
      _showPhase2Dialogue();
    });
  }

  void transitionToPhase3() {
    hasTransitionedToPhase3 = true;
    currentPhase = BossPhase.phase3;

    // Activar TODAS las armas (6) - Berserker
    activeWeapons = [
      'katana',
      'wakizashi',
      'tanto',
      'pistola',
      'cadenas',
      'manos',
    ];

    // Velocidad berserker
    currentSpeed = 150.0;

    debugPrint('âš”ï¸ðŸ’€ On-Oyabun: FASE 3 - SEPPUKU ETERNO');
    debugPrint('   Armas activas: ${activeWeapons.length} (TODAS)');

    // Flash negro + rojo
    _createScreenFlash(color: Colors.black.withValues(alpha: 0.9));
    Future.delayed(const Duration(milliseconds: 300), () {
      _createScreenFlash(color: Colors.red);
      // ONDA EXPLOSIVA (más fuerte en fase 3 pero segura)
      _triggerExplosiveWave(damage: 50, force: 80, radius: 1000);
    });

    // Diálogos
    Future.delayed(const Duration(milliseconds: 600), () {
      _showPhase3Dialogue();
    });
  }

  void enterHonorableDeathState() {
    honorableDeathAvailable = true;
    isKneeling = true;
    currentAction = 'kneeling';

    // Solo queda la katana
    activeWeapons = ['katana'];

    // Inmóvil
    velocity = Vector2.zero();
    currentSpeed = 0;

    debugPrint('âš”ï¸ On-Oyabun: ESTADO DE MUERTE HONORABLE');
    debugPrint('   El jugador tiene 30 segundos para decidir...');

  }

  // ==================== IA Y COMBATE ====================
  void _updateAI() {
    _updateTarget();

    final dist = target != null
        ? position.distanceTo(target!.position)
        : double.infinity;

    // Sistema de detección de huida y teletransportación
    _checkForFleeingAndTeleport(dist);

    // IA básica según fase
    switch (currentPhase) {
      case BossPhase.phase1:
        _aiPhase1(dist);
        break;
      case BossPhase.phase2:
        _aiPhase2(dist);
        break;
      case BossPhase.phase3:
        _aiPhase3(game.player, dist);
        break;
    }
  }

  void _updateTarget() {
    final player = game.player;
    final previousTarget = target;

    // Buscar Kohaa ALIADA (RedeemedKijinAlly) con debug
    RedeemedKijinAlly? kohaa;
    final kohaaList = game.world.children.query<RedeemedKijinAlly>().toList();

    if (kohaaList.isEmpty) {
      // DEBUG: Kohaa aliada no existe en el mundo
      if (previousTarget != null && previousTarget is! PlayerCharacter) {
        debugPrint(
          'âš ï¸ KOHAA ALIADA NO ENCONTRADA en el mundo - Solo targetear jugador',
        );
      }
    } else {
      // Buscar específicamente a Kohaa (kijinType == 'kohaa')
      for (final k in kohaaList) {
        if (!k.isDead && k.kijinType == 'kohaa') {
          kohaa = k;
          // Debug solo cuando cambia de target (no cada frame)
          break;
        }
      }
    }

    // Decidir objetivo basado en distancia y estado
    if (kohaa != null && !kohaa.isDead) {
      final distToPlayer = player.isDead
          ? double.infinity
          : position.distanceTo(player.position);
      final distToKohaa = position.distanceTo(kohaa.position);

      // Si Kohaa está huyendo, cambiar temporalmente al jugador

      if (kohaa.isRetreating) {
        target = player.isDead ? kohaa : player;
        if (previousTarget != target && target == player) {
          debugPrint(
            'ðŸŽ¯ Boss cambió objetivo â†’ JUGADOR (Kohaa está huyendo)',
          );
        }
      }
      // Priorizar al JUGADOR si está cerca (< 250u)
      else if (distToPlayer < 250) {
        target = player;
        if (previousTarget != player) {
          debugPrint(
            'ðŸŽ¯ Boss cambió objetivo â†’ JUGADOR (Jugador está cerca)',
          );
        }
      }
      // Si no, priorizar a Kohaa si está MUY cerca (< 150u)
      else if (distToKohaa < 150) {
        target = kohaa;
        if (previousTarget != kohaa) {
          debugPrint(
            'ðŸŽ¯ Boss cambió objetivo â†’ KOHAA ALIADA (Kohaa está muy cerca)',
          );
        }
      }
      // Si no, el más cercano
      else if (distToKohaa < distToPlayer) {
        target = kohaa;
      } else {
        target = player;
      }
    } else {
      target = player.isDead ? null : player;
    }

    // Actualizar historial de posiciones del objetivo
    if (target != null) {
      _targetPositionHistory.add(target!.position.clone());
      if (_targetPositionHistory.length > _maxHistorySize) {
        _targetPositionHistory.removeAt(0);
      }
    }
  }

  /// Detecta si el objetivo está huyendo y ejecuta teletransportación táctica
  void _checkForFleeingAndTeleport(double currentDistance) {
    if (target == null || !_canTeleport || isKneeling) return;

    // CONDICIÓN ESPECIAL: Kohaa aliada está huyendo para recuperarse
    if (target is RedeemedKijinAlly) {
      final kohaa = target as RedeemedKijinAlly;
      if (kohaa.isRetreating) {
        debugPrint(
          'ðŸŒ€âš¡ ¡Kohaa está HUYENDO! Boss se teletransporta para perseguirla',
        );
        _executeTeleport();
        _consecutiveDistanceIncreases = 0;
        return;
      }
    }

    // CONDICIÓN 1: Objetivo muy lejos (kiting extremo)
    if (currentDistance > 400) {
      debugPrint(
        'âš ï¸ Objetivo demasiado lejos (${currentDistance.toInt()}u) - Teletransportación forzada',
      );
      _executeTeleport();
      _consecutiveDistanceIncreases = 0;
      return;
    }

    // CONDICIÓN 2: Detectar huida consistente
    if (currentDistance >= 200) {
      // Detectar si la distancia está aumentando consistentemente
      if (currentDistance > _previousDistanceToTarget + 5) {
        // Margen reducido de 10 a 5
        _consecutiveDistanceIncreases++;
      } else {
        _consecutiveDistanceIncreases = 0;
      }

      _previousDistanceToTarget = currentDistance;

      // Si detectamos huida consistente, teletransportar
      if (_consecutiveDistanceIncreases >= _fleeingThreshold) {
        debugPrint(
          'âš ï¸ Objetivo huyendo consistentemente - Teletransportación táctica',
        );
        _executeTeleport();
        _consecutiveDistanceIncreases = 0;
      }
    } else {
      _consecutiveDistanceIncreases = 0;
      _previousDistanceToTarget = currentDistance;
    }
  }

  /// Ejecuta la teletransportación táctica
  void _executeTeleport() {
    if (target == null) return;

    debugPrint('ðŸŒ€ ON-OYABUN: ¡TELETRANSPORTACIÓN TÁCTICA!');

    // Predecir posición futura del objetivo basado en historial
    Vector2 predictedPosition = target!.position.clone();

    if (_targetPositionHistory.length >= 3) {
      // Calcular vector de movimiento promedio
      final recentMovement =
          _targetPositionHistory.last -
          _targetPositionHistory[_targetPositionHistory.length - 3];
      // Predecir 0.5 segundos adelante
      predictedPosition = target!.position + (recentMovement * 0.5);
    }

    // Calcular posición de teletransportación (cerca pero no encima)
    final directionToTarget = (predictedPosition - position).normalized();
    final teleportDistance = 100.0; // Aparecer a 100 unidades del objetivo
    Vector2 teleportPosition =
        predictedPosition - (directionToTarget * teleportDistance);

    // APLICAR LÍMITES DEL MUNDO a la posición de teletransportación
    teleportPosition = _constrainPositionToWorldBounds(teleportPosition);

    // Efecto visual ANTES de teletransportar
    _createTeleportEffect(position.clone(), isFadeOut: true);

    // Teletransportar
    position = teleportPosition;
    velocity = Vector2.zero(); // Resetear velocidad

    // Efecto visual DESPUÉS de teletransportar
    Future.delayed(const Duration(milliseconds: 100), () {
      _createTeleportEffect(position.clone(), isFadeOut: false);
    });

    // Activar cooldown (más corto en fases avanzadas)
    _canTeleport = false;
    double cooldownTime = _teleportCooldownDuration;

    // Reducir cooldown según la fase
    switch (currentPhase) {
      case BossPhase.phase1:
        cooldownTime = _teleportCooldownDuration; // 12s
        break;
      case BossPhase.phase2:
        cooldownTime = _teleportCooldownDuration * 0.75; // 9s
        break;
      case BossPhase.phase3:
        cooldownTime = _teleportCooldownDuration * 0.5; // 6s (muy agresivo)
        break;
    }

    _teleportCooldown = cooldownTime;

    // Mensaje de advertencia
    final targetName = target is PlayerCharacter ? 'jugador' : 'Kohaa';
    debugPrint(
      '   âš¡ Teletransportado cerca de $targetName en posición predicha',
    );
    debugPrint(
      '   â±ï¸ Cooldown de teletransportación: ${cooldownTime.toStringAsFixed(1)}s',
    );
  }

  /// Restringe una posición a los límites del mundo (dinámico según tamaño del mapa)
  Vector2 _constrainPositionToWorldBounds(Vector2 pos) {
    final worldSize = game.camera.visibleWorldRect;

    // Boss level (1600x1200)
    double worldMinX = 100.0;
    double worldMaxX = 1500.0;
    double worldMinY = 100.0;
    double worldMaxY = 1100.0;

    // Detectar si estamos en el mapa exterior (2000x1500)
    final exteriorMap = game.world.children
        .query<ExteriorMapLevel>()
        .firstOrNull;

    if (exteriorMap != null) {
      // Límites para ExteriorMapLevel (2000x1500)
      // Dejamos 100px de margen por las paredes
      worldMinX = 100.0;
      worldMaxX = 1900.0;
      worldMinY = 100.0;
      worldMaxY = 1400.0;
    } else if (worldSize.width > 2000) {
      // Fallback para mapas muy grandes
      worldMinX = 250.0;
      worldMaxX = 2750.0;
      worldMinY = 250.0;
      worldMaxY = 2750.0;
    }

    return Vector2(
      pos.x.clamp(worldMinX, worldMaxX),
      pos.y.clamp(worldMinY, worldMaxY),
    );
  }

  /// Crea efecto visual de teletransportación
  void _createTeleportEffect(
    Vector2 effectPosition, {
    required bool isFadeOut,
  }) {
    // Flash negro/rojo en la posición
    final flashColor = isFadeOut
        ? Colors.black.withValues(alpha: 0.8)
        : Colors.red.withValues(alpha: 0.6);

    _createScreenFlash(color: flashColor);

    // Agregar efecto visual de círculo de sombras
    final teleportEffect = TeleportEffect(
      position: effectPosition,
      isFadeOut: isFadeOut,
      duration: 0.3,
    );
    game.world.add(teleportEffect);

  }

  /// Genera una onda explosiva que daña y empuja
  void _triggerExplosiveWave({
    double damage = 30,
    double force = 50,
    double radius = 800,
  }) {
    final wave = ExplosiveWave(
      position: position.clone(),
      damage: damage,
      knockbackForce: force,
      maxRadius: radius,
    );
    game.world.add(wave);
    debugPrint('ðŸŒŠ ON-OYABUN: ¡ONDA EXPLOSIVA ACTIVADA!');
  }

  void _aiPhase1(double distance) {
    if (target == null) {
      debugPrint('âš ï¸ Boss AI: No target');
      return;
    }

    // Fase 1: IA SIMPLE Y DIRECTA (estilo Hades/Isaac)
    const attackDistance = 100.0;

    if (distance > attackDistance) {
      // PERSEGUIR: Moverse directamente hacia el objetivo
      final direction = (target!.position - position).normalized();
      velocity = direction * currentSpeed;
      currentAction = 'moving';

      // Debug cada 2 segundos
      if ((aiTimer * 10).toInt() % 20 == 0) {
        final targetName = target is RedeemedKijinAlly ? 'Kohaa' : 'Player';
        debugPrint(
          'ðŸƒ Boss persiguiendo $targetName (${distance.toInt()}u) - Vel: ${velocity.length.toInt()}',
        );
      }
    } else {
      // EN RANGO: Detenerse y atacar
      velocity = Vector2.zero();
      currentAction = 'attacking';
      _tryBasicAttack();
    }
  }

  /// Ataque básico con la katana
  void _tryBasicAttack() {
    if (target == null) return;

    // Verificar cooldown de katana
    if (weaponCooldowns['katana']! > 0) return;

    final distance = position.distanceTo(target!.position);
    final katanaRange = weapons['katana']!.range;

    if (distance <= katanaRange) {
      // Atacar con katana
      final damage = weapons['katana']!.damage;

      if (target is PlayerCharacter) {
        (target as PlayerCharacter).takeDamage(damage);
        debugPrint(
          'âš”ï¸ Boss atacó a ${(target as PlayerCharacter).role == PlayerRole.mel ? "Mel" : "Dan"}: $damage daño',
        );
      } else if (target is RedeemedKijinAlly) {
        (target as RedeemedKijinAlly).takeDamage(damage);
        debugPrint('âš”ï¸ Boss atacó a Kohaa aliada: $damage daño');
      }

      // Cooldown
      weaponCooldowns['katana'] = weapons['katana']!.cooldown;
    }
  }

  void _aiPhase2(double distance) {
    if (target == null) return;

    // Fase 2: MUY agresivo con 3 armas simultáneas + ataques especiales

    final healthPercent = health / maxHealth;

    // Prioridad -1: Grito de Guerra si HP < 50% (solo una vez)
    if (healthPercent < 0.5 && !hasUsedWarCry && warCryCooldown <= 0) {
      _executeWarCry();
      return;
    }

    // Prioridad 0: Onda de Curación si HP < 40% y está disponible
    if (healthPercent < 0.4 &&
        healingWaveCooldown <= 0 &&
        Random().nextDouble() < 0.5) {
      _executeHealingWave();
      return;
    }

    // Prioridad 1: Lluvia de Acero si está disponible (20% chance, más frecuente)
    if (lluviaAceroCooldown <= 0 && Random().nextDouble() < 0.20) {
      _ejecutarLluviaAcero();
      return;
    }

    // Prioridad 2: Cadena de Culpa si objetivo está lejos (30% chance, más frecuente)
    if (distance > 150 &&
        distance < 300 &&
        cadenaCulpaCooldown <= 0 &&
        Random().nextDouble() < 0.30) {
      _ejecutarCadenaCulpa();
      return;
    }

    // Comportamiento normal por distancia
    if (distance > 80) {
      // Sprint agresivo hacia el objetivo
      final direction = (target!.position - position).normalized();
      velocity = direction * currentSpeed * 1.6; // 60% más rápido en fase 2

      // Debug
      if (distance > 120) {
        final targetName = target is RedeemedKijinAlly
            ? 'KOHAA ALIADA'
            : 'JUGADOR';
        debugPrint(
          'ðŸƒðŸƒ Boss SPRINT hacia $targetName (${distance.toInt()}u)',
        );
      }
    } else if (distance > 50) {
      // Rango medio: Usar wakizashi o cadenas más frecuentemente
      velocity = Vector2.zero();
      final weapon = Random().nextBool() ? 'wakizashi' : 'cadenas';
      _attemptAttack(weapon);
    } else {
      // Rango corto: Combos de 2-3 armas (más frecuentes)
      velocity = Vector2.zero();
      if (Random().nextDouble() < 0.75) {
        // 75% chance de combo
        _executePhase2Combo();
      } else {
        // Ataque simple aleatorio
        final weapon = activeWeapons[Random().nextInt(activeWeapons.length)];
        _attemptAttack(weapon);
      }
    }
  }

  /// Ejecuta un combo de Fase 2 (2-3 armas seguidas)
  void _executePhase2Combo() {
    // Patrón 1: Katana â†’ Wakizashi (rápido)
    // Patrón 2: Katana â†’ Cadenas (control)
    // Patrón 3: Triple: Katana â†’ Wakizashi â†’ Cadenas

    final pattern = Random().nextInt(3);

    switch (pattern) {
      case 0: // Katana + Wakizashi
        _attemptAttack('katana');
        Future.delayed(const Duration(milliseconds: 400), () {
          _attemptAttack('wakizashi');
        });
        debugPrint('  Combo 2-armas: Katana â†’ Wakizashi');
        break;

      case 1: // Katana + Cadenas
        _attemptAttack('katana');
        Future.delayed(const Duration(milliseconds: 600), () {
          _attemptAttack('cadenas');
        });
        debugPrint('  Combo 2-armas: Katana â†’ Cadenas');
        break;

      case 2: // Triple
        _attemptAttack('katana');
        Future.delayed(const Duration(milliseconds: 350), () {
          _attemptAttack('wakizashi');
        });
        Future.delayed(const Duration(milliseconds: 800), () {
          _attemptAttack('cadenas');
        });
        debugPrint('  âš”ï¸ COMBO TRIPLE: Katana â†’ Wakizashi â†’ Cadenas');
        break;
    }
  }

  void _aiPhase3(PlayerCharacter player, double distance) {
    if (target == null) return;

    // Fase 3: BERSERKER total, extremadamente agresivo
    if (distance > 70) {
      // Acercarse MUY rápido
      final direction = (target!.position - position).normalized();
      velocity = direction * currentSpeed * 2.0; // 100% más rápido en fase 3

      // Debug
      if (distance > 100) {
        final targetName = target is RedeemedKijinAlly
            ? 'KOHAA ALIADA'
            : 'JUGADOR';
        debugPrint(
          'ðŸ”¥ðŸƒðŸ”¥ Boss BERSERKER hacia $targetName (${distance.toInt()}u)',
        );
      }
    } else {
      // Combos constantes de múltiples armas
      velocity = Vector2.zero();
      _executeRandomCombo();
    }
  }

  void _attemptAttack(String weaponName) {
    if (!weapons.containsKey(weaponName)) return;
    if (weaponCooldowns[weaponName]! > 0) return; // En cooldown
    if (target == null) return; // Sin objetivo

    final weapon = weapons[weaponName]!;
    final distance = position.distanceTo(target!.position);

    if (distance <= weapon.range) {
      _executeAttack(weaponName);
      weaponCooldowns[weaponName] = weapon.cooldown;
    }
  }

  void _executeAttack(String weaponName) {
    final weapon = weapons[weaponName]!;
    if (target == null) return;

    debugPrint(
      'âš”ï¸ On-Oyabun ataca con $weaponName (${weapon.damage} daño)',
    );

    // Por ahora, daño simple
    final distance = position.distanceTo(target!.position);
    if (distance <= weapon.range) {
      _dealDamageToTarget(target!, weapon.damage);
    }
  }

  /// Helper para aplicar daño al objetivo actual (jugador o Kohaa)
  void _dealDamageToTarget(PositionComponent target, double damage) {
    if (target is PlayerCharacter) {
      target.takeDamage(damage);
    } else if (target is RedeemedKijinAlly) {
      target.takeDamage(damage);
      debugPrint('ðŸ’¥ Boss dañó a Kohaa aliada: $damage daño');
    }
  }

  void _executeRandomCombo() {
    // Fase 3: Combo de 2-4 armas aleatorias
    final comboLength = Random().nextInt(3) + 2; // 2-4

    for (int i = 0; i < comboLength && i < activeWeapons.length; i++) {
      final weapon = activeWeapons[Random().nextInt(activeWeapons.length)];
      _attemptAttack(weapon);
    }
  }

  void _updateWeaponCooldowns(double dt) {
    for (final weaponName in weaponCooldowns.keys) {
      if (weaponCooldowns[weaponName]! > 0) {
        weaponCooldowns[weaponName] = weaponCooldowns[weaponName]! - dt;
      }
    }
  }

  // ==================== SISTEMA DE COMBOS (FASE 1) ====================

  /// Actualiza el combo en progreso
  void _updateCurrentCombo() {
    switch (currentCombo) {
      case 'sandangiri':
        _updateSanDanGiri();
        break;
      case 'tsuki':
        _updateTsuki();
        break;
      case 'tsubame':
        _updateTsubame();
        break;
      default:
        _endCombo();
    }
  }

  /// Termina el combo actual
  void _endCombo() {
    isPerformingCombo = false;
    currentCombo = '';
    comboStep = 0;
    comboTimer = 0.0;
  }

  // ==================== COMBO 1: SAN-DAN GIRI (Corte Triple) ====================
  // 3 cortes consecutivos: Horizontal derecho â†’ Horizontal izquierdo â†’ Vertical descendente
  // Daño total: 150 (50+50+50)

  void _updateSanDanGiri() {
    switch (comboStep) {
      case 0: // Inicialización
        debugPrint('   San-Dan Giri: Preparando...');
        comboStep = 1;
        comboTimer = 0.0;
        break;

      case 1: // Corte horizontal derecho (0.5s)
        if (comboTimer >= 0.5) {
          _performSlash(50, 80, 'horizontal_derecho');
          comboStep = 2;
          comboTimer = 0.0;
        }
        break;

      case 2: // Corte horizontal izquierdo (0.5s)
        if (comboTimer >= 0.5) {
          _performSlash(50, 80, 'horizontal_izquierdo');
          comboStep = 3;
          comboTimer = 0.0;
        }
        break;

      case 3: // Corte vertical descendente (0.7s)
        if (comboTimer >= 0.7) {
          _performSlash(50, 80, 'vertical');
          _endCombo();
        }
        break;
    }
  }

  // ==================== COMBO 2: TSUKI (Estocada Cargada) ====================
  // Preparación (1.2s invulnerable) â†’ Estocada ultra-rápida
  // Daño: 100 + knockback

  void _updateTsuki() {
    if (target == null) {
      _endCombo();
      return;
    }

    switch (comboStep) {
      case 0: // Inicialización - Entrar en postura de carga
        debugPrint('   Tsuki: Cargando... (INVULNERABLE)');
        isInvulnerable = true;
        invulnerabilityTimer = 1.2;
        comboStep = 1;
        comboTimer = 0.0;
        break;

      case 1: // Preparación (1.2s)
        if (comboTimer >= 1.2) {
          // Telegraph completado, ejecutar estocada
          final direction = (target!.position - position).normalized();
          velocity = direction * 300; // Ultra-rápido

          debugPrint('   âš¡ Tsuki: ¡ESTOCADA!');
          comboStep = 2;
          comboTimer = 0.0;
        }
        break;

      case 2: // Estocada (0.2s)
        // Verificar impacto durante el dash
        final distance = position.distanceTo(target!.position);
        if (distance <= 60) {
          _dealDamageToTarget(target!, 100);
          // Knockback
          final knockbackDir = (target!.position - position).normalized();
          target!.position += knockbackDir * 80;
          debugPrint('   ðŸ’¥ Tsuki conecta! +Knockback');
        }

        if (comboTimer >= 0.2) {
          velocity = Vector2.zero();
          comboStep = 3;
          comboTimer = 0.0;
        }
        break;

      case 3: // Recovery (si falló, vulnerable 2s)
        if (comboTimer >= 2.0) {
          tsukiCooldown = tsukiCooldownDuration;
          _endCombo();
        }
        break;
    }
  }

  // ==================== COMBO 3: TSUBAME GAESHI (Barrido 360Â°) ====================
  // Giro de 360Â° con katana extendida
  // Daño: 80 AOE (100 unidades)

  void _updateTsubame() {
    if (target == null) {
      _endCombo();
      return;
    }

    switch (comboStep) {
      case 0: // Inicialización - Telegraph
        debugPrint('   Tsubame Gaeshi: Preparando barrido...');
        comboStep = 1;
        comboTimer = 0.0;
        break;

      case 1: // Giro (1.0s)
        if (comboTimer >= 1.0) {
          // AOE damage al completar el giro - puede golpear a múltiples objetivos
          final player = game.player;
          if (!player.isDead) {
            final distPlayer = position.distanceTo(player.position);
            if (distPlayer <= 100) {
              player.takeDamage(80);
              final knockbackDir = (player.position - position).normalized();
              player.position += knockbackDir * 40;
              debugPrint('   ðŸŒ€ Tsubame Gaeshi golpea al jugador!');
            }
          }

          // También golpear a Kohaa ALIADA si está en rango
          game.world.children.query<RedeemedKijinAlly>().forEach((kohaa) {
            if (!kohaa.isDead && kohaa.kijinType == 'kohaa') {
              final distKohaa = position.distanceTo(kohaa.position);
              if (distKohaa <= 100) {
                kohaa.takeDamage(80);
                final knockbackDir = (kohaa.position - position).normalized();
                kohaa.position += knockbackDir * 40;
                debugPrint('   ðŸŒ€ Tsubame Gaeshi golpea a Kohaa!');
              }
            }
          });

          tsubameCooldown = tsubameCooldownDuration;
          _endCombo();
        }
        break;
    }
  }

  /// Ejecuta un slash/corte en dirección al objetivo (AOE)
  void _performSlash(double damage, double range, String direction) {
    debugPrint('   âš”ï¸ Ejecutando corte $direction (AOE: ${range}u)');

    bool hitSomething = false;

    // Dañar al jugador si está en rango
    final player = game.player;
    if (!player.isDead) {
      final distPlayer = position.distanceTo(player.position);
      if (distPlayer <= range) {
        player.takeDamage(damage);
        hitSomething = true;
        debugPrint('   ðŸ’¥ Corte $direction golpea al jugador!');
      }
    }

    // Dañar a Kohaa ALIADA si está en rango
    game.world.children.query<RedeemedKijinAlly>().forEach((kohaa) {
      if (!kohaa.isDead && kohaa.kijinType == 'kohaa') {
        final distKohaa = position.distanceTo(kohaa.position);
        if (distKohaa <= range) {
          kohaa.takeDamage(damage);
          hitSomething = true;
          debugPrint('   ðŸ’¥ Corte $direction golpea a Kohaa!');
        }
      }
    });

    if (!hitSomething) {
      debugPrint('   âš”ï¸ Corte $direction no golpea a nadie');
    }
  }

  // ==================== DUEL STANCE (Mecánica Especial) ====================
  // Preparación: 2.8s (invulnerable, telegraph visual)
  // Ventana de parry: 0.2s (jugador debe atacar para evitar)
  // Si falla parry: Golpe mortal 200 daño

  /// Actualiza el estado de Duel Stance
  void _updateDuelStance(double dt) {
    duelStanceTimer += dt;

    // Fase de carga (2.0s)
    if (duelStanceTimer < duelStanceChargeDuration) {
      // Telegraph visual - el jefe está preparando
      return;
    }

    // Ventana de parry (2.0s a 2.25s)
    if (duelStanceTimer < duelStanceChargeDuration + duelStanceParryWindow) {
      if (!duelStanceParryWindowActive) {
        duelStanceParryWindowActive = true;
        debugPrint('   âš¡ VENTANA DE PARRY ACTIVA (0.25s)!');
      }
      return;
    }

    // Ventana expiró - Ejecutar golpe mortal
    if (duelStanceParryWindowActive) {
      _executeDuelStanceStrike();
      _endDuelStance();
    }
  }

  /// Ejecuta el golpe del Duel Stance (AOE devastador)
  void _executeDuelStanceStrike() {
    debugPrint('   ðŸ’€ DUEL STANCE: ¡GOLPE MORTAL! (AOE 100u)');

    bool hitSomething = false;
    const double strikeRange = 100.0;
    const double strikeDamage = 200.0;

    // Dañar al jugador si está en rango
    final player = game.player;
    if (!player.isDead) {
      final distPlayer = position.distanceTo(player.position);
      if (distPlayer <= strikeRange) {
        player.takeDamage(strikeDamage);
        hitSomething = true;
        debugPrint(
          '   ðŸ’€ðŸ’¥ DUEL STANCE golpea al jugador! ($strikeDamage daño)',
        );
      }
    }

    // Dañar a Kohaa ALIADA si está en rango
    game.world.children.query<RedeemedKijinAlly>().forEach((kohaa) {
      if (!kohaa.isDead && kohaa.kijinType == 'kohaa') {
        final distKohaa = position.distanceTo(kohaa.position);
        if (distKohaa <= strikeRange) {
          kohaa.takeDamage(strikeDamage);
          hitSomething = true;
          debugPrint(
            '   ðŸ’€ðŸ’¥ DUEL STANCE golpea a Kohaa! ($strikeDamage daño)',
          );
        }
      }
    });

    if (!hitSomething) {
      debugPrint('   âš”ï¸ DUEL STANCE falla (nadie en rango)');
    }
  }

  /// Termina el Duel Stance
  void _endDuelStance() {
    inDuelStanceCharge = false;
    duelStanceParryWindowActive = false;
    duelStanceTimer = 0.0;
    duelStanceCooldown = duelStanceCooldownDuration;
    debugPrint('   Duel Stance finalizado. Cooldown: 10s');
  }

  /// Intenta interrumpir el Duel Stance (llamado cuando el jugador ataca)
  void interruptDuelStance() {
    if (!duelStanceParryWindowActive) return;

    // Parry exitoso!
    debugPrint('   âœ… PARRY EXITOSO! Duel Stance interrumpido');
    _endDuelStance();

    // Vulnerable durante 3 segundos como castigo
    isVulnerable = true;
  }

  // ==================== FANTASMAS YAKUZA ====================

  /// Spawn de Fantasmas Yakuza a 80% HP
  void _spawnYakuzaGhosts() {
    hasSpawnedYakuzaGhosts = true;

    debugPrint('ðŸ‘» ON-OYABUN INVOCA FANTASMAS YAKUZA!');

    // Flash rojo
    _createScreenFlash(color: Colors.red.withValues(alpha: 0.8));

    // Mostrar diálogo de invocación
    Future.delayed(const Duration(milliseconds: 200), () {
      _showYakuzaGhostsDialogue();
    });

    // Spawn 3 fantasmas alrededor del jefe
    final random = Random();
    for (int i = 0; i < 3; i++) {
      final angle = (i / 3) * 2 * pi;
      final distance = 120.0 + random.nextDouble() * 40;
      final x = position.x + cos(angle) * distance;
      final y = position.y + sin(angle) * distance;

      // Crear el fantasma
      final ghost = YakuzaGhost(position: Vector2(x, y));
      game.world.add(ghost);
      debugPrint('   âš°ï¸ Fantasma Yakuza spawneado en ($x, $y)');
    }
  }

  // ==================== ATAQUES ESPECIALES FASE 2 ====================

  /// CADENA DE CULPA - Arrastra al objetivo hacia el jefe
  void _ejecutarCadenaCulpa() {
    if (cadenaCulpaCooldown > 0) return;
    if (currentPhase != BossPhase.phase2) return;
    if (target == null) return;

    final distance = position.distanceTo(target!.position);

    if (distance > 300) return; // Fuera de rango

    cadenaCulpaCooldown = cadenaCulpaCooldownDuration;

    debugPrint('ðŸ”— CADENA DE CULPA!');

    // Daño inicial
    _dealDamageToTarget(target!, 20);

    // Arrastrar al objetivo hacia el jefe
    final direction = (position - target!.position).normalized();
    final pullDistance = 150.0;

    // Aplicar pull gradualmente
    for (int i = 0; i < 10; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (target != null) {
          target!.position += direction * (pullDistance / 10);
        }
      });
    }

    debugPrint('   â†ªï¸ Objetivo arrastrado hacia el jefe');

  }

  /// LLUVIA DE ACERO - 28 katanas caen del cielo
  void _ejecutarLluviaAcero() {
    if (lluviaAceroCooldown > 0) return;
    if (currentPhase != BossPhase.phase2) return;

    lluviaAceroCooldown = lluviaAceroCooldownDuration;

    debugPrint('âš”ï¸ LLUVIA DE ACERO - 28 KATANAS!');

    // Flash rojo brevísimo
    _createScreenFlash(color: Colors.red.withValues(alpha: 0.5));

    final random = Random();
    final player = game.player;

    // Spawn 28 katanas en posiciones aleatorias
    // Concentradas cerca del jugador pero con dispersión
    for (int i = 0; i < 28; i++) {
      Future.delayed(Duration(milliseconds: i * 80), () {
        // Posición aleatoria cerca del jugador
        final offsetX = (random.nextDouble() - 0.5) * 400;

        // Ajustar límites según el mapa
        double maxSpawnX = 1550.0;
        final exteriorMap = game.world.children
            .query<ExteriorMapLevel>()
            .firstOrNull;
        if (exteriorMap != null) {
          maxSpawnX = 1950.0; // Mapa exterior es más ancho
        }

        final spawnX = (player.position.x + offsetX).clamp(50.0, maxSpawnX);
        final spawnY = -50.0; // Arriba de la pantalla

        final katana = FallingKatana(
          position: Vector2(spawnX, spawnY),
          damage: 40.0,
          fallSpeed: 300.0 + random.nextDouble() * 100,
        );

        game.world.add(katana);
      });
    }

    debugPrint('   â˜” 28 katanas cayendo durante 2.2 segundos');
  }

  /// Spawn de Víctimas Espectrales a 50% HP (Fase 2)
  void _spawnVictimasEspectrales() {
    hasSpawnedVictimas = true;

    debugPrint('ðŸ‘» VÍCTIMAS ESPECTRALES APARECEN!');

    // Flash purpura
    _createScreenFlash(color: Colors.purple.withValues(alpha: 0.6));

    // Spawn 5 Fantasmas Yakuza (versión espectral)
    final random = Random();
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 300), () {
        final angle = (i / 5) * 2 * pi;
        final distance =
            300.0 + random.nextDouble() * 200; // Aumentado para mapa exterior
        final x = position.x + cos(angle) * distance;
        final y = position.y + sin(angle) * distance;

        final victima = YakuzaGhost(position: Vector2(x, y));
        game.world.add(victima);
        debugPrint('   âš°ï¸ Víctima Espectral spawneada en ($x, $y)');
      });
    }
  }

  /// Spawn de Katanas Flotantes a 40% HP (Fase 2)
  void _spawnKatanasFlotantes() {
    hasSpawnedKatanas = true;

    debugPrint('âš”ï¸ KATANAS FLOTANTES AUTÓNOMAS!');

    // Flash cyan
    _createScreenFlash(color: Colors.cyan.withValues(alpha: 0.6));

    // Spawn 6 Katanas Flotantes
    final random = Random();
    for (int i = 0; i < 6; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        final angle = (i / 6) * 2 * pi;
        final distance =
            350.0 + random.nextDouble() * 150; // Aumentado para mapa exterior
        final x = position.x + cos(angle) * distance;
        final y = position.y + sin(angle) * distance;

        final katana = FloatingKatana(position: Vector2(x, y));
        game.world.add(katana);
        debugPrint('   âš”ï¸ Katana flotante spawneada en ($x, $y)');
      });
    }
  }

  /// ONDA DE CURACIÓN - Boss se cura y daña/empuja a todos los enemigos cercanos
  void _executeHealingWave() {
    if (healingWaveCooldown > 0) return;

    debugPrint('ðŸŒŠðŸ’š ¡ON-OYABUN USA ONDA DE CURACIÓN!');
    debugPrint('   ðŸ’š Boss se cura ${healingWaveAmount.toInt()} HP');

    // Curarse
    final oldHealth = health;
    health = (health + healingWaveAmount).clamp(0.0, maxHealth);
    final healed = health - oldHealth;
    debugPrint(
      '   âœ¨ Boss curado: ${healed.toInt()} HP (${health.toInt()}/${maxHealth.toInt()})',
    );

    // Flash verde
    _createScreenFlash(color: Colors.green.withValues(alpha: 0.7));

    // Dañar y empujar al jugador
    final player = game.player;
    if (!player.isDead) {
      final distToPlayer = position.distanceTo(player.position);
      if (distToPlayer <= healingWaveRadius) {
        player.takeDamage(healingWaveDamage);

        // Empujar fuertemente
        final pushDir = (player.position - position).normalized();
        player.position += pushDir * healingWavePushForce;

        debugPrint(
          '   ðŸŒŠ Onda golpea al JUGADOR: ${healingWaveDamage.toInt()} daño + EMPUJE',
        );
      }
    }

    // Dañar y empujar a Kohaa aliada
    game.world.children.query<RedeemedKijinAlly>().forEach((kohaa) {
      if (!kohaa.isDead && kohaa.kijinType == 'kohaa') {
        final distToKohaa = position.distanceTo(kohaa.position);
        if (distToKohaa <= healingWaveRadius) {
          kohaa.takeDamage(healingWaveDamage);

          // Empujar
          final pushDir = (kohaa.position - position).normalized();
          kohaa.position += pushDir * healingWavePushForce;

          debugPrint(
            '   ðŸŒŠ Onda golpea a KOHAA ALIADA: ${healingWaveDamage.toInt()} daño + EMPUJE',
          );
        }
      }
    });

    // Dañar y empujar a enfermeros
    game.world.children.query<AlliedEnemy>().forEach((nurse) {
      if (!nurse.isDead) {
        final distToNurse = position.distanceTo(nurse.position);
        if (distToNurse <= healingWaveRadius) {
          nurse.takeDamage(healingWaveDamage);

          // Empujar
          final pushDir = (nurse.position - position).normalized();
          nurse.position += pushDir * healingWavePushForce;

          debugPrint(
            '   ðŸŒŠ Onda golpea a ENFERMERO: ${healingWaveDamage.toInt()} daño + EMPUJE',
          );
        }
      }
    });

    // Cooldown
    healingWaveCooldown = healingWaveCooldownDuration;
    debugPrint('   â±ï¸ Cooldown: ${healingWaveCooldownDuration.toInt()}s');
  }

  /// GRITO DE GUERRA - Boss invoca fantasmas y maldice a los aliados
  void _executeWarCry() {
    hasUsedWarCry = true;
    warCryCooldown = warCryCooldownDuration;

    debugPrint('âš”ï¸ðŸ‘»ðŸ’€ ¡ON-OYABUN USA GRITO DE GUERRA!');

    // Detener movimiento
    velocity = Vector2.zero();

    // Flash rojo oscuro
    _createScreenFlash(color: Colors.red.withValues(alpha: 0.9));

    // Diálogo del boss maldiciendo
    Future.delayed(const Duration(milliseconds: 300), () {
      _showWarCryDialogue();
    });

    // Spawn fantasmas después del diálogo
    Future.delayed(const Duration(milliseconds: 1500), () {
      _spawnWarCryGhosts();
    });
  }

  /// Muestra el diálogo de maldición del boss
  void _showWarCryDialogue() {
    final dialogue = DialogueSequence(
      id: 'oyabun_war_cry',
      dialogues: [
        const DialogueData(
          speakerName: 'On-Oyabun',
          text: '¡MALDITOS SEAN! ¡MIS HERMANOS CAÍDOS VENGARÁN MI HONOR!',
          type: DialogueType.normal,
        ),
        const DialogueData(
          speakerName: 'On-Oyabun',
          text: '¡QUE SUS ESPÍRITUS DEVOREN A TUS ALIADOS!',
          type: DialogueType.normal,
        ),
        const DialogueData(
          speakerName: 'On-Oyabun',
          text: '¡NADIE ESCAPA DE LA VENGANZA DEL CLAN!',
          type: DialogueType.normal,
        ),
      ],
      onComplete: () {
        debugPrint('ðŸ’€ Boss completó su maldición');
      },
    );

    DialogueOverlay.show(game.buildContext!, dialogue);
  }

  /// Spawn fantasmas del grito de guerra
  void _spawnWarCryGhosts() {
    debugPrint('ðŸ‘»ðŸ’€ ¡FANTASMAS DE LA VENGANZA APARECEN!');

    // Flash negro
    _createScreenFlash(color: Colors.black.withValues(alpha: 0.8));

    // Spawn fantasmas en círculo alrededor del boss
    for (int i = 0; i < warCryGhostCount; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        final angle = (i / warCryGhostCount) * 2 * pi;
        final distance =
            400.0; // Aumentado de 180 a 400 para encerrar al jugador en mapa grande
        final x = position.x + cos(angle) * distance;
        final y = position.y + sin(angle) * distance;

        final ghost = YakuzaGhost(position: Vector2(x, y));
        game.world.add(ghost);
        debugPrint('   ðŸ‘» Fantasma de venganza spawneado en ($x, $y)');
      });
    }

    debugPrint(
      '   ðŸ’€ $warCryGhostCount fantasmas invocados para destruir aliados',
    );
    debugPrint('   â±ï¸ Cooldown: ${warCryCooldownDuration.toInt()}s');
  }

  // ==================== DAÑO Y MUERTE ====================
  void takeDamage(double damage) {
    if (isDead || isInvulnerable) return;

    // Si recibe daño durante ventana de parry del Duel Stance, interrumpir
    if (duelStanceParryWindowActive) {
      interruptDuelStance();
      return; // No recibe daño, solo interrumpe
    }

    health -= damage;
    debugPrint('ðŸ’¥ On-Oyabun recibe $damage daño. HP: $health/$maxHealth');

    if (health <= 0) {
      health = 0;
      onDeath();
    }
  }

  void onDeath() {
    isDead = true;
    debugPrint(' On-Oyabun ha sido derrotado!');


    removeFromParent();
  }

  /// Reinicia el boss cuando el jugador reintenta después de morir
  void resetBoss() {
    debugPrint('ðŸ”„ Reiniciando On-Oyabun Boss...');

    // Reiniciar HP
    health = maxHealth;
    isDead = false;

    // Reiniciar fase
    currentPhase = BossPhase.phase1;
    hasTransitionedToPhase2 = false;
    hasTransitionedToPhase3 = false;
    honorableDeathAvailable = false;
    isKneeling = false;

    // Reiniciar armas
    activeWeapons = ['katana'];
    weaponCooldowns.forEach((key, value) {
      weaponCooldowns[key] = 0.0;
    });

    // Reiniciar cooldowns
    tsukiCooldown = 0.0;
    tsubameCooldown = 0.0;
    duelStanceCooldown = 0.0;
    cadenaCulpaCooldown = 0.0;
    lluviaAceroCooldown = 0.0;
    healingWaveCooldown = 0.0;
    warCryCooldown = 0.0;

    // Reiniciar flags
    hasSpawnedYakuzaGhosts = false;
    hasSpawnedVictimas = false;
    hasSpawnedKatanas = false;
    hasUsedWarCry = false;

    // Reiniciar velocidad
    currentSpeed = 150.0;
    velocity = Vector2.zero();

    // Reiniciar teletransportación
    _canTeleport = true;
    _teleportCooldown = 0.0;
    _consecutiveDistanceIncreases = 0;
    _previousDistanceToTarget = 0.0;
    _targetPositionHistory.clear();

    // Reiniciar posición (centro del mapa)
    position = Vector2(1500, 1500);

    debugPrint('âœ… Boss reiniciado completamente');
  }

  // ==================== COLISIONES ====================
  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // Colisión con jugador (daño de contacto)
    if (other is PlayerCharacter) {
      other.takeDamage(baseDamage * 0.5); // 50% daño de contacto
    }
    // Colisión con Kohaa ALIADA (daño de contacto)
    else if (other is RedeemedKijinAlly && other.kijinType == 'kohaa') {
      other.takeDamage(baseDamage * 0.5); // 50% daño de contacto
      debugPrint(
        'ðŸ’¥ Boss colisionó con Kohaa aliada: ${baseDamage * 0.5} daño',
      );
    }
  }

  // ==================== DIÁLOGOS Y EFECTOS ====================

  /// Crea un efecto de flash de pantalla
  void _createScreenFlash({Color? color}) {
    final flash = ScreenFlash(
      screenSize: Vector2(
        3000,
        3000,
      ), // Aumentado para cubrir todo el mapa exterior
      flashColor: color ?? Colors.white,
      duration: 0.6,
    );
    game.world.add(flash);
  }

  void _showYakuzaGhostsDialogue() {
    if (game.buildContext == null) return;

    game.pauseEngine();

    final isDan = game.player.role == PlayerRole.dan;

    final sequence = DialogueSequence(
      id: 'oyabun_yakuza_ghosts',
      dialogues: [
        const DialogueData(
          speakerName: 'On-Oyabun',
          text: 'Hermanos caídos... Levántense una vez más. Por el clan.',
        ),
        DialogueData(
          speakerName: isDan ? 'Dan' : 'Mel',
          text: isDan
              ? '¡Está invocando refuerzos! Mel, ¿puedes...?'
              : '¡Tres enemigos más! Dan, ten cuidado.',
          avatarPath: isDan
              ? 'assets/avatars/dialogue_icons/Dan_Dialogue.png'
              : 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
        ),
      ],
      onComplete: () {
        game.resumeEngine();
      },
    );

    DialogueOverlay.show(game.buildContext!, sequence);
  }

  /// Diálogo de transición a Fase 2
  void _showPhase2Dialogue() {
    if (game.buildContext == null) return;

    game.pauseEngine();

    final isDan = game.player.role == PlayerRole.dan;

    final sequence = DialogueSequence(
      id: 'oyabun_phase2',
      dialogues: [
        const DialogueData(
          speakerName: 'On-Oyabun',
          text: 'El código... ya no importa. Solo queda... LA MASACRE.',
        ),
        const DialogueData(
          speakerName: 'On-Oyabun',
          text:
              '*Desenvaina dos armas más* Veintitrés inocentes. Cinco guerreros. ¡TODOS GRITARON MI NOMBRE!',
        ),
        DialogueData(
          speakerName: isDan ? 'Mel' : 'Dan',
          text: isDan
              ? '¡Dan, está cambiando! Está usando múltiples armas ahora.'
              : 'Mel, se ha vuelto más agresivo. Mantente en guardia.',
          avatarPath: isDan
              ? 'assets/avatars/dialogue_icons/Mel_Dialogue.png'
              : 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
        ),
        DialogueData(
          speakerName: isDan ? 'Dan' : 'Mel',
          text: isDan
              ? 'Esto se puso serio. ¡Vamos!'
              : 'No podemos retroceder ahora. Adelante, Dan.',
          avatarPath: isDan
              ? 'assets/avatars/dialogue_icons/Dan_Dialogue.png'
              : 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
        ),
      ],
      onComplete: () {
        game.resumeEngine();
      },
    );

    DialogueOverlay.show(game.buildContext!, sequence);
  }

  /// Diálogo de transición a Fase 3
  void _showPhase3Dialogue() {
    if (game.buildContext == null) return;

    game.pauseEngine();

    final isDan = game.player.role == PlayerRole.dan;

    final sequence = DialogueSequence(
      id: 'oyabun_phase3',
      dialogues: [
        const DialogueData(speakerName: 'On-Oyabun', text: '...'),
        const DialogueData(
          speakerName: 'On-Oyabun',
          text: '*Clava su katana en su abdomen* Seppuku... Eterno...',
        ),
        const DialogueData(
          speakerName: 'On-Oyabun',
          text:
              'NO PUEDO MORIR. NO MEREZCO MORIR. ¡TODOS USTEDES MORIRÁN PRIMERO!',
        ),
        DialogueData(
          speakerName: isDan ? 'Dan' : 'Mel',
          text: isDan
              ? '¡Se está haciendo harakiri pero sigue vivo! ¿Qué clase de monstruo es?'
              : 'Imposible... está en modo berserker completo.',
          avatarPath: isDan
              ? 'assets/avatars/dialogue_icons/Dan_Dialogue.png'
              : 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
        ),
      ],
      onComplete: () {
        game.resumeEngine();
      },
    );

    DialogueOverlay.show(game.buildContext!, sequence);
  }
}

// ==================== ENUMS Y CONFIGS ====================
enum BossPhase {
  phase1, // El Código
  phase2, // La Masacre
  phase3, // Seppuku Eterno
}

class WeaponConfig {
  final double damage;
  final double range;
  final double cooldown;

  WeaponConfig({
    required this.damage,
    required this.range,
    required this.cooldown,
  });
}
