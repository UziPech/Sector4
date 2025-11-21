import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/palette.dart';
import '../game/expediente_game.dart';
import 'enemy_character.dart';
import 'character_component.dart';
import 'particle_effect.dart';
import '../game/components/player.dart';
import 'obsession_object.dart';
import 'destructible_object.dart';
import '../game/components/enemies/irracional.dart';
import '../game/components/enemies/yurei_kohaa.dart'; // Para atacar al boss Kijin

class Bullet extends PositionComponent with CollisionCallbacks, HasGameReference<ExpedienteKorinGame> {
  Vector2 direction;
  final bool isPlayerBullet;
  final double speed;
  final double damage;
  
  // Sistema de seguimiento
  final double homingStrength = 0.8;
  final double homingRange = 400.0;
  PositionComponent? _target;

  final Paint _paint;
  final Paint _glowPaint;
  
  // Sistema de trail
  final List<Vector2> _trailPositions = [];
  final int _maxTrailLength = 8;
  double _trailTimer = 0.0;
  
  // Rotación para efecto visual
  double _rotation = 0.0;

  Bullet({
    required Vector2 position,
    required Vector2 direction,
    required this.isPlayerBullet,
    this.speed = 450.0,
    this.damage = 20.0,
  }) : direction = direction.clone(),
       _paint = Paint()
         ..color = isPlayerBullet ? const Color.fromARGB(255, 255, 220, 0) : const Color.fromARGB(255, 255, 50, 50)
         ..style = PaintingStyle.fill,
       _glowPaint = Paint()
         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
       super(position: position.clone(), size: Vector2.all(16.0), anchor: Anchor.center, priority: 20);

  @override
  void update(double dt) {
    super.update(dt);
    
    if (isPlayerBullet) {
      _updateHoming(dt);
    }
    
    _trailTimer += dt;
    if (_trailTimer >= 0.02) {
      _trailPositions.add(position.clone());
      if (_trailPositions.length > _maxTrailLength) {
        _trailPositions.removeAt(0);
      }
      _trailTimer = 0.0;
    }
    
    _rotation += dt * 10.0;
    
    position.add(direction * speed * dt);

    if (position.length > 3000) {
      removeFromParent();
    }
  }
  
  void _updateHoming(double dt) {
    if (_target == null || _target!.isMounted == false) {
      _target = _findNearestEnemy();
    }
    
    if (_target != null) {
      final toTarget = _target!.position - position;
      final distance = toTarget.length;
      
      if (distance < homingRange && distance > 0) {
        final targetDirection = toTarget.normalized();
        direction.x += (targetDirection.x - direction.x) * homingStrength * dt * 15;
        direction.y += (targetDirection.y - direction.y) * homingStrength * dt * 15;
        direction.normalize();
      } else if (distance >= homingRange) {
        _target = null;
      }
    }
  }
  
  PositionComponent? _findNearestEnemy() {
    PositionComponent? nearest;
    double nearestDistance = double.infinity;
    
    for (final child in game.world.children) {
      if (child is EnemyCharacter) {
        final distance = (child.position - position).length;
        if (distance < nearestDistance && distance < homingRange) {
          nearestDistance = distance;
          nearest = child;
        }
      } else if (child is IrrationalEnemy) {
        final distance = (child.position - position).length;
        if (distance < nearestDistance && distance < homingRange) {
          nearestDistance = distance;
          nearest = child;
        }
      } else if (child is YureiKohaa) {
        final distance = (child.position - position).length;
        if (distance < nearestDistance && distance < homingRange) {
          nearestDistance = distance;
          nearest = child;
        }
      }
    }
    
    return nearest;
  }

  @override
  void render(Canvas canvas) {
    // Trail
    for (int i = 0; i < _trailPositions.length; i++) {
      final trailPos = _trailPositions[i];
      final relativePos = trailPos - position;
      final alpha = (i / _trailPositions.length * 80).toInt();
      final trailSize = size.x / 2 * (i / _trailPositions.length);
      
      final trailPaint = Paint()
        ..color = (isPlayerBullet 
            ? Color.fromARGB(alpha, 255, 220, 0) 
            : Color.fromARGB(alpha, 255, 50, 50))
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(relativePos.x, relativePos.y),
        trailSize,
        trailPaint,
      );
    }
    
    canvas.drawCircle(Offset.zero, size.x / 2 + 4, _glowPaint);
    canvas.drawCircle(Offset.zero, size.x / 2, _paint);
    
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, size.x / 4, corePaint);
    
    if (isPlayerBullet) {
      canvas.save();
      canvas.rotate(_rotation);
      _drawStar(canvas, size.x / 2);
      canvas.restore();
    }
  }
  
  void _drawStar(Canvas canvas, double radius) {
    final path = Path();
    final points = 4;
    final angle = (math.pi * 2) / points;
    
    for (int i = 0; i < points; i++) {
      final x = math.cos(angle * i) * radius * 0.4;
      final y = math.sin(angle * i) * radius * 0.4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    final starPaint = Paint()
      ..color = const Color.fromARGB(150, 255, 255, 255)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, starPaint);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is EnemyCharacter) {
      if (isPlayerBullet) {
        try {
          other.receiveDamage(damage);
          _createImpactEffect();
          removeFromParent();
        } catch (e) {
          // Error
        }
      }
    } 
    else if (other is PlayerCharacter) {
      if (!isPlayerBullet) {
        try {
          other.takeDamage(damage);
          _createImpactEffect();
          removeFromParent();
        } catch (e) {
          // Error
        }
      }
    }
    else if (other is IrrationalEnemy) {
      if (isPlayerBullet) {
        try {
          other.takeDamage(damage);
          _createImpactEffect();
          removeFromParent();
        } catch (e) {
          // Error
        }
      }
    }
    else if (other is YureiKohaa) {
      if (isPlayerBullet) {
        try {
          other.takeDamage(damage);
          _createImpactEffect();
          removeFromParent();
          print('🔫 Bala golpeó a KOHAA: $damage daño');
        } catch (e) {
          // Error
        }
      }
    }
    else if (other is ObsessionObject) {
      if (isPlayerBullet) {
        try {
          other.takeDamage(damage);
          _createImpactEffect();
          removeFromParent();
        } catch (e) {
          // Error
        }
      }
    }
    else if (other is DestructibleObject) {
      if (isPlayerBullet) {
        try {
          other.takeDamage(damage);
          _createImpactEffect();
          removeFromParent();
        } catch (e) {
          // Error
        }
      }
    }
  }
  
  void _createImpactEffect() {
    final effect = ParticleEffect(
      position: position.clone(),
      color: isPlayerBullet ? Colors.yellow : Colors.red,
      particleCount: 15,
      lifetime: 0.5,
    );
    game.world.add(effect);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox()..collisionType = CollisionType.active);
  }
}
