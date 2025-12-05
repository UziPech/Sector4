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
  
  // Cached TextPainter
  TextPainter? _promptPainter;
  String _lastPromptText = '';
  double _lastOpacity = -1.0;
  
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
  
  /// Determina si esta tumba es de un Kijin
  bool get isKijin => enemyType.contains('kijin');
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Calcular opacidad basada en tiempo de vida
    final opacity = (lifetime / _defaultLifetime).clamp(0.0, 1.0);
    
    // Efecto de pulso
    final pulseScale = 1.0 + sin(_pulseTimer) * 0.1;
    
    // Color según tipo de enemigo
    final tombColor = isKijin ? Colors.red : Colors.purple;
    final promptColor = isKijin ? Colors.red : Colors.green;
    
    // Círculo base (tumba)
    final basePaint = Paint()
      ..color = tombColor.withOpacity(0.3 * opacity)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _tombRadius * pulseScale,
      basePaint,
    );
    
    // Borde luminoso
    final borderPaint = Paint()
      ..color = tombColor.withOpacity(0.8 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isKijin ? 3 : 2;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _tombRadius * pulseScale,
      borderPaint,
    );
    
    // Holograma central (cruz o símbolo)
    final symbolPaint = Paint()
      ..color = Colors.white.withOpacity(0.9 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isKijin ? 3 : 2;
    
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
      final promptText = isKijin ? 'E - Revivir (2 slots)' : 'E - Revivir';
      
      // Actualizar painter solo si cambia significativamente o no existe
      // Nota: La opacidad cambia cada frame, pero el layout del texto es lo costoso.
      // Podemos actualizar el painter solo cuando cambia el texto, y aplicar opacidad al pintarlo o 
      // si usamos TextSpan con color base, solo necesitamos layout una vez si el texto no cambia.
      // Pero TextPainter no tiene "setOpacity". Recrear TextPainter es costoso por el layout.
      // Solución: Crear el painter con color sólido y usar saveLayer/opacity en el canvas si fuera necesario,
      // pero TextPainter usa el color del estilo. 
      // Optimizacion: Solo hacer layout si el texto cambia. El estilo lo podemos actualizar? No fácilmente.
      // Mejor: Cachear el layout. Si la opacidad cambia, lamentablemente hay que repintar, pero podemos
      // al menos evitar instanciar el objeto si la opacidad no cambia mucho (aunque cambia cada frame por lifetime).
      // COMPROMISO: Crear el painter una sola vez (layout) con color blanco solido, y pintar con opacidad en el canvas? No, TextPainter ignora tint.
      // Solución practica: Cachear el painter con el color base, y solo actualizarlo si la opacidad cambia > 0.1 o así? Descartado.
      // MEJOR: Usar un color fijo en el painter y pintar en un layer con opacidad? 
      // Vamos a simplemente cachear el objeto y el layout y solo recrearlo, ya que el texto es lo que importa.
      
      if (_promptPainter == null || promptText != _lastPromptText || (opacity - _lastOpacity).abs() > 0.05) {
         _lastPromptText = promptText;
         _lastOpacity = opacity;
         
         _promptPainter = TextPainter(
          text: TextSpan(
            text: promptText,
            style: TextStyle(
              color: promptColor.withOpacity(opacity),
              fontSize: isKijin ? 11 : 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
      }
      
      if (_promptPainter != null) {
        _promptPainter!.paint(
          canvas,
          Offset(
            center.dx - _promptPainter!.width / 2,
            center.dy - _tombRadius - 20,
          ),
        );
      }
    } else {
      _promptPainter = null; // Liberar cuando no se muestra
    }
  }
  
  /// Verifica si el jugador está en rango de interacción
  bool isPlayerInRange() => _isPlayerNearby;
  
  /// Obtiene el tipo de enemigo para resucitar
  String getEnemyType() => enemyType;
}
