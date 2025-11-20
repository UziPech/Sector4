import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../expediente_game.dart';

/// Tumba que aparece cuando un enemigo muere
/// Permite a Mel resucitar al enemigo como aliado temporal
class EnemyTomb extends PositionComponent
    with HasGameReference<ExpedienteKorinGame>, CollisionCallbacks {
  final String enemyType;
  double lifetime;
  double _pulseTimer = 0.0;
  bool _isPlayerNearby = false;
  
  static const double _tombRadius = 20.0;
  static const double _interactionRange = 50.0;
  static const double _defaultLifetime = 5.0;
  
  EnemyTomb({
    required Vector2 position,
    required this.enemyType,
    this.lifetime = _defaultLifetime,
  }) : super(position: position);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(_tombRadius * 2);
    anchor = Anchor.center;
    
    // Agregar hitbox para detección de proximidad
    add(CircleHitbox(
      radius: _tombRadius,
      collisionType: CollisionType.passive,
    ));
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Actualizar tiempo de vida
    lifetime -= dt;
    if (lifetime <= 0) {
      removeFromParent();
      return;
    }
    
    // Actualizar animación de pulso
    _pulseTimer += dt * 2;
    
    // Verificar proximidad del jugador
    final distanceToPlayer = position.distanceTo(game.player.position);
    _isPlayerNearby = distanceToPlayer < _interactionRange;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Calcular opacidad basada en tiempo de vida
    final opacity = (lifetime / _defaultLifetime).clamp(0.0, 1.0);
    
    // Efecto de pulso
    final pulseScale = 1.0 + sin(_pulseTimer) * 0.1;
    
    // Círculo base (tumba)
    final basePaint = Paint()
      ..color = Colors.purple.withOpacity(0.3 * opacity)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _tombRadius * pulseScale,
      basePaint,
    );
    
    // Borde luminoso
    final borderPaint = Paint()
      ..color = Colors.purple.withOpacity(0.8 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _tombRadius * pulseScale,
      borderPaint,
    );
    
    // Holograma central (cruz o símbolo)
    final symbolPaint = Paint()
      ..color = Colors.white.withOpacity(0.9 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final center = (size / 2).toOffset();
    final symbolSize = _tombRadius * 0.5;
    
    // Dibujar cruz
    canvas.drawLine(
      Offset(center.dx - symbolSize, center.dy),
      Offset(center.dx + symbolSize, center.dy),
      symbolPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - symbolSize),
      Offset(center.dx, center.dy + symbolSize),
      symbolPaint,
    );
    
    // Indicador de interacción si el jugador está cerca
    if (_isPlayerNearby) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'E - Revivir',
          style: TextStyle(
            color: Colors.green.withOpacity(opacity),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - _tombRadius - 20,
        ),
      );
    }
  }
  
  /// Verifica si el jugador está en rango de interacción
  bool isPlayerInRange() => _isPlayerNearby;
  
  /// Obtiene el tipo de enemigo para resucitar
  String getEnemyType() => enemyType;
}
