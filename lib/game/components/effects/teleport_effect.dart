import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../expediente_game.dart';

/// Efecto visual de teletransportación del boss
/// Círculo de sombras que se expande/contrae
class TeleportEffect extends PositionComponent 
    with HasGameReference<ExpedienteKorinGame> {
  
  final bool isFadeOut; // true = desaparición, false = aparición
  final double duration;
  double _timer = 0.0;
  
  TeleportEffect({
    required Vector2 position,
    this.isFadeOut = true,
    this.duration = 0.3,
  }) : super(position: position, anchor: Anchor.center);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(150); // Tamaño del efecto
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    _timer += dt;
    
    if (_timer >= duration) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final progress = (_timer / duration).clamp(0.0, 1.0);
    
    // Radio del círculo según si es fade out o fade in
    final radius = isFadeOut 
        ? 75 * (1 - progress) // Se contrae
        : 75 * progress; // Se expande
    
    // Opacidad
    final opacity = isFadeOut
        ? 0.8 * (1 - progress)
        : 0.8 * (1 - progress);
    
    // Círculo principal (negro/rojo)
    final mainPaint = Paint()
      ..color = Colors.black.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      radius,
      mainPaint,
    );
    
    // Anillo rojo exterior
    final ringPaint = Paint()
      ..color = Colors.red.withOpacity(opacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      radius,
      ringPaint,
    );
    
    // Partículas de sombra (pequeños círculos)
    final particlePaint = Paint()
      ..color = Colors.grey.withOpacity(opacity * 0.4)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * 3.14159 + (_timer * 3); // Rotación
      final particleRadius = radius * 0.8;
      final x = size.x / 2 + particleRadius * cos(angle);
      final y = size.y / 2 + particleRadius * sin(angle);
      
      canvas.drawCircle(
        Offset(x, y),
        5,
        particlePaint,
      );
    }
  }
}
