import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Efecto visual especial para resurrección de Kijin
/// Usa colores rosa/púrpura en vez de verde
class KijinResurrectionEffect extends PositionComponent {
  double _lifetime = 1.5; // Más largo que normal
  double _timer = 0.0;
  
  KijinResurrectionEffect({required Vector2 position})
      : super(position: position, size: Vector2.all(150), anchor: Anchor.center);
  
  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    
    if (_timer >= _lifetime) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final progress = _timer / _lifetime;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    
    // Círculos expansivos rosa/púrpura
    for (int i = 0; i < 4; i++) {
      final delay = i * 0.15;
      final adjustedProgress = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      final radius = 25.0 + (adjustedProgress * 50.0);
      
      final paint = Paint()
        ..color = (i % 2 == 0 
            ? const Color(0xFFFF1493) // Deep pink
            : const Color(0xFF9370DB)) // Medium purple
            .withOpacity(opacity * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      
      canvas.drawCircle(
        (size / 2).toOffset(),
        radius,
        paint,
      );
    }
    
    // Partículas ascendentes (rosa)
    final particlePaint = Paint()
      ..color = const Color(0xFFFF69B4).withOpacity(opacity * 0.9)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * pi * 2;
      final distance = progress * 40.0;
      final x = (size.x / 2) + (distance * cos(angle));
      final y = (size.y / 2) - (progress * 50.0) + (distance * sin(angle));
      
      canvas.drawCircle(
        Offset(x, y),
        6.0 * (1.0 - progress),
        particlePaint,
      );
    }
    
    // Aura interior brillante
    final auraPaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.5)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      15.0 * (1.0 - progress * 0.5),
      auraPaint,
    );
    
    // Texto "REDIMIDA"
    if (progress < 0.8) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'REDIMIDA',
          style: TextStyle(
            color: const Color(0xFFFF69B4).withOpacity(opacity),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(opacity * 0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.x - textPainter.width) / 2,
          -45.0 - (progress * 25.0),
        ),
      );
    }
  }
  
  @override
  int get priority => 100;
}
