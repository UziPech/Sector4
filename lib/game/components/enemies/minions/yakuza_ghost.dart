import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../../expediente_game.dart';
import '../../player.dart';
import '../yurei_kohaa.dart'; // Para atacar a Kohaa

/// Fantasma Yakuza - Minion de On-Oyabun
/// Aparecen a 80% HP en Fase 1
class YakuzaGhost extends PositionComponent 
    with CollisionCallbacks, HasGameReference<ExpedienteKorinGame> {
  
  double _health;
  final double _maxHealth = 150.0;
  final double _speed = 90.0;
  final double _damage = 15.0;
  final double _attackRange = 40.0;
  final double _attackCooldown = 1.5;
  double _attackTimer = 0.0;
  
  bool _isDead = false;
  PositionComponent? _currentTarget;
  
  static const double _size = 30.0;
  
  YakuzaGhost({
    required Vector2 position,
  })  : _health = 150.0,
        super(position: position, anchor: Anchor.center);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(_size);
    
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
    
    // Actualizar timer de ataque
    if (_attackTimer > 0) _attackTimer -= dt;
    
    // IA simple: perseguir y atacar al jugador
    _updateAI(dt);
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
    
    // Lógica de movimiento con separación (Steering Behavior)
    Vector2 direction = (target!.position - position).normalized();
    
    // Fuerza de separación para evitar agruparse
    Vector2 separation = Vector2.zero();
    int neighbors = 0;
    
    game.world.children.query<YakuzaGhost>().forEach((other) {
      if (other != this && !other.isDead) {
        final dist = position.distanceTo(other.position);
        if (dist < _size * 1.5) { // Radio de separación
          separation += (position - other.position).normalized() / dist;
          neighbors++;
        }
      }
    });
    
    if (neighbors > 0) {
      separation = separation.normalized() * 1.5; // Peso de la separación
      direction = (direction + separation).normalized();
    }
    
    // Moverse
    if (minDistance > _attackRange) {
      position += direction * _speed * dt;
    } else {
      // Atacar si está en rango
      _tryAttack();
    }
  }
  
  void _tryAttack() {
    if (_attackTimer > 0 || _currentTarget == null) return;
    
    final distance = position.distanceTo(_currentTarget!.position);
    
    if (distance <= _attackRange) {
      if (_currentTarget is PlayerCharacter) {
        (_currentTarget as PlayerCharacter).takeDamage(_damage);
        debugPrint('👻 Fantasma Yakuza ataca Jugador: $_damage daño');
      } else if (_currentTarget is YureiKohaa) {
        (_currentTarget as YureiKohaa).takeDamage(_damage);
        debugPrint('👻 Fantasma Yakuza ataca Kohaa: $_damage daño');
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
    debugPrint('👻 Fantasma Yakuza eliminado');
    removeFromParent();
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Aura fantasmal (semi-transparente)
    final auraPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _size / 2 + 5,
      auraPaint,
    );
    
    // Cuerpo del fantasma (gris oscuro)
    final bodyPaint = Paint()
      ..color = const Color(0xFF505050).withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _size / 2,
      bodyPaint,
    );
    
    // Borde rojo (yakuza)
    final borderPaint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _size / 2,
      borderPaint,
    );
    
    // Barra de vida
    _drawHealthBar(canvas);
  }
  
  void _drawHealthBar(Canvas canvas) {
    const barWidth = 40.0;
    const barHeight = 3.0;
    final barX = (size.x - barWidth) / 2;
    final barY = -8.0;
    
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
      ..color = Colors.red.withOpacity(0.7)
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
