import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Efecto de flash de pantalla (blanco/color) para momentos dramáticos
class ScreenFlash extends PositionComponent {
  final Color flashColor;
  final double duration;
  final VoidCallback? onComplete;
  
  double _elapsed = 0.0;
  double _opacity = 0.0;
  
  ScreenFlash({
    required Vector2 screenSize,
    this.flashColor = Colors.white,
    this.duration = 0.5,
    this.onComplete,
  }) : super(
    position: Vector2.zero(),
    size: screenSize,
    priority: 1000, // Muy alto para renderizar sobre todo
  );
  
  @override
  void update(double dt) {
    super.update(dt);
    
    _elapsed += dt;
    
    if (_elapsed < duration / 2) {
      // Fade in (0 a 1)
      _opacity = (_elapsed / (duration / 2)).clamp(0.0, 1.0);
    } else if (_elapsed < duration) {
      // Fade out (1 a 0)
      final fadeOutProgress = (_elapsed - duration / 2) / (duration / 2);
      _opacity = (1.0 - fadeOutProgress).clamp(0.0, 1.0);
    } else {
      // Completado
      _opacity = 0.0;
      onComplete?.call();
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final paint = Paint()
      ..color = flashColor.withOpacity(_opacity)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(size.toRect(), paint);
  }
}
