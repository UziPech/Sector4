import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../expediente_game.dart';
import '../player.dart';
import '../enemy_tomb.dart';
import 'allied_enemy.dart';
import 'redeemed_kijin_ally.dart';
import 'irracional.dart';
import '../bosses/on_oyabun_boss.dart';

/// Yurei Kohaa - Jefe Kijin (CategorÃ­a 2)
/// La Novia Escarlata - Un enemigo tÃ¡ctico y peligroso
class YureiKohaa extends PositionComponent
    with HasGameReference<ExpedienteKorinGame>, CollisionCallbacks {
  double _health;
  final double _maxHealth = 3000.0; // Â¡10x mÃ¡s resistente!
  final double _speed = 150.0;
  final double _damage = 25.0;
  final double _attackRange = 50.0;
  final double _attackCooldown = 1.2;
  double _attackTimer = 0.0;

  // Dash attack (MÃS FRECUENTE)
  final double _dashCooldown = 4.0; // Reducido de 5s a 4s
  double _dashTimer = 0.0;
  bool _isDashing = false;
  bool _isPreparingDash = false; // Nueva: preparaciÃ³n antes del dash
  final double _dashPreparationTime =
      0.8; // Tiempo de preparaciÃ³n (INVULNERABLE)
  double _dashPreparationTimer = 0.0;
  final double _dashDuration = 0.4; // DuraciÃ³n mÃ¡s larga
  double _dashTime = 0.0;
  Vector2 _dashDirection = Vector2.zero();
  final double _dashSpeed = 500.0; // MÃ¡s rÃ¡pido

  // ExplosiÃ³n defensiva (NUEVA HABILIDAD)
  final double _defensiveExplosionCooldown = 12.0; // Cooldown de 12 segundos
  double _defensiveExplosionTimer = 0.0;
  bool _canUseDefensiveExplosion = true;
  final double _defensiveExplosionThreshold = 0.3; // 30% HP

  // RegeneraciÃ³n de vida
  double _regenerationTimer = 0.0;

  // Sistema de huida cuando tiene poca vida
  bool _isFleeing = false;
  final double _fleeHealthThreshold = 0.15; // 15% HP (solo huye en emergencia)
  final double _fleeDistance = 300.0; // Distancia de huida
  double _fleeTimer = 0.0; // Timer para evitar huir indefinidamente
  final double _maxFleeTime = 4.0; // MÃ¡ximo 4s huyendo antes de volver
  Vector2? _fleeTargetPosition; // PosiciÃ³n objetivo al huir
  int _fleeCount = 0; // Contador de veces que ha huido
  final int _maxFleeCount = 2; // MÃ¡ximo 2 huidas por combate

  // Sistema de curaciÃ³n cuando estÃ¡ segura
  double _healingTimer = 0.0;
  final double _healingInterval = 3.0; // Curar cada 3s (mÃ¡s lento)
  final double _healingAmount = 30.0; // 30 HP por tick (reducido)
  final double _safeDistance = 250.0; // Distancia segura del peligro
  double _totalHealingReceived = 0.0; // Total curado
  final double _maxTotalHealing = 300.0; // MÃ¡ximo 300 HP de curaciÃ³n total

  // Spawn de enfermeros (a 50% HP)
  bool _hasSpawnedNurses = false;

  bool _isDead = false;
  PositionComponent? _currentTarget;

  static const double _size = 40.0;

  // Sistema de sprites
  SpriteAnimationComponent? _spriteComponent;
  late SpriteAnimation _idleAnimation;
  late SpriteAnimation _walkAnimation;

  // Cached TextPainters
  late TextPainter _bossNamePainter;
  TextPainter? _statusTextPainter;
  String _lastStatusText = '';
  Color _lastStatusColor = Colors.transparent;

  // PERFORMANCE: Cached Paint objects
  late final Paint _auraPaint;
  late final Paint _bodyPaint;
  late final Paint _borderPaint;
  late final Paint _healthBgPaint;
  late final Paint _healthBarPaint;

  YureiKohaa({required Vector2 position})
    : _health = 3000.0, // HP inicial MUY ALTO
      super(position: position);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(_size);
    anchor = Anchor.center;

    // Cargar spritesheet de Yurei Kohaa
    await _loadSprites();

    // Agregar hitbox
    add(CircleHitbox(radius: _size / 2, collisionType: CollisionType.passive));

    // Inicializar painter del nombre (es estÃ¡tico)
    _bossNamePainter = TextPainter(
      text: const TextSpan(
        text: 'YUREI KOHAA',
        style: TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // PERFORMANCE: Initialize Paint objects once
    _auraPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    _bodyPaint = Paint()
      ..color = const Color(0xFF8B0000).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    _borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    _healthBgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    _healthBarPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
  }

  /// Carga el spritesheet y configura las animaciones
  Future<void> _loadSprites() async {
    // Sprites eliminados temporalmente por limpieza de assets
    debugPrint(
      'âš ï¸ Sprites de Yurei Kohaa removidos. Usando fallback circular.',
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isDead) return;

    // Actualizar animaciÃ³n de sprites segÃºn estado
    if (_spriteComponent != null) {
      // Determinar animaciÃ³n segÃºn velocidad
      final velocity = _isDashing
          ? _dashDirection * _dashSpeed
          : (_currentTarget != null &&
                position.distanceTo(_currentTarget!.position) > _attackRange)
          ? (_currentTarget!.position - position).normalized() * _speed
          : Vector2.zero();

      if (velocity.length > 10) {
        _spriteComponent!.animation = _walkAnimation;
      } else {
        _spriteComponent!.animation = _idleAnimation;
      }
    }

    // Actualizar timers
    if (_attackTimer > 0) _attackTimer -= dt;
    if (_dashTimer > 0) _dashTimer -= dt;
    if (_defensiveExplosionTimer > 0) {
      _defensiveExplosionTimer -= dt;
      if (_defensiveExplosionTimer <= 0) {
        _canUseDefensiveExplosion = true;
      }
    }

    // LÃ³gica de preparaciÃ³n del dash (INVULNERABLE)
    if (_isPreparingDash) {
      _dashPreparationTimer += dt;
      if (_dashPreparationTimer >= _dashPreparationTime) {
        // Terminar preparaciÃ³n, ejecutar dash
        _isPreparingDash = false;
        _isDashing = true;
        _dashPreparationTimer = 0.0;
      }
      return; // No moverse durante preparaciÃ³n
    }

    // LÃ³gica de dash
    if (_isDashing) {
      _dashTime += dt;
      if (_dashTime >= _dashDuration) {
        _isDashing = false;
        _dashTime = 0.0;
      } else {
        // Moverse en la direcciÃ³n del dash
        final newPos = position + (_dashDirection * _dashSpeed * dt);

        // Aplicar lÃ­mites estrictos durante dash
        const double worldMinX = 150.0;
        const double worldMaxX = 2850.0;
        const double worldMinY = 150.0;
        const double worldMaxY = 2850.0;

        position.x = newPos.x.clamp(worldMinX, worldMaxX);
        position.y = newPos.y.clamp(worldMinY, worldMaxY);
        return; // No hacer IA normal durante el dash
      }
    }

    // RegeneraciÃ³n gradual
    if (_regenerationTimer > 0) {
      _regenerationTimer -= dt;
    }

    // Sistema de curaciÃ³n cuando estÃ¡ segura
    _updateHealing(dt);

    // IA: Decidir objetivo y atacar (o huir)
    _updateAI(dt);
  }

  void _updateAI(double dt) {
    // Actualizar objetivo (70% Dan, 30% Mel o aliados)
    if (_currentTarget == null || _targetIsDead()) {
      _findTarget();
    }

    if (_currentTarget == null) return;

    final distanceToTarget = position.distanceTo(_currentTarget!.position);
    final healthPercent = _health / _maxHealth;

    // COMPORTAMIENTO DE HUIDA cuando tiene poca vida
    // EXCEPTO si estÃ¡ luchando contra el boss final O si ya huyÃ³ muchas veces
    if (healthPercent <= _fleeHealthThreshold && !_isFleeing) {
      // NO huir si el objetivo es el boss final
      if (_currentTarget is OnOyabunBoss) {
      }
      // NO huir si ya alcanzÃ³ el lÃ­mite de huidas
      else if (_fleeCount >= _maxFleeCount) {
        // Solo imprimir una vez cada cierto tiempo o no imprimir
      }
      // Huir solo si aÃºn tiene huidas disponibles
      else {
        _isFleeing = true;
        _fleeTimer = 0.0;
        _fleeCount++;
        _fleeTargetPosition = null; // Resetear posiciÃ³n objetivo
      }
    }

    // Dejar de huir cuando se recupera O cuando pasa mucho tiempo
    if (_isFleeing) {
      _fleeTimer += dt;

      // Condiciones para dejar de huir:
      // 1. Se recuperÃ³ suficiente HP
      // 2. PasÃ³ el tiempo mÃ¡ximo de huida
      if (healthPercent > _fleeHealthThreshold + 0.15 ||
          _fleeTimer >= _maxFleeTime) {
        _isFleeing = false;
        _fleeTargetPosition = null;
        _fleeTimer = 0.0;
      }
    }

    // Si estÃ¡ huyendo, usar lÃ³gica inteligente
    if (_isFleeing) {
      _updateFleeingBehavior(dt, distanceToTarget);
      return;
    }

    // COMPORTAMIENTO NORMAL: Atacar
    // Intentar dash si estÃ¡ listo (RANGO MÃS AMPLIO)
    if (_dashTimer <= 0 && distanceToTarget > 80 && distanceToTarget < 400) {
      _executeDash();
      return;
    }

    // Moverse hacia el objetivo
    if (distanceToTarget > _attackRange) {
      final direction = (_currentTarget!.position - position).normalized();
      final newPos = position + (direction * _speed * dt);

      // Aplicar lÃ­mites estrictos
      const double worldMinX = 150.0;
      const double worldMaxX = 2850.0;
      const double worldMinY = 150.0;
      const double worldMaxY = 2850.0;

      position.x = newPos.x.clamp(worldMinX, worldMaxX);
      position.y = newPos.y.clamp(worldMinY, worldMaxY);
    } else {
      // Atacar si estÃ¡ en rango
      _tryAttack();
    }
  }

  /// Comportamiento inteligente de huida (evita esquinas, busca posiciones seguras)
  void _updateFleeingBehavior(double dt, double distanceToTarget) {
    if (_currentTarget == null) return;

    // DESHABILITAR HUIDA si estÃ¡ luchando contra el boss final
    // Esto la hace mortal y evita que sea invencible
    if (_currentTarget is OnOyabunBoss) {
      _isFleeing = false;
      _fleeTimer = 0.0;
      return;
    }

    // Si no tenemos posiciÃ³n objetivo o estamos cerca de ella, calcular nueva
    if (_fleeTargetPosition == null ||
        position.distanceTo(_fleeTargetPosition!) < 50) {
      _fleeTargetPosition = _calculateSafeFleePosition();
    }

    // Si estamos lo suficientemente lejos, quedarnos quietos y curar
    if (distanceToTarget >= _fleeDistance) {
      // Quieta, curÃ¡ndose
      _constrainToWorldBounds(); // Asegurar que estÃ¡ dentro de lÃ­mites
      return;
    }

    // Moverse hacia la posiciÃ³n segura
    if (_fleeTargetPosition != null) {
      final direction = (_fleeTargetPosition! - position).normalized();
      final newPos =
          position +
          (direction * _speed * dt * 1.3); // 30% mÃ¡s rÃ¡pido al huir

      // Aplicar lÃ­mites ANTES de mover
      const double worldMinX = 150.0;
      const double worldMaxX = 2850.0;
      const double worldMinY = 150.0;
      const double worldMaxY = 2850.0;

      position.x = newPos.x.clamp(worldMinX, worldMaxX);
      position.y = newPos.y.clamp(worldMinY, worldMaxY);
    }
  }

  /// Calcula una posiciÃ³n segura para huir (evita esquinas y bordes)
  Vector2 _calculateSafeFleePosition() {
    if (_currentTarget == null) return position.clone();

    // Centro del mapa (posiciÃ³n mÃ¡s segura)
    const double centerX = 1500.0;
    const double centerY = 1500.0;
    final mapCenter = Vector2(centerX, centerY);

    // Vector desde el peligro hacia nosotros
    final awayFromThreat = (position - _currentTarget!.position).normalized();

    // PosiciÃ³n ideal: lejos del peligro pero cerca del centro
    final idealPosition =
        _currentTarget!.position + (awayFromThreat * _fleeDistance);

    // Interpolar entre posiciÃ³n ideal y centro del mapa
    // Esto evita que se vaya a las esquinas
    final safePosition = idealPosition * 0.6 + mapCenter * 0.4;

    // Asegurar que estÃ¡ dentro de lÃ­mites
    return Vector2(
      safePosition.x.clamp(200.0, 2800.0),
      safePosition.y.clamp(200.0, 2800.0),
    );
  }

  /// Sistema de curaciÃ³n cuando estÃ¡ segura (con lÃ­mite total)
  void _updateHealing(double dt) {
    if (_isDead) return;

    // Solo curar si estÃ¡ huyendo o lejos del peligro
    bool isSafe = false;

    if (_isFleeing && _currentTarget != null) {
      final distanceToThreat = position.distanceTo(_currentTarget!.position);
      isSafe = distanceToThreat >= _safeDistance;
    }

    if (isSafe) {
      _healingTimer += dt;

      if (_healingTimer >= _healingInterval) {
        // Verificar si aÃºn puede curarse (lÃ­mite total)
        if (_totalHealingReceived >= _maxTotalHealing) {
          _healingTimer = 0.0;
          return;
        }

        final oldHealth = _health;
        final healAmount = _healingAmount.clamp(
          0.0,
          _maxTotalHealing - _totalHealingReceived,
        );
        _health = (_health + healAmount).clamp(0.0, _maxHealth);
        final healed = _health - oldHealth;

        if (healed > 0) {
          _totalHealingReceived += healed;
        }

        _healingTimer = 0.0;
      }
    } else {
      _healingTimer = 0.0; // Resetear timer si no estÃ¡ segura
    }
  }

  /// Restringe la posiciÃ³n a los lÃ­mites del mundo (con deslizamiento)
  void _constrainToWorldBounds() {
    const double worldMinX = 150.0; // Ajustado para coincidir con paredes
    const double worldMaxX = 2850.0;
    const double worldMinY = 150.0; // Ajustado para coincidir con paredes
    const double worldMaxY = 2850.0;

    // Solo aplicar lÃ­mites, sin modificar velocidad (permite deslizamiento natural)
    position.x = position.x.clamp(worldMinX, worldMaxX);
    position.y = position.y.clamp(worldMinY, worldMaxY);
  }

  void _findTarget() {
    final player = game.player;
    final random = Random();

    // OPTIMIZED: Use cached reference instead of query
    final boss = game.activeBoss;

    // Si existe el boss final, PRIORIDAD MÃXIMA (90% chance - mÃ¡s agresiva)
    if (boss != null && !boss.isDead && random.nextDouble() < 0.9) {
      _currentTarget = boss;
      if (_currentTarget != boss) {
        // Solo imprimir cuando cambia de objetivo
      }
      return;
    }

    // 60% perseguir a Dan, 40% a aliados
    if (random.nextDouble() < 0.6) {
      // Perseguir a Dan
      _currentTarget = player;
    } else {
      // OPTIMIZED: Use cached allies list
      if (game.allies.isNotEmpty) {
        _currentTarget =
            game.allies[random.nextInt(game.allies.length)]
                as PositionComponent;
      } else {
        _currentTarget = player; // Fallback a Dan
      }
    }
  }

  bool _targetIsDead() {
    if (_currentTarget is PlayerCharacter) {
      return (_currentTarget as PlayerCharacter).isDead;
    } else if (_currentTarget is AlliedEnemy) {
      return (_currentTarget as AlliedEnemy).isDead;
    } else if (_currentTarget is RedeemedKijinAlly) {
      return (_currentTarget as RedeemedKijinAlly).isDead;
    } else if (_currentTarget is OnOyabunBoss) {
      return (_currentTarget as OnOyabunBoss).isDead;
    }
    return true;
  }

  void _executeDash() {
    if (_currentTarget == null) return;

    // Iniciar PREPARACIÃ“N (fase invulnerable)
    _isPreparingDash = true;
    _dashPreparationTimer = 0.0;
    _dashTime = 0.0;
    _dashTimer = _dashCooldown;
    _dashDirection = (_currentTarget!.position - position).normalized();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // Solo hacer daÃ±o durante el dash
    if (!_isDashing) return;

    const double dashDamage = 50.0; // DaÃ±o del dash

    // ColisiÃ³n con jugador
    if (other is PlayerCharacter) {
      other.takeDamage(dashDamage);
    }
    // ColisiÃ³n con aliados normales
    else if (other is AlliedEnemy) {
      other.takeDamage(dashDamage);
    }
    // ColisiÃ³n con aliados Kijin
    else if (other is RedeemedKijinAlly) {
      other.takeDamage(dashDamage);
    }
    // ColisiÃ³n con el boss final
    else if (other is OnOyabunBoss) {
      other.takeDamage(dashDamage);
    }
  }

  void _tryAttack() {
    if (_attackTimer > 0 || _currentTarget == null) return;

    final distanceToTarget = position.distanceTo(_currentTarget!.position);
    if (distanceToTarget <= _attackRange) {
      _attack(_currentTarget!);
      _attackTimer = _attackCooldown;
    }
  }

  void _attack(PositionComponent target) {
    if (target is PlayerCharacter) {
      target.takeDamage(_damage);
    } else if (target is AlliedEnemy) {
      target.takeDamage(_damage);
    } else if (target is RedeemedKijinAlly) {
      target.takeDamage(_damage);
    } else if (target is OnOyabunBoss) {
      target.takeDamage(_damage);
    }
  }

  /// Recibe daÃ±o
  void takeDamage(double damage) {
    if (_isDead) return;

    // INVULNERABLE durante preparaciÃ³n del dash
    if (_isPreparingDash) {
      return;
    }

    _health -= damage;

    // NUEVA: ExplosiÃ³n defensiva cuando estÃ¡ baja de vida
    final healthPercent = _health / _maxHealth;
    if (healthPercent <= _defensiveExplosionThreshold &&
        _canUseDefensiveExplosion) {
      _executeDefensiveExplosion();
      _canUseDefensiveExplosion = false;
      _defensiveExplosionTimer = _defensiveExplosionCooldown;
    }

    // Spawn de enfermeros a 60% HP (MÃS TEMPRANO)
    if (!_hasSpawnedNurses && _health <= _maxHealth * 0.6) {
      _spawnNurses();
      _hasSpawnedNurses = true;
    }

    if (_health <= 0) {
      _health = 0;
      _die();
    }
  }

  /// NUEVA HABILIDAD: ExplosiÃ³n Defensiva
  /// Se activa cuando Kohaa estÃ¡ baja de vida (< 30%)
  void _executeDefensiveExplosion() {
    const double explosionRadius = 250.0;
    const double explosionDamage = 40.0;
    const double pushForce = 450.0;
    const double healAmount = 100.0;

    // CURARSE
    _health = (_health + healAmount).clamp(0.0, _maxHealth);

    // DaÃ±ar y empujar al jugador
    final player = game.player;
    final distToPlayer = position.distanceTo(player.position);
    if (distToPlayer <= explosionRadius) {
      player.takeDamage(explosionDamage);
      // EMPUJAR FUERTEMENTE
      final pushDirection = (player.position - position).normalized();
      player.position += pushDirection * pushForce * 0.15;
    }

    // DaÃ±ar y empujar aliados normales
    final normalAllies = game.world.children.query<AlliedEnemy>();
    for (final ally in normalAllies) {
      if (ally.isDead) continue;
      final distToAlly = position.distanceTo(ally.position);
      if (distToAlly <= explosionRadius) {
        ally.takeDamage(explosionDamage);
        final pushDirection = (ally.position - position).normalized();
        ally.position += pushDirection * pushForce * 0.2;
      }
    }

    // DaÃ±ar y empujar aliados Kijin
    final kijinAllies = game.world.children.query<RedeemedKijinAlly>();
    for (final ally in kijinAllies) {
      if (ally.isDead) continue;
      final distToAlly = position.distanceTo(ally.position);
      if (distToAlly <= explosionRadius) {
        ally.takeDamage(explosionDamage);
        final pushDirection = (ally.position - position).normalized();
        ally.position += pushDirection * pushForce * 0.2;
      }
    }
  }

  void _spawnNurses() {
    // ===== ATAQUE AOE DE FASE =====
    _executePhaseTransitionAOE();

    // REGENERAR VIDA al spawn de enfermeros (25% de HP max)
    final healAmount = _maxHealth * 0.25;
    _health = (_health + healAmount).clamp(0.0, _maxHealth);

    // Spawn 2 enfermeros
    for (int i = 0; i < 2; i++) {
      final offset = Vector2(
        (i == 0 ? -80 : 80),
        Random().nextDouble() * 60 - 30,
      );

      final nurse = IrrationalEnemy(
        position: position + offset,
        health: 30.0,
        speed: 110.0,
        damage: 8.0,
      );

      game.world.add(nurse);
    }
  }

  /// Ataque AOE al cambiar de fase - DaÃ±a y empuja
  void _executePhaseTransitionAOE() {
    const double aoeRadius = 200.0;
    const double aoeDamage = 30.0;
    const double pushForce = 300.0;

    // DaÃ±ar jugador si estÃ¡ cerca
    final player = game.player;
    final distToPlayer = position.distanceTo(player.position);
    if (distToPlayer <= aoeRadius) {
      player.takeDamage(aoeDamage);
      // Empujar jugador
      final pushDirection = (player.position - position).normalized();
      player.position += pushDirection * pushForce * 0.1; // PequeÃ±o empuje
    }

    // DaÃ±ar TODOS los aliados cercanos
    final normalAllies = game.world.children.query<AlliedEnemy>();
    for (final ally in normalAllies) {
      if (ally.isDead) continue;
      final distToAlly = position.distanceTo(ally.position);
      if (distToAlly <= aoeRadius) {
        ally.takeDamage(aoeDamage);
        // Empujar aliado
        final pushDirection = (ally.position - position).normalized();
        ally.position += pushDirection * pushForce * 0.15;
      }
    }

    // DaÃ±ar aliados Kijin cercanos
    final kijinAllies = game.world.children.query<RedeemedKijinAlly>();
    for (final ally in kijinAllies) {
      if (ally.isDead) continue;
      final distToAlly = position.distanceTo(ally.position);
      if (distToAlly <= aoeRadius) {
        ally.takeDamage(aoeDamage);
        // Empujar aliado Kijin
        final pushDirection = (ally.position - position).normalized();
        ally.position += pushDirection * pushForce * 0.15;
      }
    }
  }

  /// Recuperar vida al reintentar (recarga entre muertes del jugador)
  void recoverHealthOnRetry(double amount) {
    if (_isDead) return; // No recuperar si ya muriÃ³

    _health = (_health + amount).clamp(0.0, _maxHealth);
  }

  /// Muerte de Kohaa
  void _die() {
    _isDead = true;

    // Crear tumba especial ROJA para Kijin
    final tomb = EnemyTomb(
      position: position.clone(),
      enemyType: 'kijin_kohaa',
      lifetime: 10.0, // Mas tiempo que irracionales
    );
    game.world.add(tomb);

    // Remover este enemigo
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Aura roja para Kijin (MANTENER) - using cached paint
    canvas.drawCircle((size / 2).toOffset(), _size / 2 + 8, _auraPaint);

    // FALLBACK: Si sprites no cargaron, dibujar cÃ­rculo
    if (_spriteComponent == null) {
      // Cuerpo de Kohaa (rojo oscuro) - FALLBACK
      canvas.drawCircle((size / 2).toOffset(), _size / 2, _bodyPaint);

      // Borde blanco brillante
      canvas.drawCircle((size / 2).toOffset(), _size / 2, _borderPaint);
    }

    // Indicador de HUIDA (verde pulsante)
    if (_isFleeing) {
      // Determinar texto segÃºn estado
      final healthPercent = _health / _maxHealth;
      String statusText;
      Color statusColor;

      if (healthPercent > _fleeHealthThreshold + 0.05) {
        statusText = 'ðŸ’š CURÃNDOSE';
        statusColor = Colors.lightGreen;
      } else {
        statusText = 'ðŸƒ HUYENDO';
        statusColor = Colors.green;
      }

      // Actualizar painter solo si cambia el texto o color
      if (statusText != _lastStatusText ||
          statusColor != _lastStatusColor ||
          _statusTextPainter == null) {
        _lastStatusText = statusText;
        _lastStatusColor = statusColor;
        _statusTextPainter = TextPainter(
          text: TextSpan(
            text: statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
      }

      // Dibujar texto cacheado
      if (_statusTextPainter != null) {
        _statusTextPainter!.paint(
          canvas,
          Offset((size.x - _statusTextPainter!.width) / 2, -50),
        );
      }
    } else {
      // Limpiar painter si no se usa para liberar memoria
      _statusTextPainter = null;
      _lastStatusText = '';
    }

    // Indicador de preparaciÃ³n (INVULNERABLE - dorado brillante)
    if (_isPreparingDash) {
      final preparePaint = Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

      canvas.drawCircle((size / 2).toOffset(), _size / 2 + 12, preparePaint);

      // Segundo anillo pulsante
      final pulse = (sin(_dashPreparationTimer * 10) * 0.5 + 0.5);
      final pulsePaint = Paint()
        ..color = Colors.white.withValues(alpha: pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle((size / 2).toOffset(), _size / 2 + 18, pulsePaint);
    }

    // Indicador de dash activo
    if (_isDashing) {
      final dashPaint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle((size / 2).toOffset(), _size / 2 + 10, dashPaint);
    }

    // Barra de vida
    _drawHealthBar(canvas);

    // Nombre del jefe
    _drawBossName(canvas);
  }

  void _drawHealthBar(Canvas canvas) {
    const barWidth = 80.0;
    const barHeight = 6.0;
    final barX = (size.x - barWidth) / 2;
    final barY = -20.0;

    // Fondo - using cached paint
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      _healthBgPaint,
    );

    // Vida - using cached paint
    final healthPercent = (_health / _maxHealth).clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth * healthPercent, barHeight),
      _healthBarPaint,
    );

    // Borde - using cached paint
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      _borderPaint,
    );
  }

  void _drawBossName(Canvas canvas) {
    _bossNamePainter.paint(
      canvas,
      Offset((size.x - _bossNamePainter.width) / 2, -35),
    );
  }

  /// Getters
  bool get isDead => _isDead;
  double get health => _health;
  double get healthPercent => _health / _maxHealth;
}
