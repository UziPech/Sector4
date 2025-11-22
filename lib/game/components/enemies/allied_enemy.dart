import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../expediente_game.dart';
import '../../systems/resurrection_system.dart';
import '../enemy_tomb.dart';
import 'irracional.dart';
import 'yurei_kohaa.dart'; // Añadido para poder atacar a Kohaa
import '../bosses/on_oyabun_boss.dart'; // Para atacar a On-Oyabun
import 'minions/yakuza_ghost.dart'; // Para atacar minions del boss
import 'minions/floating_katana.dart'; // Para atacar minions del boss

/// Enemigo aliado temporal - Resucitado por Mel
/// Ataca a otros enemigos durante un tiempo limitado
class AlliedEnemy extends PositionComponent
    with HasGameReference<ExpedienteKorinGame>, CollisionCallbacks {
  
  late final double _maxHealth;
  late double _health;
  late final double _speed;
  late final double _damage;
  late final double _attackRange;
  late final double _attackCooldown;
  double _attackTimer = 0.0;
  
  // Duración del aliado
  final double _lifetime;
  double _lifetimeTimer = 0.0;
  
  bool _isDead = false;
  PositionComponent? _currentTarget; // Cambiado para aceptar cualquier enemigo
  
  // Referencia al manager de resurrecciones
  final ResurrectionManager? resurrectionManager;
  
  // Tipo de enemigo resucitado
  final String enemyType;
  
  static const double _size = 28.0;
  
  AlliedEnemy({
    required Vector2 position,
    double lifetime = 45.0, // 45 segundos por defecto
    this.resurrectionManager,
    this.enemyType = 'irracional',
  })  : _lifetime = lifetime,
        super(position: position) {
    // Configurar estadísticas según el tipo de enemigo
    _configureStats();
  }
  
  /// Configura las estadísticas según el tipo de enemigo
  void _configureStats() {
    switch (enemyType) {
      case 'irracional':
      case 'allied':
        _maxHealth = 60.0;
        _health = 60.0;
        _speed = 130.0;
        _damage = 18.0;
        _attackRange = 45.0;
        _attackCooldown = 0.9;
        break;
      // Preparado para futuros mutados de mayor rango
      case 'mutado_rango_medio':
        _maxHealth = 100.0;
        _health = 100.0;
        _speed = 150.0;
        _damage = 25.0;
        _attackRange = 50.0;
        _attackCooldown = 0.8;
        break;
      case 'mutado_rango_alto':
        _maxHealth = 150.0;
        _health = 150.0;
        _speed = 170.0;
        _damage = 35.0;
        _attackRange = 60.0;
        _attackCooldown = 0.7;
        break;
      default:
        _maxHealth = 60.0;
        _health = 60.0;
        _speed = 130.0;
        _damage = 18.0;
        _attackRange = 45.0;
        _attackCooldown = 0.9;
    }
  }
  
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
    
    // Actualizar tiempo de vida
    _lifetimeTimer += dt;
    if (_lifetimeTimer >= _lifetime) {
      _expire();
      return;
    }
    
    // Actualizar cooldown de ataque
    if (_attackTimer > 0) {
      _attackTimer -= dt;
    }
    
    // IA: Buscar y atacar enemigos
    _findAndAttackEnemies(dt);
  }
  
  void _findAndAttackEnemies(double dt) {
    // Si no tiene objetivo, buscar nuevo
    if (_currentTarget == null || !_isTargetValid()) {
      _findNearestEnemy();
    }
    
    // Si tiene objetivo, perseguirlo y atacar
    if (_currentTarget != null && _isTargetValid()) {
      final distanceToTarget = position.distanceTo(_currentTarget!.position);
      
      // Acercarse si está lejos
      if (distanceToTarget > _attackRange) {
        final direction = (_currentTarget!.position - position).normalized();
        position += direction * _speed * dt;
      } else {
        // Atacar si está en rango
        _tryAttack();
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
  
  void _findNearestEnemy() {
    // Buscar todos los tipos de enemigos
    final irrationals = game.world.children.query<IrrationalEnemy>();
    final yureiKohaas = game.world.children.query<YureiKohaa>();
    final ghosts = game.world.children.query<YakuzaGhost>();
    final katanas = game.world.children.query<FloatingKatana>();
    
    PositionComponent? nearest;
    double nearestDistance = double.infinity;
    
    // PRIORIDAD 0: YUREI KOHAA (enemiga principal) - SIEMPRE priorizar
    for (final kohaa in yureiKohaas) {
      if (kohaa.isDead) continue;
      
      final distance = position.distanceTo(kohaa.position);
      // Si Yurei Kohaa está a menos de 300 unidades, SIEMPRE targetearla
      if (distance < 300.0) {
        nearest = kohaa;
        nearestDistance = distance;
        print('🎯 Aliado priorizando YUREI KOHAA (${distance.toInt()}u)');
        break; // Prioridad absoluta
      } else if (distance < nearestDistance) {
        nearest = kohaa;
        nearestDistance = distance;
      }
    }
    
    // Si ya encontramos a Yurei Kohaa cerca, no buscar más
    if (nearest is YureiKohaa && nearestDistance < 300.0) {
      _currentTarget = nearest;
      return;
    }
    
    // PRIORIDAD 1: Atacar minions del boss (más fáciles)
    for (final ghost in ghosts) {
      if (ghost.isDead) continue;
      final distance = position.distanceTo(ghost.position);
      if (distance < nearestDistance) {
        nearest = ghost;
        nearestDistance = distance;
      }
    }
    
    for (final katana in katanas) {
      if (katana.isDead) continue;
      final distance = position.distanceTo(katana.position);
      if (distance < nearestDistance) {
        nearest = katana;
        nearestDistance = distance;
      }
    }
    
    // PRIORIDAD 2: Buscar entre irracionales
    for (final enemy in irrationals) {
      if (enemy.isDead) continue;
      
      final distance = position.distanceTo(enemy.position);
      if (distance < nearestDistance) {
        nearest = enemy;
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
  
  void _tryAttack() {
    if (_attackTimer > 0 || _currentTarget == null) return;
    
    // Atacar según el tipo de enemigo
    if (_currentTarget is YakuzaGhost) {
      (_currentTarget as YakuzaGhost).takeDamage(_damage);
      print('⚔️ Enfermero atacó Fantasma Yakuza: $_damage daño');
    } else if (_currentTarget is FloatingKatana) {
      (_currentTarget as FloatingKatana).takeDamage(_damage);
      print('⚔️ Enfermero atacó Katana Flotante: $_damage daño');
    } else if (_currentTarget is IrrationalEnemy) {
      (_currentTarget as IrrationalEnemy).takeDamage(_damage);
      print('⚔️ Aliado atacó Irracional: $_damage daño');
    } else if (_currentTarget is YureiKohaa) {
      (_currentTarget as YureiKohaa).takeDamage(_damage);
      print('⚔️ Aliado atacó Kohaa: $_damage daño');
    } else if (_currentTarget is OnOyabunBoss) {
      (_currentTarget as OnOyabunBoss).takeDamage(_damage);
      print('⚔️ Aliado atacó ON-OYABUN: $_damage daño');
    }
    
    _attackTimer = _attackCooldown;
  }
  
  /// Recibe daño (puede ser atacado por otros enemigos)
  void takeDamage(double damage) {
    if (_isDead) return;
    
    _health -= damage;
    
    if (_health <= 0) {
      _health = 0;
      _die();
    }
  }
  
  /// Muerte del aliado
  void _die() {
    _isDead = true;
    _createTombOnDeath();
    // Liberar slot en el manager
    resurrectionManager?.unregisterAlly();
    removeFromParent();
  }
  
  /// Expiración natural del aliado
  void _expire() {
    _isDead = true;
    // Crear efecto de desvanecimiento
    _createExpireEffect();
    _createTombOnDeath();
    // Liberar slot en el manager
    resurrectionManager?.unregisterAlly();
    removeFromParent();
  }
  
  void _createExpireEffect() {
    // TODO: Agregar efecto visual de desvanecimiento
  }
  
  /// Crea una tumba cuando el aliado muere o expira
  void _createTombOnDeath() {
    final tomb = EnemyTomb(
      position: position.clone(),
      enemyType: 'allied',
      lifetime: 8.0, // Las tumbas de aliados duran más tiempo
    );
    game.world.add(tomb);
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Aura verde para indicar que es aliado
    final auraPaint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _size / 2 + 5,
      auraPaint,
    );
    
    // Cuerpo del aliado (verde)
    final bodyPaint = Paint()
      ..color = Colors.green.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _size / 2,
      bodyPaint,
    );
    
    // Borde blanco
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _size / 2,
      borderPaint,
    );
    
    // Barra de vida
    _drawHealthBar(canvas);
    
    // Indicador de tiempo restante
    _drawLifetimeBar(canvas);
  }
  
  void _drawHealthBar(Canvas canvas) {
    const barWidth = 40.0;
    const barHeight = 4.0;
    final barX = (size.x - barWidth) / 2;
    final barY = -10.0;
    
    // Fondo
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      bgPaint,
    );
    
    // Vida
    final healthPercent = (_health / _maxHealth).clamp(0.0, 1.0);
    final healthPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth * healthPercent, barHeight),
      healthPaint,
    );
  }
  
  void _drawLifetimeBar(Canvas canvas) {
    const barWidth = 40.0;
    const barHeight = 3.0;
    final barX = (size.x - barWidth) / 2;
    final barY = -16.0;
    
    // Progreso de vida
    final lifetimePercent = (1.0 - (_lifetimeTimer / _lifetime)).clamp(0.0, 1.0);
    final lifetimePaint = Paint()
      ..color = Colors.yellow.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth * lifetimePercent, barHeight),
      lifetimePaint,
    );
  }
  
  /// Getters
  bool get isDead => _isDead;
  double get health => _health;
}
