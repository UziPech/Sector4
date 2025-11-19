import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import '../game/expediente_game.dart';
import 'stalker_enemy.dart';

class ObsessionObject extends PositionComponent 
    with HasGameReference<ExpedienteKorinGame>, CollisionCallbacks {
  
  final String id;
  final StalkerEnemy linkedEnemy;
  double health = 50.0;
  
  static final _paint = BasicPalette.red.paint()..style = PaintingStyle.fill;
  static final _glowPaint = Paint()
    ..color = Colors.red.withOpacity(0.5)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

  ObsessionObject({
    required this.id,
    required this.linkedEnemy,
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
    linkedEnemy.onObsessionDestroyed();
    removeFromParent();
    // Efectos de destrucción
  }
  
  @override
  void render(Canvas canvas) {
    // Efecto de brillo pulsante
    final double pulse = (game.currentTime() % 1.0);
    canvas.drawCircle(
      (size / 2).toOffset(),
      size.x / 2 + pulse * 5,
      _glowPaint,
    );
    
    canvas.drawRect(size.toRect(), _paint);
  }
}
