import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../expediente_game.dart';

class DestructibleObject extends PositionComponent with HasGameReference<ExpedienteKorinGame>, CollisionCallbacks {
  double health = 50.0;
  
  DestructibleObject({
    required Vector2 position,
  }) : super(position: position, size: Vector2(40, 40), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void render(Canvas canvas) {
    // Decoy looks similar but different color/style
    final paint = Paint()..color = Colors.grey;
    canvas.drawRect(size.toRect(), paint);
  }
  
  void takeDamage(double amount) {
    health -= amount;
    if (health <= 0) {
      removeFromParent();
    }
  }
}
