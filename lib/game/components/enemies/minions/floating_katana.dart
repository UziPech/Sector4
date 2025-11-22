import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../../expediente_game.dart';
import '../../player.dart';
import '../yurei_kohaa.dart'; // Para atacar a Kohaa

/// Katana flotante autónoma que ataca al jugador
/// Aparece a 40% HP en Fase 2 del jefe
class FloatingKatana extends PositionComponent 
    with CollisionCallbacks, HasGameReference<ExpedienteKorinGame> {
  
  double _health;
  final double _maxHealth = 80.0;
  final double _speed = 110.0;
  final double _damage = 25.0;
  final double _attackRange = 60.0;
  final double _attackCooldown = 1.2;
  double _attackTimer = 0.0;
  
  bool _isDead = false;
  Vector2 _velocity = Vector2.zero();
  double _rotationAngle = 0.0;
  PositionComponent? _currentTarget;
  
  static const double _size = 35.0;
  
  FloatingKatana({
    required Vector2 position,
  })  : _health = 80.0,
        super(position: position, anchor: Anchor.center);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(_size, 8); // Katana horizontal flotante
    
    // Agregar hitbox
    add(RectangleHitbox());
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (_isDead) return;
    
    // Actualizar timer de ataque
    if (_attackTimer > 0) _attackTimer -= dt;
    
    // Rotar constantemente para efecto visual
    _rotationAngle += dt * 3.0;
    angle = _rotationAngle;
    
    // IA: Perseguir y atacar al jugador
    _updateAI(dt);
    
    // Aplicar velocidad
    position += _velocity * dt;
  }
  
  void _updateAI(double dt) {
    final player = game.player;
    
    // Buscar objetivo más cercano (Jugador o Kohaa)
    PositionComponent? target = player.isDead ? null : player;
    double minDistance = player.isDead ? double.infinity : position.distanceTo(player.position);
    
    // Verificar si Kohaa está cerca
    game.world.children.query<YureiKohaa>().forEach((kohaa) {
      if (!kohaa.isDead) {
        final dist = position.distanceTo(kohaa.position);
        if (dist < minDistance) {
          minDistance = dist;
          target = kohaa;
        }
      }
    });
    
    _currentTarget = target;
    
    if (target == null) return;
    
    final distanceToTarget = position.distanceTo(target!.position);
    
    // Orbitar alrededor del objetivo
    if (distanceToTarget > _attackRange) {
      // Acercarse
      final direction = (target!.position - position).normalized();
      _velocity = direction * _speed;
    } else {
      // Orbitar y atacar
      final angleToTarget = atan2(
        target!.position.y - position.y,
        target!.position.x - position.x,
      );
      final orbitAngle = angleToTarget + pi / 2;
      _velocity = Vector2(cos(orbitAngle), sin(orbitAngle)) * (_speed * 0.7);
      
      _tryAttack();
    }
  }
  
  void _tryAttack() {
    if (_attackTimer > 0 || _currentTarget == null) return;
    
    final distance = position.distanceTo(_currentTarget!.position);
    
    if (distance <= _attackRange) {
      if (_currentTarget is PlayerCharacter) {
        (_currentTarget as PlayerCharacter).takeDamage(_damage);
        debugPrint('⚔️ Katana flotante ataca Jugador: $_damage daño');
      } else if (_currentTarget is YureiKohaa) {
        (_currentTarget as YureiKohaa).takeDamage(_damage);
        debugPrint('⚔️ Katana flotante ataca Kohaa: $_damage daño');
      }
      
      _attackTimer = _attackCooldown;
    }
  }
  
  void takeDamage(double damage) {
    if (_isDead) return;
    
    _health -= damage;
    
    if (_health <= 0) {
      _health = 0;
      _die();
    }
  }
  
  void _die() {
    _isDead = true;
    debugPrint('⚔️ Katana flotante destruida');
    removeFromParent();
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Aura flotante (brillante)
    final auraPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _size / 2 + 3,
      auraPaint,
    );
    
    // Hoja de katana (plateada brillante)
    final bladePaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(size.toRect(), bladePaint);
    
    // Borde brillante
    final edgePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawRect(size.toRect(), edgePaint);
    
    // Barra de vida pequeña
    _drawHealthBar(canvas);
  }
  
  void _drawHealthBar(Canvas canvas) {
    const barWidth = 30.0;
    const barHeight = 2.0;
    final barX = (size.x - barWidth) / 2;
    final barY = -6.0;
    
    // Fondo
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      bgPaint,
    );
    
    // HP
    final healthPercent = (_health / _maxHealth).clamp(0.0, 1.0);
    final healthPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth * healthPercent, barHeight),
      healthPaint,
    );
  }
  
  /// Getters
  bool get isDead => _isDead;
  double get health => _health;
}
