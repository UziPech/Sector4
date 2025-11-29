import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../expediente_game.dart';
import 'stalker_enemy.dart';

class ObsessionObject extends PositionComponent with HasGameReference<ExpedienteKorinGame>, CollisionCallbacks {
  final String id;
  final StalkerEnemy linkedEnemy;
  
  double health = 200.0; // Resistente
  final double maxHealth = 200.0;
  
  ObsessionObject({
    required this.id,
    required this.linkedEnemy,
    required Vector2 position,
  }) : super(position: position, size: Vector2(40, 40), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void render(Canvas canvas) {
    // Objeto brillante/pulsante que representa la obsesión
    final paint = Paint()..color = Colors.purpleAccent;
    canvas.drawRect(size.toRect(), paint);
    
    // Barra de vida
    final hpBarWidth = size.x;
    final hpBarHeight = 5.0;
    final hpPercent = health / maxHealth;
    
    canvas.drawRect(
      Rect.fromLTWH(0, -10, hpBarWidth, hpBarHeight),
      Paint()..color = Colors.red.withOpacity(0.5),
    );
    
    canvas.drawRect(
      Rect.fromLTWH(0, -10, hpBarWidth * hpPercent, hpBarHeight),
      Paint()..color = Colors.green,
    );
  }
  
  void takeDamage(double amount) {
    health -= amount;
    if (health <= 0) {
      _destroy();
    }
  }
  
  void _destroy() {
    linkedEnemy.onObsessionObjectDestroyed();
    removeFromParent();
  }
}
