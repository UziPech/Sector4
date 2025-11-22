import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../expediente_game.dart';
import '../player.dart';

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
    
    // Remover si sale de la pantalla
    if (position.y > 1200) {
      removeFromParent();
    }
  }
  
  void _checkPlayerHit() {
    final player = game.player;
    final distance = position.distanceTo(player.position);
    
    if (distance <= 30 && !hasHit) {
      hasHit = true;
      player.takeDamage(damage);
      debugPrint('💥 Katana cayendo impacta: $damage daño');
      
      // Efecto visual de impacto
      // TODO: Agregar partículas
      
      // Remover después del impacto
      Future.delayed(const Duration(milliseconds: 100), () {
        removeFromParent();
      });
    }
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
