import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../expediente_game.dart';
import '../player.dart';
import '../enemies/yurei_kohaa.dart';
import '../enemies/minions/yakuza_ghost.dart';
import '../enemies/minions/floating_katana.dart';
import '../enemies/minions/falling_katana.dart';
import '../../../narrative/components/dialogue_system.dart';
import '../effects/screen_flash.dart';
import '../../../narrative/models/dialogue_data.dart';
import '../../models/player_role.dart';
/// 怨親分 ON-OYABUN - "El Padrino de la Venganza"
/// Singularidad (Categoría 3) - Jefe final del exterior
/// 
/// Fusión de víctima y verdugo, atrapado en un bucle eterno
/// de culpa y venganza. Líder del clan Kōga-gumi que ejecutó
/// la masacre del búnker y las 28 víctimas que se fusionaron con él.
class OnOyabunBoss extends PositionComponent 
    with CollisionCallbacks, HasGameReference<ExpedienteKorinGame> {
  
  // ==================== STATS BASE ====================
  final double maxHealth = 8000.0;
  double health = 8000.0;
  
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
  
  // Cooldowns de combos especiales
  double tsukiCooldown = 0.0;
  double tsubameCooldown = 0.0;
  final double tsukiCooldownDuration = 8.0;
  final double tsubameCooldownDuration = 6.0;
  
  // Duel Stance (mecánica especial)
  bool inDuelStanceCharge = false;
  double duelStanceTimer = 0.0;
  final double duelStanceChargeDuration = 2.8; // Preparación
  final double duelStanceParryWindow = 0.2; // Ventana de parry
  bool duelStanceParryWindowActive = false;
  double duelStanceCooldown = 0.0;
  final double duelStanceCooldownDuration = 15.0;
  
  // Fantasmas Yakuza (spawn a 80% HP)
  bool hasSpawnedYakuzaGhosts = false;
  
  // Ataques especiales Fase 2
  double cadenaCulpaCooldown = 0.0;
  final double cadenaCulpaCooldownDuration = 12.0;
  double lluviaAceroCooldown = 0.0;
  final double lluviaAceroCooldownDuration = 15.0;
  
  // Spawns adicionales Fase 2
  bool hasSpawnedVictimas = false; // 50% HP
  bool hasSpawnedKatanas = false;  // 40% HP
  
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
  
  // ==================== CONSTRUCTOR ====================
  OnOyabunBoss({
    required Vector2 position,
  }) : super(position: position, anchor: Anchor.center);
  
  // ==================== INICIALIZACIÓN ====================
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Tamaño del jefe (3 metros de alto, el doble del jugador)
    size = Vector2(60, 90); // Width x Height
    
    // Agregar hitbox circular
    add(RectangleHitbox(
      size: Vector2(60, 90),
      anchor: Anchor.center,
    ));
    
    // Inicializar cooldowns de armas
    for (final weaponName in weapons.keys) {
      weaponCooldowns[weaponName] = 0.0;
    }
    
    debugPrint('⚔️ On-Oyabun ha sido invocado! HP: $maxHealth');
  }
  
  /// Recibe daño de cualquier fuente
  // (Este método fue movido a la sección de DAÑO Y MUERTE más abajo)

  
  // ==================== UPDATE LOOP ====================
  @override
  void update(double dt) {
    super.update(dt);
    
    if (isDead) return;
    
    // Actualizar cooldowns de armas
    _updateWeaponCooldowns(dt);
    
    // Actualizar cooldowns de combos especiales
    if (tsukiCooldown > 0) tsukiCooldown -= dt;
    if (tsubameCooldown > 0) tsubameCooldown -= dt;
    if (duelStanceCooldown > 0) duelStanceCooldown -= dt;
    if (cadenaCulpaCooldown > 0) cadenaCulpaCooldown -= dt;
    if (lluviaAceroCooldown > 0) lluviaAceroCooldown -= dt;
    
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
    
    // IA del jefe (según la fase)
    if (!inDuelStance && !isKneeling) {
      aiTimer += dt;
      if (aiTimer >= aiUpdateInterval) {
        _updateAI();
        aiTimer = 0.0;
      }
    }
    
    // Actualizar posición basada en velocidad
    position += velocity * dt;
    
    // Reducir velocidad gradualmente (fricción)
    velocity *= 0.95;
  }
  
  // ==================== RENDER ====================
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Renderizar aura según fase
    _renderAura(canvas);
    
    // Renderizar cuerpo del jefe (placeholder)
    _renderBody(canvas);
    
    // Renderizar barra de HP (para testing)
    _renderHealthBar(canvas);
  }
  
  void _renderAura(Canvas canvas) {
    Color auraColor = Colors.red.withOpacity(0.3);
    double auraIntensity = 1.0;
    
    switch (currentPhase) {
      case BossPhase.phase1:
        auraColor = Colors.red.withOpacity(0.3);
        auraIntensity = 1.0;
        break;
      case BossPhase.phase2:
        auraColor = Colors.red.withOpacity(0.5);
        auraIntensity = 1.3;
        break;
      case BossPhase.phase3:
        auraColor = Colors.black.withOpacity(0.6);
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
  
  void _renderBody(Canvas canvas) {
    // Placeholder: Círculo grande rojo/negro según fase
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
    
    // Indicador de fase (pequeño texto)
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Fase ${currentPhase.index + 1}',
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(5, size.y - 15));
  }
  
  void _renderHealthBar(Canvas canvas) {
    final barWidth = size.x;
    final barHeight = 4.0;
    final hpPercent = (health / maxHealth).clamp(0.0, 1.0);
    
    // Fondo de la barra
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, -10, barWidth, barHeight),
      bgPaint,
    );
    
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
    
    debugPrint('⚔️ On-Oyabun: FASE 2 - LA MASACRE');
    debugPrint('   Armas activas: ${activeWeapons.length}');
    
    // FLASH BLANCO DRAMÁTICO
    _createScreenFlash();
    
    // Pausar y mostrar diálogos de transición
    Future.delayed(const Duration(milliseconds: 300), () {
      _showPhase2Dialogue();
    });
  }
  
  void transitionToPhase3() {
    hasTransitionedToPhase3 = true;
    currentPhase = BossPhase.phase3;
    
    // Activar TODAS las armas (6) - Berserker
    activeWeapons = ['katana', 'wakizashi', 'tanto', 'pistola', 'cadenas', 'manos'];
    
    // Velocidad berserker
    currentSpeed = 150.0;
    
    debugPrint('⚔️💀 On-Oyabun: FASE 3 - SEPPUKU ETERNO');
    debugPrint('   Armas activas: ${activeWeapons.length} (TODAS)');
    
    // Flash negro + rojo
    _createScreenFlash(color: Colors.black.withOpacity(0.9));
    Future.delayed(const Duration(milliseconds: 300), () {
      _createScreenFlash(color: Colors.red);
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
    
    debugPrint('⚔️ On-Oyabun: ESTADO DE MUERTE HONORABLE');
    debugPrint('   El jugador tiene 30 segundos para decidir...');
    
    // TODO: Iniciar timer de 30 segundos
    // Fase 2: Agresivo con 3 armas simultáneas + ataques especiales
    
    // Prioridad 1: Lluvia de Acero si está disponible (15% chance)
    if (lluviaAceroCooldown <= 0 && Random().nextDouble() < 0.15) {
      _ejecutarLluviaAcero();
      return;
    }
    
    // Prioridad 2: Cadena de Culpa si jugador está lejos (20% chance)
    if (distance > 150 && distance < 300 && cadenaCulpaCooldown <= 0 && Random().nextDouble() < 0.20) {
      _ejecutarCadenaCulpa();
      return;
    }
    
    // Comportamiento normal por distancia
    if (distance > 150) {
      // Sprint hacia el jugador
      final direction = (player.position - position).normalized();
      velocity = direction * currentSpeed;
    } else if (distance > 80) {
      // Rango medio: Usar wakizashi o cadenas
      velocity = Vector2.zero();
      final weapon = Random().nextBool() ? 'wakizashi' : 'cadenas';
      _attemptAttack(weapon);
    } else {
      // Rango corto: Combos de 2-3 armas
      velocity = Vector2.zero();
      if (Random().nextDouble() < 0.6) {
        _executePhase2Combo();
      } else {
        // Ataque simple aleatorio
        final weapon = activeWeapons[Random().nextInt(activeWeapons.length)];
        _attemptAttack(weapon);
      }
    }
  }
  
  // ==================== IA Y COMBATE ====================
  void _updateAI() {
    _updateTarget();
    
    final dist = target != null ? position.distanceTo(target!.position) : double.infinity;
    
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
    
    // Buscar Kohaa
    YureiKohaa? kohaa;
    game.world.children.query<YureiKohaa>().forEach((k) {
      if (!k.isDead) kohaa = k;
    });
    
    // Decidir objetivo basado en distancia
    if (kohaa != null && !kohaa!.isDead) {
      final distToPlayer = player.isDead ? double.infinity : position.distanceTo(player.position);
      final distToKohaa = position.distanceTo(kohaa!.position);
      
      if (distToKohaa < distToPlayer) {
        target = kohaa;
      } else {
        target = player.isDead ? kohaa : player;
      }
    } else {
      target = player.isDead ? null : player;
    }
  }
  
  void _aiPhase1(double distance) {
    if (target == null) return;
    
    // Fase 1: Caminar lentamente hacia el objetivo y usar combos
    if (distance > weapons['katana']!.range + 30) {
      // Acercarse lentamente
      final direction = (target!.position - position).normalized();
      velocity = direction * currentSpeed;
    } else {
      // En rango: decidir qué combo/mecánica usar
      velocity = Vector2.zero();
      
      // Prioridad de mecánicas según cooldowns y distancia
      final random = Random().nextDouble();
      
      // 20% chance: Duel Stance (si está disponible)
      if (duelStanceCooldown <= 0 && random < 0.20) {
        _startDuelStance();
      }
      // 30% chance: Tsuki (estocada) si está a media distancia
      else if (distance > 60 && tsukiCooldown <= 0 && random < 0.50) {
        _startCombo('tsuki');
      }
      // 25% chance: Tsubame (AOE) si está cerca
      else if (distance <= 100 && tsubameCooldown <= 0 && random < 0.75) {
        _startCombo('tsubame');
      }
      // Por defecto: San-Dan Giri (combo triple)
      else {
        _startCombo('sandangiri');
      }
    }
  }
  
  void _aiPhase2(double distance) {
    if (target == null) return;
    
    // Fase 2: Agresivo con 3 armas simultáneas + ataques especiales
    
    // Prioridad 1: Lluvia de Acero si está disponible (15% chance)
    if (lluviaAceroCooldown <= 0 && Random().nextDouble() < 0.15) {
      _ejecutarLluviaAcero();
      return;
    }
    
    // Prioridad 2: Cadena de Culpa si objetivo está lejos (20% chance)
    if (distance > 150 && distance < 300 && cadenaCulpaCooldown <= 0 && Random().nextDouble() < 0.20) {
      _ejecutarCadenaCulpa();
      return;
    }
    
    // Comportamiento normal por distancia
    if (distance > 150) {
      // Sprint hacia el objetivo
      final direction = (target!.position - position).normalized();
      velocity = direction * currentSpeed;
    } else if (distance > 80) {
      // Rango medio: Usar wakizashi o cadenas
      velocity = Vector2.zero();
      final weapon = Random().nextBool() ? 'wakizashi' : 'cadenas';
      _attemptAttack(weapon);
    } else {
      // Rango corto: Combos de 2-3 armas
      velocity = Vector2.zero();
      if (Random().nextDouble() < 0.6) {
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
    // Patrón 1: Katana → Wakizashi (rápido)
    // Patrón 2: Katana → Cadenas (control)
    // Patrón 3: Triple: Katana → Wakizashi → Cadenas
    
    final pattern = Random().nextInt(3);
    
    switch (pattern) {
      case 0: // Katana + Wakizashi
        _attemptAttack('katana');
        Future.delayed(const Duration(milliseconds: 400), () {
          _attemptAttack('wakizashi');
        });
        debugPrint('  Combo 2-armas: Katana → Wakizashi');
        break;
        
      case 1: // Katana + Cadenas
        _attemptAttack('katana');
        Future.delayed(const Duration(milliseconds: 600), () {
          _attemptAttack('cadenas');
        });
        debugPrint('  Combo 2-armas: Katana → Cadenas');
        break;
        
      case 2: // Triple
        _attemptAttack('katana');
        Future.delayed(const Duration(milliseconds: 350), () {
          _attemptAttack('wakizashi');
        });
        Future.delayed(const Duration(milliseconds: 800), () {
          _attemptAttack('cadenas');
        });
        debugPrint('  ⚔️ COMBO TRIPLE: Katana → Wakizashi → Cadenas');
        break;
    }
  }
  
  void _aiPhase3(PlayerCharacter player, double distance) {
    // Fase 3: Berserker mode, combos aleatorios
    if (distance > 100) {
      // Acercarse rápido
      final direction = (player.position - position).normalized();
      velocity = direction * currentSpeed;
    } else {
      // Combos de múltiples armas
      _executeRandomCombo();
    }
  }
  
  void _attemptAttack(String weaponName) {
    if (!weapons.containsKey(weaponName)) return;
    if (weaponCooldowns[weaponName]! > 0) return; // En cooldown
    
    final weapon = weapons[weaponName]!;
    final player = game.player;
    final distance = position.distanceTo(player.position);
    
    if (distance <= weapon.range) {
      _executeAttack(weaponName);
      weaponCooldowns[weaponName] = weapon.cooldown;
    }
  }
  
  void _executeAttack(String weaponName) {
    final weapon = weapons[weaponName]!;
    final player = game.player;
    
    debugPrint('⚔️ On-Oyabun ataca con $weaponName (${weapon.damage} daño)');
    
    // TODO: Implementar cada tipo de ataque específico
    // Por ahora, daño simple
    final distance = position.distanceTo(player.position);
    if (distance <= weapon.range) {
      player.takeDamage(weapon.damage);
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
  
  /// Inicia un combo específico
  void _startCombo(String comboName) {
    if (isPerformingCombo) return; // Ya está en un combo
    
    isPerformingCombo = true;
    currentCombo = comboName;
    comboStep = 0;
    comboTimer = 0.0;
    velocity = Vector2.zero(); // Detenerse al iniciar combo
    
    debugPrint('⚔️ On-Oyabun inicia combo: $comboName');
  }
  
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
  // 3 cortes consecutivos: Horizontal derecho → Horizontal izquierdo → Vertical descendente
  // Daño total: 150 (50+50+50)
  
  void _updateSanDanGiri() {
    final player = game.player;
    
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
  // Preparación (1.2s invulnerable) → Estocada ultra-rápida
  // Daño: 100 + knockback
  
  void _updateTsuki() {
    final player = game.player;
    
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
          final direction = (player.position - position).normalized();
          velocity = direction * 300; // Ultra-rápido
          
          debugPrint('   ⚡ Tsuki: ¡ESTOCADA!');
          comboStep = 2;
          comboTimer = 0.0;
        }
        break;
        
      case 2: // Estocada (0.2s)
        // Verificar impacto durante el dash
        final distance = position.distanceTo(player.position);
        if (distance <= 60) {
          player.takeDamage(100);
          // Knockback
          final knockbackDir = (player.position - position).normalized();
          player.position += knockbackDir * 80;
          debugPrint('   💥 Tsuki conecta! +Knockback');
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
  
  // ==================== COMBO 3: TSUBAME GAESHI (Barrido 360°) ====================
  // Giro de 360° con katana extendida
  // Daño: 80 AOE (100 unidades)
  
  void _updateTsubame() {
    final player = game.player;
    
    switch (comboStep) {
      case 0: // Inicialización - Telegraph
        debugPrint('   Tsubame Gaeshi: Preparando barrido...');
        comboStep = 1;
        comboTimer = 0.0;
        break;
        
      case 1: // Giro (1.0s)
        if (comboTimer >= 1.0) {
          // AOE damage al completar el giro
          final distance = position.distanceTo(player.position);
          if (distance <= 100) {
            player.takeDamage(80);
            // Pequeño knockback
            final knockbackDir = (player.position - position).normalized();
            player.position += knockbackDir * 40;
            debugPrint('   🌀 Tsubame Gaeshi conecta!');
          }
          
          tsubameCooldown = tsubameCooldownDuration;
          _endCombo();
        }
        break;
    }
  }
  
  /// Ejecuta un slash/corte en dirección al jugador
  void _performSlash(double damage, double range, String direction) {
    final player = game.player;
    final distance = position.distanceTo(player.position);
    
    if (distance <= range) {
      player.takeDamage(damage);
      debugPrint('   ⚔️ Corte $direction conecta ($damage daño)');
    } else {
      debugPrint('   ⚔️ Corte $direction falla (jugador fuera de rango)');
    }
  }
  
  // ==================== DUEL STANCE (Mecánica Especial) ====================
  // Preparación: 2.8s (invulnerable, telegraph visual)
  // Ventana de parry: 0.2s (jugador debe atacar para evitar)
  // Si falla parry: Golpe mortal 200 daño
  
  /// Inicia el Duel Stance
  void _startDuelStance() {
    if (inDuelStanceCharge || duelStanceCooldown > 0) return;
    
    inDuelStanceCharge = true;
    duelStanceTimer = 0.0;
    duelStanceParryWindowActive = false;
    velocity = Vector2.zero();
    
    // Invulnerable durante carga
    isInvulnerable = true;
    invulnerabilityTimer = duelStanceChargeDuration;
    
    debugPrint('⚔️ DUEL STANCE INICIADO - 2.8s de carga');
  }
  
  /// Actualiza el estado de Duel Stance
  void _updateDuelStance(double dt) {
    duelStanceTimer += dt;
    
    // Fase de carga (2.8s)
    if (duelStanceTimer < duelStanceChargeDuration) {
      // Telegraph visual - el jefe está preparando
      // TODO: Agregar efecto visual de carga
      return;
    }
    
    // Ventana de parry (2.8s a 3.0s)
    if (duelStanceTimer < duelStanceChargeDuration + duelStanceParryWindow) {
      if (!duelStanceParryWindowActive) {
        duelStanceParryWindowActive = true;
        debugPrint('   ⚡ VENTANA DE PARRY ACTIVA (0.2s)!');
        // TODO: Efecto visual de ventana de parry
      }
      return;
    }
    
    // Ventana expiró - Ejecutar golpe mortal
    if (duelStanceParryWindowActive) {
      _executeDuelStanceStrike();
      _endDuelStance();
    }
  }
  
  /// Ejecuta el golpe del Duel Stance
  void _executeDuelStanceStrike() {
    final player = game.player;
    final distance = position.distanceTo(player.position);
    
    if (distance <= 100) {
      player.takeDamage(200); // Golpe devastador
      debugPrint('   💀 DUEL STANCE: Golpe mortal conecta (200 daño)!');
    } else {
      debugPrint('   ⚔️ DUEL STANCE: Golpe falla (jugador lejos)');
    }
  }
  
  /// Termina el Duel Stance
  void _endDuelStance() {
    inDuelStanceCharge = false;
    duelStanceParryWindowActive = false;
    duelStanceTimer = 0.0;
    duelStanceCooldown = duelStanceCooldownDuration;
    debugPrint('   Duel Stance finalizado. Cooldown: 15s');
  }
  
  /// Intenta interrumpir el Duel Stance (llamado cuando el jugador ataca)
  void interruptDuelStance() {
    if (!duelStanceParryWindowActive) return;
    
    // Parry exitoso!
    debugPrint('   ✅ PARRY EXITOSO! Duel Stance interrumpido');
    _endDuelStance();
    
    // Vulnerable durante 3 segundos como castigo
    isVulnerable = true;
    // TODO: Aplicar stun o debuff temporal
  }
  
  // ==================== FANTASMAS YAKUZA ====================
  
  /// Spawn de Fantasmas Yakuza a 80% HP
  void _spawnYakuzaGhosts() {
    hasSpawnedYakuzaGhosts = true;
    
    debugPrint('👻 ON-OYABUN INVOCA FANTASMAS YAKUZA!');
    
    // Flash rojo
    _createScreenFlash(color: Colors.red.withOpacity(0.8));
    
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
      debugPrint('   ⚰️ Fantasma Yakuza spawneado en ($x, $y)');
    }
  }
  
  // ==================== ATAQUES ESPECIALES FASE 2 ====================
  
  /// CADENA DE CULPA - Arrastra al jugador hacia el jefe
  void _ejecutarCadenaCulpa() {
    if (cadenaCulpaCooldown > 0) return;
    if (currentPhase != BossPhase.phase2) return;
    
    final player = game.player;
    final distance = position.distanceTo(player.position);
    
    if (distance > 300) return; // Fuera de rango
    
    cadenaCulpaCooldown = cadenaCulpaCooldownDuration;
    
    debugPrint('🔗 CADENA DE CULPA!');
    
    // Daño inicial
    player.takeDamage(20);
    
    // Arrastrar al jugador hacia el jefe
    final direction = (position - player.position).normalized();
    final pullDistance = 150.0;
    
    // Aplicar pull gradualmente
    for (int i = 0; i < 10; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        player.position += direction * (pullDistance / 10);
      });
    }
    
    debugPrint('   ↪️ Jugador arrastrado hacia el jefe');
    
    // TODO: Efecto visual de cadenas
  }
  
  /// LLUVIA DE ACERO - 28 katanas caen del cielo
  void _ejecutarLluviaAcero() {
    if (lluviaAceroCooldown > 0) return;
    if (currentPhase != BossPhase.phase2) return;
    
    lluviaAceroCooldown = lluviaAceroCooldownDuration;
    
    debugPrint('⚔️ LLUVIA DE ACERO - 28 KATANAS!');
    
    // Flash rojo brevísimo
    _createScreenFlash(color: Colors.red.withOpacity(0.5));
    
    final random = Random();
    final player = game.player;
    
    // Spawn 28 katanas en posiciones aleatorias
    // Concentradas cerca del jugador pero con dispersión
    for (int i = 0; i < 28; i++) {
      Future.delayed(Duration(milliseconds: i * 80), () {
        // Posición aleatoria cerca del jugador
        final offsetX = (random.nextDouble() - 0.5) * 400;
        final offsetY = (random.nextDouble() - 0.5) * 400;
        final spawnX = (player.position.x + offsetX).clamp(50.0, 1550.0);
        final spawnY = -50.0; // Arriba de la pantalla
        
        final katana = FallingKatana(
          position: Vector2(spawnX, spawnY),
          damage: 40.0,
          fallSpeed: 300.0 + random.nextDouble() * 100,
        );
        
        game.world.add(katana);
      });
    }
    
    debugPrint('   ☔ 28 katanas cayendo durante 2.2 segundos');
  }
  
  /// Spawn de Víctimas Espectrales a 50% HP (Fase 2)
  void _spawnVictimasEspectrales() {
    hasSpawnedVictimas = true;
    
    debugPrint('👻 VÍCTIMAS ESPECTRALES APARECEN!');
    
    // Flash purpura
    _createScreenFlash(color: Colors.purple.withOpacity(0.6));
    
    // Spawn 5 Fantasmas Yakuza (versión espectral)
    final random = Random();
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 300), () {
        final angle = (i / 5) * 2 * pi;
        final distance = 150.0 + random.nextDouble() * 50;
        final x = position.x + cos(angle) * distance;
        final y = position.y + sin(angle) * distance;
        
        final victima = YakuzaGhost(position: Vector2(x, y));
        game.world.add(victima);
        debugPrint('   ⚰️ Víctima Espectral spawneada en ($x, $y)');
      });
    }
  }
  
  /// Spawn de Katanas Flotantes a 40% HP (Fase 2)
  void _spawnKatanasFlotantes() {
    hasSpawnedKatanas = true;
    
    debugPrint('⚔️ KATANAS FLOTANTES AUTÓNOMAS!');
    
    // Flash cyan
    _createScreenFlash(color: Colors.cyan.withOpacity(0.6));
    
    // Spawn 6 Katanas Flotantes
    final random = Random();
    for (int i = 0; i < 6; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        final angle = (i / 6) * 2 * pi;
        final distance = 180.0 + random.nextDouble() * 60;
        final x = position.x + cos(angle) * distance;
        final y = position.y + sin(angle) * distance;
        
        final katana = FloatingKatana(position: Vector2(x, y));
        game.world.add(katana);
        debugPrint('   ⚔️ Katana flotante spawneada en ($x, $y)');
      });
    }
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
    debugPrint('💥 On-Oyabun recibe $damage daño. HP: $health/$maxHealth');
    
    if (health <= 0) {
      health = 0;
      onDeath();
    }
  }
  
  void onDeath() {
    isDead = true;
    debugPrint('💀 On-Oyabun ha sido derrotado!');
    
    // TODO: Animación de muerte
    // TODO: Drops
    // TODO: Tumba (dorada si fue honorable, normal si no)
    
    removeFromParent();
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
  }
  
  // ==================== DIÁLOGOS Y EFECTOS ====================
  
  /// Crea un efecto de flash de pantalla
  void _createScreenFlash({Color? color}) {
    final flash = ScreenFlash(
      screenSize: Vector2(1600, 1200), // Tamaño del mapa
      flashColor: color ?? Colors.white,
      duration: 0.6,
    );
    game.world.add(flash);
  }
  
  /// Diálogo cuando spawnea Fantasmas Yakuza
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
          text: '*Desenvaina dos armas más* Veintitrés inocentes. Cinco guerreros. ¡TODOS GRITARON MI NOMBRE!',
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
        const DialogueData(
          speakerName: 'On-Oyabun',
          text: '...',
        ),
        const DialogueData(
          speakerName: 'On-Oyabun',
          text: '*Clava su katana en su abdomen* Seppuku... Eterno...',
        ),
        const DialogueData(
          speakerName: 'On-Oyabun',
          text: 'NO PUEDO MORIR. NO MEREZCO MORIR. ¡TODOS USTEDES MORIRÁN PRIMERO!',
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


