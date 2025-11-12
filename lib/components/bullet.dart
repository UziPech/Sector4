import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'particle_effect.dart';
import '../main.dart';

class Bullet extends PositionComponent with CollisionCallbacks, HasGameReference<ExpedienteKorinGame> {
  Vector2 direction; // Cambiado a mutable para el homing
  final bool isPlayerBullet;
  final double speed;
  final double damage;
  
  // Sistema de seguimiento mejorado (homing más agresivo)
  final double homingStrength = 0.8; // Qué tan fuerte sigue al objetivo (0-1) - AUMENTADO
  final double homingRange = 400.0; // Distancia máxima para seguir - AUMENTADO
  PositionComponent? _target;

  final Paint _paint;
  final Paint _glowPaint;
  final Paint _trailPaint;
  
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
    this.speed = 450.0, // AUMENTADO de 300 a 450
    this.damage = 20.0,
  }) : direction = direction.clone(),
       _paint = Paint()
         ..color = isPlayerBullet ? const Color.fromARGB(255, 255, 220, 0) : const Color.fromARGB(255, 255, 50, 50)
         ..style = PaintingStyle.fill,
       _glowPaint = Paint()
         ..color = (isPlayerBullet ? const Color.fromARGB(100, 255, 220, 0) : const Color.fromARGB(100, 255, 50, 50))
         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
       _trailPaint = Paint()
         ..color = (isPlayerBullet ? const Color.fromARGB(80, 255, 220, 0) : const Color.fromARGB(80, 255, 50, 50))
         ..style = PaintingStyle.fill,
       super(position: position.clone(), size: Vector2.all(16.0), anchor: Anchor.center); // AUMENTADO de 12 a 16

  @override
  void update(double dt) {
    super.update(dt);
    
    // Sistema de seguimiento ligero (solo para balas del jugador)
    if (isPlayerBullet) {
      _updateHoming(dt);
    }
    
    // Actualizar trail
    _trailTimer += dt;
    if (_trailTimer >= 0.02) { // Agregar posición cada 0.02s
      _trailPositions.add(position.clone());
      if (_trailPositions.length > _maxTrailLength) {
        _trailPositions.removeAt(0);
      }
      _trailTimer = 0.0;
    }
    
    // Rotar para efecto visual
    _rotation += dt * 10.0;
    
    position.add(direction * speed * dt);

    // Eliminar la bala si se va muy lejos
    if (position.length > 1000) {
      removeFromParent();
    }
  }
  
  void _updateHoming(double dt) {
    // Buscar el enemigo más cercano si no tenemos objetivo
    if (_target == null || _target!.isMounted == false) {
      _target = _findNearestEnemy();
    }
    
    // Si tenemos un objetivo, ajustar dirección hacia él
    if (_target != null) {
      final toTarget = _target!.position - position;
      final distance = toTarget.length;
      
      // Solo seguir si está dentro del rango
      if (distance < homingRange && distance > 0) {
        final targetDirection = toTarget.normalized();
        
        // Homing más agresivo - interpolación más fuerte
        direction.x += (targetDirection.x - direction.x) * homingStrength * dt * 15; // AUMENTADO de 5 a 15
        direction.y += (targetDirection.y - direction.y) * homingStrength * dt * 15;
        
        // Normalizar para mantener velocidad constante
        direction.normalize();
      } else if (distance >= homingRange) {
        // Si el objetivo está fuera de rango, buscar otro
        _target = null;
      }
    }
  }
  
  PositionComponent? _findNearestEnemy() {
    PositionComponent? nearest;
    double nearestDistance = double.infinity;
    
    // Buscar en los hijos del world
    for (final child in game.world.children) {
      if (child is PositionComponent && 
          child.runtimeType.toString().contains('EnemyCharacter')) {
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
    // Dibujar trail (estela)
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
    
    // Dibujar glow exterior (resplandor)
    canvas.drawCircle(Offset.zero, size.x / 2 + 4, _glowPaint);
    
    // Dibujar bala principal (más grande)
    canvas.drawCircle(Offset.zero, size.x / 2, _paint);
    
    // Dibujar núcleo brillante
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, size.x / 4, corePaint);
    
    // Dibujar forma de estrella para balas del jugador
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

    // Verificar si colisiona con un enemigo
    if (other.runtimeType.toString().contains('EnemyCharacter')) {
      if (isPlayerBullet) {
        try {
          (other as dynamic).receiveDamage(damage);
          _createImpactEffect();
          removeFromParent();
        } catch (e) {
          // Error al aplicar daño
        }
      }
    } 
    // Verificar si colisiona con el jugador
    else if (other.runtimeType.toString().contains('PlayerCharacter')) {
      if (!isPlayerBullet) {
        try {
          (other as dynamic).receiveDamage(damage);
          _createImpactEffect();
          removeFromParent();
        } catch (e) {
          // Error al aplicar daño
        }
      }
    }
  }
  
  void _createImpactEffect() {
    // Efecto de impacto más grande y visible
    final effect = ParticleEffect(
      position: position.clone(),
      color: isPlayerBullet ? Colors.yellow : Colors.red,
      particleCount: 15, // AUMENTADO de 8 a 15
      lifetime: 0.5, // AUMENTADO de 0.3 a 0.5
    );
    game.world.add(effect);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox()..collisionType = CollisionType.active);
  }
}
