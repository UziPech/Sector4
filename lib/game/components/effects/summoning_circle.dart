import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Efecto de círculo de invocación para On-Oyabun
/// Se dibuja en el suelo antes de que aparezca el jefe
class SummoningCircle extends PositionComponent {
  double animationProgress = 0.0;
  final double animationDuration = 5.0; // 5 segundos de invocación
  final double circleRadius = 200.0;
  
  // Callback cuando se completa la invocación
  final VoidCallback? onSummoningComplete;
  
  SummoningCircle({
    required Vector2 position,
    this.onSummoningComplete,
  }) : super(position: position, anchor: Anchor.center);
  
  @override
  void update(double dt) {
    super.update(dt);
    
    animationProgress += dt / animationDuration;
    
    if (animationProgress >= 1.0) {
      // Completar invocación
      onSummoningComplete?.call();
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final progress = animationProgress.clamp(0.0, 1.0);
    
    // Círculo exterior expansivo (rojo)
    final outerRadius = circleRadius * progress;
    final outerPaint = Paint()
      ..color = Colors.red.withOpacity(0.3 * (1.0 - progress * 0.5))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawCircle(Offset.zero, outerRadius, outerPaint);
    
    // Círculo interior (más intenso)
    final innerRadius = circleRadius * 0.7 * progress;
    final innerPaint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(Offset.zero, innerRadius, innerPaint);
    
    // Símbolos yakuza rotando (28 símbolos para las 28 víctimas)
    if (progress > 0.3) {
      _drawRotatingSymbols(canvas, progress);
    }
    
    // Partículas rojas ascendentes
    if (progress > 0.5) {
      _drawParticles(canvas, progress);
    }
  }
  
  void _drawRotatingSymbols(Canvas canvas, double progress) {
    final symbolCount = 28;
    final rotationSpeed = progress * 2 * pi;
    final symbolRadius = circleRadius * 0.85;
    
    final symbolPaint = Paint()
      ..color = Colors.red.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < symbolCount; i++) {
      final angle = (i / symbolCount) * 2 * pi + rotationSpeed;
      final x = cos(angle) * symbolRadius;
      final y = sin(angle) * symbolRadius;
      
      // Dibujar pequeño símbolo (círculo como placeholder)
      canvas.drawCircle(Offset(x, y), 3.0, symbolPaint);
    }
  }
  
  void _drawParticles(Canvas canvas, double progress) {
    final particleCount = 20;
    final random = Random(42); // Seed fijo para consistencia
    
    final particlePaint = Paint()
      ..color = Colors.red.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < particleCount; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * circleRadius;
      final height = (progress - 0.5) * 100; // Ascendentes
      
      final x = cos(angle) * distance;
      final y = sin(angle) * distance - height;
      
      final size = random.nextDouble() * 2 + 1;
      canvas.drawCircle(Offset(x, y), size, particlePaint);
    }
  }
  
  @override
  int get priority => -50; // Renderizar debajo del jefe pero encima del fondo
}
