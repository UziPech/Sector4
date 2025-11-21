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

/// Yurei Kohaa - Jefe Kijin (Categoría 2)
/// La Novia Escarlata - Un enemigo táctico y peligroso
class YureiKohaa extends PositionComponent
    with HasGameReference<ExpedienteKorinGame>, CollisionCallbacks {
  
  double _health;
  final double _maxHealth = 3000.0; // ¡10x más resistente!
  final double _speed = 150.0;
  final double _damage = 25.0;
  final double _attackRange = 50.0;
  final double _attackCooldown = 1.2;
  double _attackTimer = 0.0;
  
  // Dash attack (MÁS FRECUENTE)
  final double _dashCooldown = 4.0; // Reducido de 5s a 4s
  double _dashTimer = 0.0;
  bool _isDashing = false;
  bool _isPreparingDash = false; // Nueva: preparación antes del dash
  double _dashPreparationTime = 0.8; // Tiempo de preparación (INVULNERABLE)
  double _dashPreparationTimer = 0.0;
  double _dashDuration = 0.4; // Duración más larga
  double _dashTime = 0.0;
  Vector2 _dashDirection = Vector2.zero();
  final double _dashSpeed = 500.0; // Más rápido
  
  // Explosión defensiva (NUEVA HABILIDAD)
  final double _defensiveExplosionCooldown = 12.0; // Cooldown de 12 segundos
  double _defensiveExplosionTimer = 0.0;
  bool _canUseDefensiveExplosion = true;
  final double _defensiveExplosionThreshold = 0.3; // 30% HP
  
  // Regeneración de vida
  bool _canRegenerate = true;
  double _regenerationCooldown = 15.0;
  double _regenerationTimer = 0.0;
  
  // Spawn de enfermeros (a 50% HP)
  bool _hasSpawnedNurses = false;
  
  bool _isDead = false;
  PositionComponent? _currentTarget;
  
  static const double _size = 40.0;
  
  YureiKohaa({
    required Vector2 position,
  })  : _health = 3000.0, // HP inicial MUY ALTO
        super(position: position);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(_size);
    anchor = Anchor.center;
    
    // Agregar hitbox
    add(CircleHitbox(
      radius: _size / 2,
      collisionType: CollisionType.passive,
    ));
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (_isDead) return;
    
    // Actualizar timers
    if (_attackTimer > 0) _attackTimer -= dt;
    if (_dashTimer > 0) _dashTimer -= dt;
    if (_defensiveExplosionTimer > 0) {
      _defensiveExplosionTimer -= dt;
      if (_defensiveExplosionTimer <= 0) {
        _canUseDefensiveExplosion = true;
      }
    }
    
    // Lógica de preparación del dash (INVULNERABLE)
    if (_isPreparingDash) {
      _dashPreparationTimer += dt;
      if (_dashPreparationTimer >= _dashPreparationTime) {
        // Terminar preparación, ejecutar dash
        _isPreparingDash = false;
        _isDashing = true;
        _dashPreparationTimer = 0.0;
        print('⚡ ¡Kohaa EMBISTE con furia!');
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
        // Moverse en la dirección del dash
        position += _dashDirection * _dashSpeed * dt;
        return; // No hacer IA normal durante el dash
      }
    }
    
    // Regeneración gradual
    if (_regenerationTimer > 0) {
      _regenerationTimer -= dt;
    }
    
    // IA: Decidir objetivo y atacar
    _updateAI(dt);
  }
  
  void _updateAI(double dt) {
    // Actualizar objetivo (70% Dan, 30% Mel o aliados)
    if (_currentTarget == null || _targetIsDead()) {
      _findTarget();
    }
    
    if (_currentTarget == null) return;
    
    final distanceToTarget = position.distanceTo(_currentTarget!.position);
    
    // Intentar dash si está listo (RANGO MÁS AMPLIO)
    if (_dashTimer <= 0 && distanceToTarget > 80 && distanceToTarget < 400) {
      _executeDash();
      return;
    }
    
    // Moverse hacia el objetivo
    if (distanceToTarget > _attackRange) {
      final direction = (_currentTarget!.position - position).normalized();
      position += direction * _speed * dt;
    } else {
      // Atacar si está en rango
      _tryAttack();
    }
  }
  
  void _findTarget() {
    // 60% perseguir a Dan, 40% a aliados
    final player = game.player;
    final random = Random();
    
    if (random.nextDouble() < 0.6) {
      // Perseguir a Dan
      _currentTarget = player;
    } else {
      // Buscar aliados (normales o Kijin)
      final normalAllies = game.world.children.query<AlliedEnemy>();
      final kijinAllies = game.world.children.query<RedeemedKijinAlly>();
      
      final allAllies = <PositionComponent>[...normalAllies, ...kijinAllies];
      
      if (allAllies.isNotEmpty) {
        _currentTarget = allAllies[random.nextInt(allAllies.length)];
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
    }
    return true;
  }
  
  void _executeDash() {
    if (_currentTarget == null) return;
    
    // Iniciar PREPARACIÓN (fase invulnerable)
    _isPreparingDash = true;
    _dashPreparationTimer = 0.0;
    _dashTime = 0.0;
    _dashTimer = _dashCooldown;
    _dashDirection = (_currentTarget!.position - position).normalized();
    
    print('🛡️ ¡Kohaa se vuelve INVULNERABLE y prepara su embestida!');
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
      print('⚔️ Kohaa atacó al jugador: $_damage daño');
    } else if (target is AlliedEnemy) {
      target.takeDamage(_damage);
      print('⚔️ Kohaa atacó a aliado normal: $_damage daño');
    } else if (target is RedeemedKijinAlly) {
      target.takeDamage(_damage);
      print('⚔️ Kohaa atacó a Kijin aliado: $_damage daño');
    }
  }
  
  /// Recibe daño
  void takeDamage(double damage) {
    if (_isDead) return;
    
    // INVULNERABLE durante preparación del dash
    if (_isPreparingDash) {
      print('🛡️ ¡Kohaa es INVULNERABLE! (Preparando dash)');
      return;
    }
    
    _health -= damage;
    print('💥 Kohaa recibió $damage de daño! (${_health.toStringAsFixed(0)}/${_maxHealth} HP)');
    
    // NUEVA: Explosión defensiva cuando está baja de vida
    final healthPercent = _health / _maxHealth;
    if (healthPercent <= _defensiveExplosionThreshold && _canUseDefensiveExplosion) {
      _executeDefensiveExplosion();
      _canUseDefensiveExplosion = false;
      _defensiveExplosionTimer = _defensiveExplosionCooldown;
    }
    
    // Spawn de enfermeros a 60% HP (MÁS TEMPRANO)
    if (!_hasSpawnedNurses && _health <= _maxHealth * 0.6) {
      _spawnNurses();
      _hasSpawnedNurses = true;
      print('🩸 ¡KOHAA SPAWNEÓ ENFERMEROS AL 60% HP!');
    }
    
    if (_health <= 0) {
      _health = 0;
      _die();
    }
  }
  
  /// NUEVA HABILIDAD: Explosión Defensiva
  /// Se activa cuando Kohaa está baja de vida (< 30%)
  void _executeDefensiveExplosion() {
    const double explosionRadius = 250.0;
    const double explosionDamage = 40.0;
    const double pushForce = 450.0;
    const double healAmount = 100.0;
    
    print('💥🔴 ¡KOHAA USA EXPLOSIÓN DEFENSIVA! Se cura $healAmount HP');
    
    // CURARSE
    _health = (_health + healAmount).clamp(0.0, _maxHealth);
    print('💚 Kohaa se curó a ${_health.toStringAsFixed(0)}/${_maxHealth} HP');
    
    // Dañar y empujar al jugador
    final player = game.player;
    final distToPlayer = position.distanceTo(player.position);
    if (distToPlayer <= explosionRadius) {
      player.takeDamage(explosionDamage);
      // EMPUJAR FUERTEMENTE
      final pushDirection = (player.position - position).normalized();
      player.position += pushDirection * pushForce * 0.15;
      print('💥 ¡Jugador recibió $explosionDamage daño y fue EMPUJADO!');
    }
    
    // Dañar y empujar aliados normales
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
    
    // Dañar y empujar aliados Kijin
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
    print('🩸 ¡CAMBIO DE FASE! Kohaa invoca enfermeros!');
    
    // ===== ATAQUE AOE DE FASE =====
    _executePhaseTransitionAOE();
    
    // REGENERAR VIDA al spawn de enfermeros (25% de HP max)
    final healAmount = _maxHealth * 0.25;
    _health = (_health + healAmount).clamp(0.0, _maxHealth);
    print('💚 ¡Kohaa se curó ${healAmount.toStringAsFixed(0)} HP! (${_health.toStringAsFixed(0)}/${_maxHealth})');
    
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
  
  /// Ataque AOE al cambiar de fase - Daña y empuja
  void _executePhaseTransitionAOE() {
    const double aoeRadius = 200.0;
    const double aoeDamage = 30.0;
    const double pushForce = 300.0;
    
    print('💥💥 ¡EXPLOSIÓN DE FASE! Radio: $aoeRadius');
    
    // Dañar jugador si está cerca
    final player = game.player;
    final distToPlayer = position.distanceTo(player.position);
    if (distToPlayer <= aoeRadius) {
      player.takeDamage(aoeDamage);
      // Empujar jugador
      final pushDirection = (player.position - position).normalized();
      player.position += pushDirection * pushForce * 0.1; // Pequeño empuje
      print('💥 Jugador recibió $aoeDamage daño y fue empujado!');
    }
    
    // Dañar TODOS los aliados cercanos
    final normalAllies = game.world.children.query<AlliedEnemy>();
    for (final ally in normalAllies) {
      if (ally.isDead) continue;
      final distToAlly = position.distanceTo(ally.position);
      if (distToAlly <= aoeRadius) {
        ally.takeDamage(aoeDamage);
        // Empujar aliado
        final pushDirection = (ally.position - position).normalized();
        ally.position += pushDirection * pushForce * 0.15;
        print('💥 Aliado normal recibió $aoeDamage daño y fue empujado!');
      }
    }
    
    // Dañar aliados Kijin cercanos
    final kijinAllies = game.world.children.query<RedeemedKijinAlly>();
    for (final ally in kijinAllies) {
      if (ally.isDead) continue;
      final distToAlly = position.distanceTo(ally.position);
      if (distToAlly <= aoeRadius) {
        ally.takeDamage(aoeDamage);
        // Empujar aliado Kijin
        final pushDirection = (ally.position - position).normalized();
        ally.position += pushDirection * pushForce * 0.15;
        print('💥 Kijin aliado recibió $aoeDamage daño y fue empujado!');
      }
    }
  }
  
  /// Recuperar vida al reintentar (recarga entre muertes del jugador)
  void recoverHealthOnRetry(double amount) {
    if (_isDead) return; // No recuperar si ya murió
    
    _health = (_health + amount).clamp(0.0, _maxHealth);
    print('💚 Kohaa recuperó $amount HP! Ahora tiene ${_health.toStringAsFixed(0)}/$_maxHealth HP');
  }
  
  /// Muerte de Kohaa
  void _die() {
    _isDead = true;
    
    print('GAME MESSAGE: Kohaa ha sido derrotada...');
    
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
    
    // Aura roja para Kijin
    final auraPaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _size / 2 + 8,
      auraPaint,
    );
    
    // Cuerpo de Kohaa (rojo oscuro)
    final bodyPaint = Paint()
      ..color = const Color(0xFF8B0000).withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _size / 2,
      bodyPaint,
    );
    
    // Borde blanco brillante
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _size / 2,
      borderPaint,
    );
    
    // Indicador de preparación (INVULNERABLE - dorado brillante)
    if (_isPreparingDash) {
      final preparePaint = Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      
      canvas.drawCircle(
        (size / 2).toOffset(),
        _size / 2 + 12,
        preparePaint,
      );
      
      // Segundo anillo pulsante
      final pulse = (sin(_dashPreparationTimer * 10) * 0.5 + 0.5);
      final pulsePaint = Paint()
        ..color = Colors.white.withOpacity(pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawCircle(
        (size / 2).toOffset(),
        _size / 2 + 18,
        pulsePaint,
      );
    }
    
    // Indicador de dash activo
    if (_isDashing) {
      final dashPaint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawCircle(
        (size / 2).toOffset(),
        _size / 2 + 10,
        dashPaint,
      );
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
    
    // Fondo
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      bgPaint,
    );
    
    // Vida
    final healthPercent = (_health / _maxHealth).clamp(0.0, 1.0);
    final healthPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth * healthPercent, barHeight),
      healthPaint,
    );
    
    // Borde
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      borderPaint,
    );
  }
  
  void _drawBossName(Canvas canvas) {
    final textPainter = TextPainter(
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
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        -35,
      ),
    );
  }
  
  /// Getters
  bool get isDead => _isDead;
  double get health => _health;
  double get healthPercent => _health / _maxHealth;
}
