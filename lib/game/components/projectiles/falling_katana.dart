import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../expediente_game.dart';
import '../player.dart';
import '../enemies/yurei_kohaa.dart';

/// Proyectil de katana que cae del cielo
/// Usado en el ataque "Lluvia de Acero" de On-Oyabun
class FallingKatana extends PositionComponent 
    with HasGameReference<ExpedienteKorinGame> {
  
  final double damage;
  final double fallSpeed;
  bool hasHit = false;
  
  FallingKatana({
    required Vector2 position,
    this.damage = 40.0,
    this.fallSpeed = 300.0,
  }) : super(position: position, anchor: Anchor.center);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(6, 40); // Katana vertical
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (hasHit) return;
    
    // Caer hacia abajo
    position.y += fallSpeed * dt;
    
    // Verificar impacto con jugador
    _checkPlayerHit();
    
    // Remover si sale de la pantalla (ajustado para mapa exterior 1500px)
    if (position.y > 1600) {
      removeFromParent();
    }
  }
  
  void _checkPlayerHit() {
    if (hasHit) return;
    
    final player = game.player;
    
    // Verificar impacto con jugador
    if (!player.isDead) {
      final distanceToPlayer = position.distanceTo(player.position);
      if (distanceToPlayer <= 30) {
        hasHit = true;
        player.takeDamage(damage);
        debugPrint('💥 Katana cayendo impacta al jugador: $damage daño');
        _removeAfterImpact();
        return;
      }
    }
    
    // Verificar impacto con Kohaa
    game.world.children.query<YureiKohaa>().forEach((kohaa) {
      if (!kohaa.isDead && !hasHit) {
        final distanceToKohaa = position.distanceTo(kohaa.position);
        if (distanceToKohaa <= 30) {
          hasHit = true;
          kohaa.takeDamage(damage);
          debugPrint('💥 Katana cayendo impacta a Kohaa: $damage daño');
          _removeAfterImpact();
        }
      }
    });
  }
  
  void _removeAfterImpact() {
    // Efecto visual de impacto
    // TODO: Agregar partículas
    
    // Remover después del impacto
    Future.delayed(const Duration(milliseconds: 100), () {
      removeFromParent();
    });
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Hoja (plateada)
    final bladePaint = Paint()
      ..color = const Color(0xFFC0C0C0)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y * 0.85),
      bladePaint,
    );
    
    // Empuñadura (roja)
    final handlePaint = Paint()
      ..color = const Color(0xFF8B0000)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, size.y * 0.85, size.x, size.y * 0.15),
      handlePaint,
    );
    
    // Borde brillante
    final edgePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawLine(
      const Offset(0, 0),
      Offset(0, size.y * 0.85),
      edgePaint,
    );
  }
}
