import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../expediente_game.dart';
import '../../systems/resurrection_system.dart';
import '../enemy_tomb.dart';
import 'irracional.dart';
import 'allied_enemy.dart';
import 'yurei_kohaa.dart'; // Añadido para poder atacar a Kohaa
import '../bosses/on_oyabun_boss.dart'; // Para atacar a On-Oyabun
import 'minions/yakuza_ghost.dart'; // Para el llanto de Kohaa
import 'minions/floating_katana.dart'; // Para el llanto de Kohaa

/// Kijin Redimido - Aliado resucitado de categoría Kijin
/// NO expira por tiempo, solo por muerte
/// Más fuerte que aliados normales y con IA mejorada para evitar apilamiento
class RedeemedKijinAlly extends PositionComponent
    with HasGameReference<ExpedienteKorinGame>, CollisionCallbacks {
  late final double _maxHealth;
  late double _health;
  late final double _speed;
  late final double _damage;
  late final double _attackRange;
  late final double _attackCooldown;
  double _attackTimer = 0.0;

  // Dash attack (habilidad especial)
  final double _dashCooldown = 6.0; // Cooldown de dash
  double _dashTimer = 0.0;
  bool _isDashing = false;
  bool _isPreparingDash = false;
  final double _dashPreparationTime = 0.6;
  double _dashPreparationTimer = 0.0;
  final double _dashDuration = 0.3;
  double _dashTime = 0.0;
  Vector2 _dashDirection = Vector2.zero();
  final double _dashSpeed = 400.0;

  // Espaciamiento con otros aliados
  final double _separationRadius = 80.0;

  bool _isDead = false;
  PositionComponent? _currentTarget; // Cambiado para aceptar cualquier enemigo

  // Sistema táctico para Kohaa aliada
  bool _isRetreating = false;
  double _retreatTimer = 0.0;
  final double _retreatDuration = 8.0; // Retirarse por 8s para recuperarse
  final double _retreatHealthThreshold = 0.5; // Retirarse si HP < 50%
  double _retreatCooldown = 0.0;
  final double _retreatCooldownDuration = 30.0; // Cooldown de 30s entre huidas

  // Sistema de curación durante huida
  double _healingDuringRetreat = 0.0;
  final double _healingPerSecond = 15.0; // 15 HP/s durante huida
  final double _maxHealingDuringRetreat = 150.0; // Máximo 150 HP por huida

  // Explosión táctica (habilidad especial)
  final double _tacticalExplosionCooldown = 15.0;
  double _tacticalExplosionTimer = 0.0;
  final double _tacticalExplosionDamage = 100.0; // Daño significativo al boss
  final double _tacticalExplosionRadius = 150.0;

  // Llanto de Kohaa (ondas de dolor)
  double _cryingWaveCooldown = 0.0;
  final double _cryingWaveCooldownDuration = 20.0; // Cada 20 segundos
  final double _cryingWaveDamage = 100.0; // 100 daño
  final double _cryingWaveRadius = 200.0; // Radio de 200 unidades
  final double _cryingWaveHealthThreshold = 0.25; // Solo si HP < 25%

  // Referencia al manager de resurrecciones
  final ResurrectionManager? resurrectionManager;

  // Tipo de Kijin
  final String kijinType;

  // Spawn de enfermeros (a 50% HP)
  bool _hasSpawnedNurses = false;

  static const double _size = 35.0; // Más grande que aliados normales

  RedeemedKijinAlly({
    required Vector2 position,
    this.resurrectionManager,
    this.kijinType = 'kohaa',
  }) : super(position: position) {
    _configureStats();
  }

  /// Configura las estadísticas según el tipo de Kijin
  void _configureStats() {
    // Configuración según tipo
    if (kijinType == 'kohaa') {
      _maxHealth = 2000.0; // Kohaa aliada SUPER resistente para duelo épico
      _health = _maxHealth;
      _speed = 160.0; // Rápida
      _attackRange = 80.0;
      _attackCooldown = 1.2;
      _damage = 30.0; // Daño aumentado para duelo épico
    } else {
      _maxHealth = 100.0;
      _health = 100.0;
      _speed = 150.0;
      _damage = 25.0;
      _attackRange = 50.0;
      _attackCooldown = 0.9;
      _speed = 150.0;
      _damage = 25.0;
      _attackRange = 50.0;
      _attackCooldown = 0.9;
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(_size);
    anchor = Anchor.center;

    // Agregar hitbox
    add(CircleHitbox(radius: _size / 2, collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isDead) return;

    // Actualizar timers
    if (_attackTimer > 0) _attackTimer -= dt;
    if (_dashTimer > 0) _dashTimer -= dt;
    if (_tacticalExplosionTimer > 0) _tacticalExplosionTimer -= dt;
    if (_retreatTimer > 0) _retreatTimer -= dt;
    if (_retreatCooldown > 0) _retreatCooldown -= dt;
    if (_cryingWaveCooldown > 0) _cryingWaveCooldown -= dt;

    // Lógica de preparación del dash (INVULNERABLE)
    if (_isPreparingDash) {
      _dashPreparationTimer += dt;
      if (_dashPreparationTimer >= _dashPreparationTime) {
        _isPreparingDash = false;
        _isDashing = true;
        _dashPreparationTimer = 0.0;
        // [PERF] print('âš¡ ¡Kijin Redimido EMBISTE!');
      }
      return; // No moverse durante preparación
    }

    // Lógica de dash
    if (_isDashing) {
      _dashTime += dt;
      if (_dashTime >= _dashDuration) {
        _isDashing = false;
        _dashTime = 0.0;
      } else {
        final newPos = position + _dashDirection * _dashSpeed * dt;
        position = _constrainToWorldBounds(
          newPos,
        ); // Aplicar límites durante dash
        _damageEnemiesInPath();
        return;
      }
    }

    // IA mejorada: Buscar y atacar enemigos CON separación
    _findAndAttackEnemies(dt);
  }

  void _findAndAttackEnemies(double dt) {
    // TÁCTICA INTELIGENTE para Kohaa aliada
    if (kijinType == 'kohaa') {
      _smartKohaaTactics(dt);
      return;
    }

    // Comportamiento normal para otros Kijin
    if (_currentTarget == null || !_isTargetValid()) {
      _findNearestEnemy();
    }

    if (!_isTargetValid()) {
      _findNearestEnemy();
    }

    if (_currentTarget != null) {
      final distanceToTarget = position.distanceTo(_currentTarget!.position);

      // Intentar dash si está listo
      if (_dashTimer <= 0 && distanceToTarget > 100 && distanceToTarget < 300) {
        _executeDash();
        return;
      }

      // Acercarse si está lejos
      if (distanceToTarget > _attackRange) {
        Vector2 direction = (_currentTarget!.position - position).normalized();
        direction = _applySeparation(direction);
        final newPos = position + direction * _speed * dt;
        position = _constrainToWorldBounds(newPos); // Aplicar límites
      } else {
        _tryAttack();
      }
    }
  }

  /// IA táctica inteligente para Kohaa aliada
  void _smartKohaaTactics(double dt) {
    final healthPercent = _health / _maxHealth;

    // PRIORIDAD 0: Llanto de Kohaa si HP crítico
    if (healthPercent < _cryingWaveHealthThreshold &&
        _cryingWaveCooldown <= 0) {
      _executeCryingWave();
    }

    // PRIORIDAD 1: Retirarse si HP bajo y cooldown disponible
    if (healthPercent < _retreatHealthThreshold &&
        _retreatTimer <= 0 &&
        _retreatCooldown <= 0) {
      _isRetreating = true;
      _retreatTimer = _retreatDuration;
      _retreatCooldown = _retreatCooldownDuration;
      _healingDuringRetreat = 0.0; // Reset healing counter
      // [PERF] print('ðŸƒðŸ’¨ðŸ’š ¡Kohaa aliada HUYE del combate para recuperarse! (HP: ${(_health).toInt()}/${_maxHealth.toInt()})');
    }

    // Ejecutar retirada con curación
    if (_isRetreating && _retreatTimer > 0) {
      _executeRetreatWithHealing(dt);
      return;
    } else if (_retreatTimer <= 0 && _isRetreating) {
      _isRetreating = false;
      // [PERF] print('âœ… Kohaa aliada regresa al combate (HP: ${(_health).toInt()}/${_maxHealth.toInt()})');
    }

    // PRIORIDAD 2: Buscar objetivo
    if (_currentTarget == null || !_isTargetValid()) {
      _findNearestEnemy();
    }

    if (_currentTarget == null) return;

    final distanceToTarget = position.distanceTo(_currentTarget!.position);

    // PRIORIDAD 3: Explosión táctica si el boss está cerca
    if (_tacticalExplosionTimer <= 0) {
      _tryTacticalExplosion();
    }

    // PRIORIDAD 4: IA SIMPLE Y DIRECTA (estilo roguelike)
    if (_currentTarget is OnOyabunBoss) {
      const attackDistance = 80.0;

      if (distanceToTarget > attackDistance) {
        // PERSEGUIR: Moverse hacia el boss
        final direction = (_currentTarget!.position - position).normalized();
        final newPos = position + direction * _speed * dt;
        position = _constrainToWorldBounds(newPos);
      } else {
        // EN RANGO: Atacar
        _tryAttack();

        // Retroceder un poco después de atacar
        if (_attackTimer <= 0) {
          final awayDirection = (position - _currentTarget!.position)
              .normalized();
          final stepBack = position + awayDirection * 30.0;
          position = _constrainToWorldBounds(stepBack);
        }
      }
    } else {
      // Contra minions, comportamiento normal pero agresivo
      if (distanceToTarget > _attackRange) {
        Vector2 direction = (_currentTarget!.position - position).normalized();
        direction = _applySeparation(direction);
        final newPos = position + direction * _speed * dt;
        position = _constrainToWorldBounds(newPos); // Aplicar límites
      } else {
        _tryAttack();
      }
    }
  }

  /// Ejecuta la retirada táctica con curación
  void _executeRetreatWithHealing(double dt) {
    // Buscar el boss para alejarse de él
    final bosses = game.world.children.query<OnOyabunBoss>();
    Vector2 retreatDirection = Vector2.zero();

    for (final boss in bosses) {
      if (!boss.isDead) {
        // Alejarse del boss
        retreatDirection = (position - boss.position).normalized();
        break;
      }
    }

    // Si no hay boss, moverse hacia el centro (zona segura)
    if (retreatDirection == Vector2.zero()) {
      final center = Vector2(1500, 1500);
      retreatDirection = (center - position)
          .normalized(); // Hacia el centro, no alejarse
    }

    // Verificar si está cerca de los bordes y FORZAR hacia el centro
    const double safeMargin = 400.0; // Margen más grande
    const double dangerMargin = 300.0; // Zona de peligro
    final center = Vector2(1500, 1500);

    // Si está en zona de peligro, ir directamente al centro
    if (position.x < 250 + dangerMargin ||
        position.x > 2750 - dangerMargin ||
        position.y < 250 + dangerMargin ||
        position.y > 2750 - dangerMargin) {
      retreatDirection = (center - position).normalized();
      // [PERF] print('âš ï¸ Kohaa cerca del borde, huyendo al CENTRO');
    } else {
      // Si está cerca pero no en peligro, ajustar dirección
      if (position.x < 250 + safeMargin) {
        retreatDirection.x = retreatDirection.x
            .abs(); // Forzar hacia la derecha
      } else if (position.x > 2750 - safeMargin) {
        retreatDirection.x = -retreatDirection.x
            .abs(); // Forzar hacia la izquierda
      }

      if (position.y < 250 + safeMargin) {
        retreatDirection.y = retreatDirection.y.abs(); // Forzar hacia abajo
      } else if (position.y > 2750 - safeMargin) {
        retreatDirection.y = -retreatDirection.y.abs(); // Forzar hacia arriba
      }
    }

    // Moverse rápido en dirección de huida (controlada)
    final newPos =
        position +
        retreatDirection.normalized() *
            _speed *
            dt *
            1.3; // Reducido de 1.5 a 1.3
    position = _constrainToWorldBounds(newPos); // Respetar límites del mundo

    // CURARSE mientras huye
    if (_healingDuringRetreat < _maxHealingDuringRetreat) {
      final healAmount = _healingPerSecond * dt;
      final actualHeal = min(
        healAmount,
        _maxHealingDuringRetreat - _healingDuringRetreat,
      );

      _health = min(_health + actualHeal, _maxHealth);
      _healingDuringRetreat += actualHeal;

      // Debug cada segundo
      if (_retreatTimer.toInt() != (_retreatTimer + dt).toInt()) {
        // [PERF] print('ðŸ’š Kohaa curándose: +${actualHeal.toInt()} HP (${_health.toInt()}/${_maxHealth.toInt()})');
      }
    }
  }

  void _executeDash() {
    if (_currentTarget == null) return;

    _isPreparingDash = true;
    _dashPreparationTimer = 0.0;
    _dashTime = 0.0;
    _dashTimer = _dashCooldown;
    _dashDirection = (_currentTarget!.position - position).normalized();

    // [PERF] print('ðŸ›¡ï¸ Kijin Redimido prepara dash (invulnerable)');
  }

  void _damageEnemiesInPath() {
    final dashDamage = _damage * 2.0; // Doble daño en dash
    const dashRadius = 40.0;

    // Dañar irracionales
    final irrationals = game.world.children.query<IrrationalEnemy>();
    for (final enemy in irrationals) {
      if (enemy.isDead) continue;
      final distance = position.distanceTo(enemy.position);
      if (distance <= dashRadius) {
        enemy.takeDamage(dashDamage);
        // [PERF] print('âš¡ Dash golpeó irracional: $dashDamage daño');
      }
    }

    // Dañar bosses
    final bosses = game.world.children.query<YureiKohaa>();
    for (final boss in bosses) {
      if (boss.isDead) continue;
      final distance = position.distanceTo(boss.position);
      if (distance <= dashRadius) {
        boss.takeDamage(dashDamage);
        // [PERF] print('âš¡ Dash golpeó a KOHAA: $dashDamage daño');
      }
    }

    final oyabuns = game.world.children.query<OnOyabunBoss>();
    for (final boss in oyabuns) {
      if (boss.isDead) continue;
      final distance = position.distanceTo(boss.position);
      if (distance <= dashRadius) {
        boss.takeDamage(dashDamage);
        // [PERF] print('âš¡ Dash golpeó a ON-OYABUN: $dashDamage daño');
      }
    }
  }

  bool _isTargetValid() {
    if (_currentTarget == null) return false;

    // Verificar si el objetivo sigue vivo según su tipo
    if (_currentTarget is IrrationalEnemy) {
      return !(_currentTarget as IrrationalEnemy).isDead;
    } else if (_currentTarget is YureiKohaa) {
      return !(_currentTarget as YureiKohaa).isDead;
    } else if (_currentTarget is OnOyabunBoss) {
      return !(_currentTarget as OnOyabunBoss).isDead;
    }

    return false;
  }

  /// Nueva función para evitar apilamiento con otros aliados
  Vector2 _applySeparation(Vector2 desiredDirection) {
    Vector2 separationForce = Vector2.zero();
    int neighborCount = 0;

    // Buscar todos los aliados cercanos
    final allAllies = <PositionComponent>[
      ...game.world.children.query<RedeemedKijinAlly>(),
      ...game.world.children.query<AlliedEnemy>(),
    ];

    for (final ally in allAllies) {
      if (ally == this) continue;

      final distance = position.distanceTo((ally).position);

      if (distance < _separationRadius && distance > 0) {
        // Fuerza de separación inversamente proporcional a la distancia
        final awayDirection = (position - ally.position).normalized();
        final strength = (1.0 - distance / _separationRadius);
        separationForce += awayDirection * strength;
        neighborCount++;
      }
    }

    if (neighborCount > 0) {
      separationForce = separationForce / neighborCount.toDouble();

      // Mezclar dirección deseada con fuerza de separación (70% objetivo, 30% separación)
      return (desiredDirection * 0.7 + separationForce * 0.3).normalized();
    }

    return desiredDirection;
  }

  void _findNearestEnemy() {
    // ESTRATEGIA TÁCTICA para Kohaa aliada
    if (kijinType == 'kohaa') {
      _findTacticalTarget();
      return;
    }

    // Comportamiento normal para otros Kijin
    final irrationals = game.world.children.query<IrrationalEnemy>();
    final bosses = game.world.children.query<YureiKohaa>();

    PositionComponent? nearest;
    double nearestDistance = double.infinity;

    // Buscar entre irracionales
    for (final enemy in irrationals) {
      if (enemy.isDead) continue;

      final distance = position.distanceTo(enemy.position);
      if (distance < nearestDistance) {
        nearest = enemy;
        nearestDistance = distance;
      }
    }

    // Buscar entre bosses (Kohaa y OnOyabun)
    for (final boss in bosses) {
      if (boss.isDead) continue;

      final distance = position.distanceTo(boss.position);
      if (distance < nearestDistance) {
        nearest = boss;
        nearestDistance = distance;
      }
    }

    final oyabuns = game.world.children.query<OnOyabunBoss>();
    for (final boss in oyabuns) {
      if (boss.isDead) continue;

      final distance = position.distanceTo(boss.position);
      if (distance < nearestDistance) {
        nearest = boss;
        nearestDistance = distance;
      }
    }

    _currentTarget = nearest;
  }

  /// Sistema táctico para Kohaa aliada - Prioriza minions sobre boss
  void _findTacticalTarget() {
    // Buscar minions del boss (Yakuza Ghosts y Floating Katanas)
    final minions = <PositionComponent>[];

    // Importar y buscar minions
    try {
      final ghosts = game.world.children.query<PositionComponent>().where(
        (c) =>
            c.runtimeType.toString().contains('YakuzaGhost') &&
            c is! RedeemedKijinAlly,
      );
      final katanas = game.world.children.query<PositionComponent>().where(
        (c) => c.runtimeType.toString().contains('FloatingKatana'),
      );

      minions.addAll(ghosts);
      minions.addAll(katanas);
    } catch (e) {
      // Si falla, usar targeting normal
    }

    // PRIORIDAD 1: Atacar minions si existen
    if (minions.isNotEmpty) {
      PositionComponent? nearestMinion;
      double nearestDistance = double.infinity;

      for (final minion in minions) {
        final distance = position.distanceTo(minion.position);
        if (distance < nearestDistance) {
          nearestMinion = minion;
          nearestDistance = distance;
        }
      }

      if (nearestMinion != null) {
        _currentTarget = nearestMinion;
        return;
      }
    }

    // PRIORIDAD 2: Si no hay minions, distraer al boss (pero con poco daño)
    final oyabuns = game.world.children.query<OnOyabunBoss>();
    for (final boss in oyabuns) {
      if (!boss.isDead) {
        _currentTarget = boss;
        // [PERF] print('ðŸŽ¯ Kohaa aliada: Distrayendo al boss');
        return;
      }
    }

    // PRIORIDAD 3: Atacar irracionales si no hay nada más
    final irrationals = game.world.children.query<IrrationalEnemy>();
    PositionComponent? nearest;
    double nearestDistance = double.infinity;

    for (final enemy in irrationals) {
      if (enemy.isDead) continue;
      final distance = position.distanceTo(enemy.position);
      if (distance < nearestDistance) {
        nearest = enemy;
        nearestDistance = distance;
      }
    }

    _currentTarget = nearest;
  }

  void _tryAttack() {
    if (_attackTimer > 0 || _currentTarget == null) return;

    // Atacar según el tipo de enemigo
    if (_currentTarget is IrrationalEnemy) {
      (_currentTarget as IrrationalEnemy).takeDamage(_damage);
      // [PERF] print('âš”ï¸ Kijin Redimido atacó Irracional: $_damage daño');
    } else if (_currentTarget is YureiKohaa) {
      (_currentTarget as YureiKohaa).takeDamage(_damage);
      // [PERF] print('âš”ï¸ Kijin Redimido atacó Kohaa: $_damage daño');
    } else if (_currentTarget is OnOyabunBoss) {
      (_currentTarget as OnOyabunBoss).takeDamage(_damage);
      // [PERF] print('âš”ï¸ Kijin Redimido atacó ON-OYABUN: $_damage daño');
    }

    _attackTimer = _attackCooldown;
  }

  /// Explosión táctica - Habilidad especial de Kohaa aliada
  void _tryTacticalExplosion() {
    // Buscar al boss
    final bosses = game.world.children.query<OnOyabunBoss>();

    for (final boss in bosses) {
      if (boss.isDead) continue;

      final distanceToBoss = position.distanceTo(boss.position);

      // Solo explotar si el boss está cerca
      if (distanceToBoss <= _tacticalExplosionRadius) {
        _executeTacticalExplosion(boss);
        break;
      }
    }
  }

  /// Ejecuta la explosión táctica
  void _executeTacticalExplosion(OnOyabunBoss boss) {
    // [PERF] print('ðŸ’¥ðŸ”¥ ¡KOHAA ALIADA USA EXPLOSIÓN TÁCTICA!');

    // Daño al boss
    boss.takeDamage(_tacticalExplosionDamage);
    // [PERF] print('   ðŸ’¥ Boss recibe ${_tacticalExplosionDamage.toInt()} daño de la explosión!');

    // Empujar al boss ligeramente
    final pushDirection = (boss.position - position).normalized();
    boss.position += pushDirection * 50; // Pequeño empuje

    // Cooldown
    _tacticalExplosionTimer = _tacticalExplosionCooldown;

    // [PERF] print('   ðŸŒŸ Onda expansiva de ${_tacticalExplosionRadius.toInt()} unidades');
    // [PERF] print('   â±ï¸ Cooldown: ${_tacticalExplosionCooldown.toInt()}s');
  }

  /// LLANTO DE KOHAA - Ondas de dolor que dañan a todos los enemigos
  void _executeCryingWave() {
    // [PERF] print('ðŸ˜­ðŸ’”ðŸŒŠ ¡LLANTO DE KOHAA! Ondas de dolor devastadoras');
    // [PERF] print('   ðŸ’” Kohaa llora por su dolor (HP: ${_health.toInt()}/${_maxHealth.toInt()})');

    // Dañar al boss
    game.world.children.query<OnOyabunBoss>().forEach((boss) {
      if (!boss.isDead) {
        final distance = position.distanceTo(boss.position);
        if (distance <= _cryingWaveRadius) {
          boss.takeDamage(_cryingWaveDamage);
          // [PERF] print('   ðŸŒŠ Onda golpea a ON-OYABUN: ${_cryingWaveDamage.toInt()} daño');
        }
      }
    });

    // Dañar a Yakuza Ghosts
    game.world.children.query<YakuzaGhost>().forEach((ghost) {
      if (!ghost.isDead) {
        final distance = position.distanceTo(ghost.position);
        if (distance <= _cryingWaveRadius) {
          ghost.takeDamage(_cryingWaveDamage);
        }
      }
    });

    // Dañar a Floating Katanas
    game.world.children.query<FloatingKatana>().forEach((katana) {
      if (!katana.isDead) {
        final distance = position.distanceTo(katana.position);
        if (distance <= _cryingWaveRadius) {
          katana.takeDamage(_cryingWaveDamage);
        }
      }
    });

    // Dañar a Irracionales
    game.world.children.query<IrrationalEnemy>().forEach((enemy) {
      if (!enemy.isDead) {
        final distance = position.distanceTo(enemy.position);
        if (distance <= _cryingWaveRadius) {
          enemy.takeDamage(_cryingWaveDamage);
        }
      }
    });

    // [PERF] print('   ðŸ’¥ ${enemiesHit} enemigos golpeados por las ondas');
    // [PERF] print('   â±ï¸ Cooldown: ${_cryingWaveCooldownDuration.toInt()}s');

    // Cooldown
    _cryingWaveCooldown = _cryingWaveCooldownDuration;
  }

  /// Recibe daño (puede ser atacado por otros enemigos)
  void takeDamage(double damage) {
    if (_isDead) return;

    // INVULNERABLE durante preparación del dash
    if (_isPreparingDash) {
      // [PERF] print('ðŸ›¡ï¸ ¡Kijin Redimido es INVULNERABLE! (Preparando dash)');
      return;
    }

    _health -= damage;

    // Spawn de enfermeros al 50% HP
    if (!_hasSpawnedNurses && _health <= _maxHealth * 0.5) {
      _spawnNurses();
      _hasSpawnedNurses = true;
      // [PERF] print('ðŸ©¸ ¡KIJIN REDIMIDO INVOCA ENFERMEROS AL 50% HP!');
    }

    if (_health <= 0) {
      _health = 0;
      _die();
    }
  }

  void _spawnNurses() {
    // [PERF] print('ðŸ©¸ ¡Kijin redimido invoca enfermeros para ayudar!');

    // Spawn 2 enfermeros ALIADOS
    for (int i = 0; i < 2; i++) {
      final offset = Vector2(
        (i == 0 ? -80 : 80),
        Random().nextDouble() * 60 - 30,
      );

      // Crear enfermero como aliado (SIN registrar slots - son parte del Kijin)
      final nurse = AlliedEnemy(
        position: position + offset,
        lifetime: 600.0, // 10 MINUTOS de duración (solo mueren por daño)
        resurrectionManager:
            null, // NO registrar en manager (son parte del Kijin)
        enemyType: 'irracional', // Usa stats predefinidas
      );

      game.world.add(nurse);
      // NO llamar a registerAlly() - los enfermeros son parte del Kijin, no slots separados
      // [PERF] print('ðŸ‘¥ Enfermero spawneado (10 min de duración, parte del Kijin)');
    }
  }

  /// Muerte del aliado
  void _die() {
    _isDead = true;
    _createTombOnDeath();
    // Liberar 2 slots en el manager (Kijin cuesta 2)
    resurrectionManager?.unregisterKijinAlly();
    removeFromParent();
  }

  /// Crea una tumba cuando el aliado muere
  void _createTombOnDeath() {
    final tomb = EnemyTomb(
      position: position.clone(),
      enemyType: 'redeemed_kijin',
      lifetime: 300.0, // 5 MINUTOS - Permite revivir múltiples veces
    );
    game.world.add(tomb);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Aura púrpura/rosa para indicar que es Kijin redimido
    final auraPaint = Paint()
      ..color = const Color(0xFFFF1493)
          .withValues(alpha: 0.3) // Deep pink
      ..style = PaintingStyle.fill;

    canvas.drawCircle((size / 2).toOffset(), _size / 2 + 7, auraPaint);

    // Indicador de preparación de dash (AMARILLO brillante)
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

    // Cuerpo del aliado (blanco puro)
    final bodyPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle((size / 2).toOffset(), _size / 2, bodyPaint);

    // Borde rosa brillante
    final borderPaint = Paint()
      ..color =
          const Color(0xFFFF69B4) // Hot pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle((size / 2).toOffset(), _size / 2, borderPaint);

    // Barra de vida
    _drawHealthBar(canvas);

    // Etiqueta "REDIMIDO"
    _drawRedeemedLabel(canvas);
  }

  void _drawHealthBar(Canvas canvas) {
    const barWidth = 50.0;
    const barHeight = 5.0;
    final barX = (size.x - barWidth) / 2;
    final barY = -15.0;

    // Fondo
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(barX, barY, barWidth, barHeight), bgPaint);

    // Vida
    final healthPercent = (_health / _maxHealth).clamp(0.0, 1.0);
    final healthPaint = Paint()
      ..color =
          const Color(0xFFFF69B4) // Hot pink
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth * healthPercent, barHeight),
      healthPaint,
    );
  }

  void _drawRedeemedLabel(Canvas canvas) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'REDIMIDA',
        style: TextStyle(
          color: Color(0xFFFF69B4),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset((size.x - textPainter.width) / 2, -28));
  }

  /// Limita la posición a los bordes del mundo (dinámico según tamaño del mapa)
  Vector2 _constrainToWorldBounds(Vector2 pos) {
    final worldSize = game.camera.visibleWorldRect;

    // Boss level (1600x1200)
    double worldMinX = 100.0;
    double worldMaxX = 1500.0;
    double worldMinY = 100.0;
    double worldMaxY = 1100.0;

    // Mapa grande (3000x3000)
    if (worldSize.width > 2000) {
      worldMinX = 250.0;
      worldMaxX = 2750.0;
      worldMinY = 250.0;
      worldMaxY = 2750.0;
    }

    final clampedPos = Vector2(
      pos.x.clamp(worldMinX, worldMaxX),
      pos.y.clamp(worldMinY, worldMaxY),
    );

    // Debug si se está saliendo
    if (pos.x != clampedPos.x || pos.y != clampedPos.y) {
      // [PERF] print('âš ï¸ Kohaa corregida: (${pos.x.toInt()}, ${pos.y.toInt()}) â†’ (${clampedPos.x.toInt()}, ${clampedPos.y.toInt()})');

      // Si está MUY cerca del borde, detener movimiento completamente
      if (pos.x < worldMinX + 50 ||
          pos.x > worldMaxX - 50 ||
          pos.y < worldMinY + 50 ||
          pos.y > worldMaxY - 50) {
        // [PERF] print('ðŸ›‘ Kohaa DETENIDA en el borde');
      }
    }

    return clampedPos;
  }

  /// Getters
  bool get isDead => _isDead;
  bool get isRetreating =>
      _isRetreating; // Para que el boss sepa si está huyendo
  double get health => _health;
}
