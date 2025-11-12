import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Límites del mundo - mantiene al jugador dentro del área visible
class WorldBounds {
  final double width;
  final double height;
  final double padding;
  
  WorldBounds({
    required this.width,
    required this.height,
    this.padding = 50.0,
  });
  
  /// Mantiene una posición dentro de los límites
  Vector2 clampPosition(Vector2 position, double entitySize) {
    final halfSize = entitySize / 2;
    return Vector2(
      position.x.clamp(
        -width / 2 + halfSize + padding,
        width / 2 - halfSize - padding,
      ),
      position.y.clamp(
        -height / 2 + halfSize + padding,
        height / 2 - halfSize - padding,
      ),
    );
  }
  
  /// Verifica si una posición está dentro de los límites
  bool isInBounds(Vector2 position, double entitySize) {
    final halfSize = entitySize / 2;
    return position.x >= -width / 2 + halfSize + padding &&
           position.x <= width / 2 - halfSize - padding &&
           position.y >= -height / 2 + halfSize + padding &&
           position.y <= height / 2 - halfSize - padding;
  }
  
  /// Obtiene una posición aleatoria dentro de los límites
  Vector2 getRandomPosition({double margin = 100.0}) {
    final random = DateTime.now().millisecondsSinceEpoch;
    final x = (random % width.toInt()).toDouble() - width / 2;
    final y = ((random * 7) % height.toInt()).toDouble() - height / 2;
    return Vector2(x, y);
  }
}

/// Componente visual para mostrar los límites del mundo
class WorldBoundsComponent extends PositionComponent {
  final WorldBounds bounds;
  
  final Paint _borderPaint = Paint()
    ..color = const Color.fromRGBO(255, 255, 255, 0.2)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  
  WorldBoundsComponent({required this.bounds}) {
    position = Vector2.zero();
    anchor = Anchor.center;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Dibujar borde del mundo
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: bounds.width - bounds.padding * 2,
        height: bounds.height - bounds.padding * 2,
      ),
      _borderPaint,
    );
  }
}
