import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Efecto de partículas simple para impactos y explosiones
class ParticleEffect extends PositionComponent {
  final Color color;
  final int particleCount;
  final double lifetime;
  final List<_Particle> particles = [];
  
  double _elapsed = 0.0;
  
  ParticleEffect({
    required Vector2 position,
    required this.color,
    this.particleCount = 10,
    this.lifetime = 0.5,
  }) {
    this.position = position;
    _createParticles();
  }
  
  void _createParticles() {
    final random = Random();
    for (int i = 0; i < particleCount; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 50.0 + random.nextDouble() * 100.0;
      final velocity = Vector2(
        cos(angle) * speed,
        sin(angle) * speed,
      );
      
      particles.add(_Particle(
        position: Vector2.zero(),
        velocity: velocity,
        size: 2.0 + random.nextDouble() * 3.0,
      ));
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    _elapsed += dt;
    
    if (_elapsed >= lifetime) {
      removeFromParent();
      return;
    }
    
    // Actualizar partículas
    for (final particle in particles) {
      particle.position.add(particle.velocity * dt);
      particle.velocity.scale(0.95); // Fricción
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final alpha = (1.0 - (_elapsed / lifetime)) * 255;
    final paint = Paint()
      ..color = color.withAlpha(alpha.toInt())
      ..style = PaintingStyle.fill;
    
    for (final particle in particles) {
      canvas.drawCircle(
        Offset(particle.position.x, particle.position.y),
        particle.size,
        paint,
      );
    }
  }
}

class _Particle {
  Vector2 position;
  Vector2 velocity;
  double size;
  
  _Particle({
    required this.position,
    required this.velocity,
    required this.size,
  });
}

/// Efecto de curación (círculo expandiéndose)
class HealEffect extends PositionComponent {
  final double maxRadius = 50.0;
  final double lifetime = 0.8;
  double _elapsed = 0.0;
  
  HealEffect({required Vector2 position}) {
    this.position = position;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    _elapsed += dt;
    if (_elapsed >= lifetime) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final progress = _elapsed / lifetime;
    final radius = maxRadius * progress;
    final alpha = ((1.0 - progress) * 150).toInt();
    
    final paint = Paint()
      ..color = Color.fromARGB(alpha, 0, 255, 0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawCircle(Offset.zero, radius, paint);
  }
}
