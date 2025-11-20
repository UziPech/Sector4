import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import '../game/expediente_game.dart';

/// Objeto destructible decorativo (señuelo)
/// Se ve igual al ObsessionObject pero no afecta al Stalker
class DestructibleObject extends PositionComponent 
    with HasGameReference<ExpedienteKorinGame>, CollisionCallbacks {
  
  double health = 50.0;
  final double maxHealth = 50.0;
  
  static final _paint = BasicPalette.red.paint()..style = PaintingStyle.fill;
  static final _glowPaint = Paint()
    ..color = Colors.red.withOpacity(0.5)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

  DestructibleObject({
    required Vector2 position,
  }) : super(position: position, size: Vector2.all(32.0));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }
  
  void takeDamage(double amount) {
    health -= amount;
    if (health <= 0) {
      destroy();
    }
  }
  
  
  void destroy() {
    // Buscar al Stalker en el mundo y notificarle
    for (final child in game.world.children) {
      if (child.runtimeType.toString().contains('StalkerEnemy')) {
        (child as dynamic).onObjectDestroyed(false); // false = decoy
        break;
      }
    }
    
    // Solo desaparece sin efecto especial
    removeFromParent();
  }
  
  @override
  void render(Canvas canvas) {
    // Efecto de brillo pulsante (idéntico al ObsessionObject)
    final double pulse = (game.currentTime() % 1.0);
    canvas.drawCircle(
      (size / 2).toOffset(),
      size.x / 2 + pulse * 5,
      _glowPaint,
    );
    
    // Barra de vida (para dar feedback visual)
    if (health < maxHealth) {
      const double barWidth = 32.0;
      const double barHeight = 3.0;
      const double offsetY = -8.0;
      
      canvas.drawRect(
        const Rect.fromLTWH(-barWidth / 2, offsetY, barWidth, barHeight),
        Paint()..color = const Color(0xFF404040),
      );
      
      final double healthPercent = (health / maxHealth).clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromLTWH(-barWidth / 2, offsetY, barWidth * healthPercent, barHeight),
        Paint()..color = const Color(0xFFFF0000),
      );
    }
    
    canvas.drawRect(size.toRect(), _paint);
  }
}
