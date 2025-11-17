import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../components/player.dart';
import '../components/mel.dart';

/// HUD del juego - Muestra información vital
class GameHUD extends PositionComponent {
  final PlayerCharacter player;
  final MelCharacter mel;
  
  GameHUD({
    required this.player,
    required this.mel,
  }) : super(priority: 100); // Alto priority para renderizar encima
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Fondo del HUD
    final hudRect = Rect.fromLTWH(10, 10, 300, 120);
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawRect(hudRect, bgPaint);
    
    // Borde
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(hudRect, borderPaint);
    
    // Texto de vida de Dan
    _drawText(
      canvas,
      'DAN',
      20,
      25,
      Colors.white,
      bold: true,
    );
    
    // Barra de vida de Dan
    _drawHealthBar(
      canvas,
      20,
      45,
      250,
      player.health,
      player.maxHealth,
      Colors.green,
    );
    
    // Texto de Mel
    _drawText(
      canvas,
      'MEL - SOPORTE VITAL',
      20,
      75,
      Colors.cyan,
      bold: true,
    );
    
    // Indicador de cooldown de Mel
    if (mel.canHeal) {
      _drawText(
        canvas,
        'DISPONIBLE (E)',
        20,
        95,
        Colors.yellow,
      );
    } else {
      final progress = (mel.healCooldownProgress * 100).toInt();
      _drawText(
        canvas,
        'RECARGANDO: $progress%',
        20,
        95,
        Colors.orange,
      );
      
      // Barra de cooldown
      _drawCooldownBar(
        canvas,
        20,
        110,
        250,
        mel.healCooldownProgress,
      );
    }
  }
  
  void _drawText(
    Canvas canvas,
    String text,
    double x,
    double y,
    Color color, {
    bool bold = false,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: bold ? 14 : 12,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }
  
  void _drawHealthBar(
    Canvas canvas,
    double x,
    double y,
    double width,
    double current,
    double max,
    Color color,
  ) {
    // Fondo de la barra
    final bgPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(x, y, width, 20),
      bgPaint,
    );
    
    // Barra de vida
    final healthPercent = (current / max).clamp(0.0, 1.0);
    final healthPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(x, y, width * healthPercent, 20),
      healthPaint,
    );
    
    // Borde
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(
      Rect.fromLTWH(x, y, width, 20),
      borderPaint,
    );
    
    // Texto de vida
    _drawText(
      canvas,
      '${current.toInt()} / ${max.toInt()}',
      x + width / 2 - 30,
      y + 4,
      Colors.white,
    );
  }
  
  void _drawCooldownBar(
    Canvas canvas,
    double x,
    double y,
    double width,
    double progress,
  ) {
    // Fondo
    final bgPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(x, y, width, 10),
      bgPaint,
    );
    
    // Progreso
    final progressPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(x, y, width * progress, 10),
      progressPaint,
    );
    
    // Borde
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(
      Rect.fromLTWH(x, y, width, 10),
      borderPaint,
    );
  }
}
