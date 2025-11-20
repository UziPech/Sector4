import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../expediente_game.dart';
import 'irracional.dart';

/// Enemigo aliado temporal - Resucitado por Mel
/// Ataca a otros enemigos durante un tiempo limitado
class AlliedEnemy extends PositionComponent
    with HasGameReference<ExpedienteKorinGame>, CollisionCallbacks {
  
  final double _maxHealth = 50.0;
  double _health = 50.0;
  final double _speed = 120.0;
  final double _damage = 15.0;
  final double _attackRange = 40.0;
  final double _attackCooldown = 1.0;
  double _attackTimer = 0.0;
  
  // Duración del aliado
  final double _lifetime;
  double _lifetimeTimer = 0.0;
  
  bool _isDead = false;
  IrrationalEnemy? _currentTarget;
  
  static const double _size = 28.0;
  
  AlliedEnemy({
    required Vector2 position,
    double lifetime = 20.0, // 20 segundos por defecto
  })  : _lifetime = lifetime,
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
    // Si no tiene objetivo o el objetivo murió, buscar nuevo
    if (_currentTarget == null || _currentTarget!.isDead) {
      _findNearestEnemy();
    }
    
    // Si tiene objetivo, perseguirlo y atacar
    if (_currentTarget != null && !_currentTarget!.isDead) {
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
  
  void _findNearestEnemy() {
    final enemies = game.world.children.query<IrrationalEnemy>();
    IrrationalEnemy? nearest;
    double nearestDistance = double.infinity;
    
    for (final enemy in enemies) {
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
    
    _currentTarget!.takeDamage(_damage);
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
    removeFromParent();
  }
  
  /// Expiración natural del aliado
  void _expire() {
    _isDead = true;
    // Crear efecto de desvanecimiento
    _createExpireEffect();
    removeFromParent();
  }
  
  void _createExpireEffect() {
    // TODO: Agregar efecto visual de desvanecimiento
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
