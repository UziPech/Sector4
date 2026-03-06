import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../expediente_game.dart';

class MissionNotification extends PositionComponent with HasGameReference<ExpedienteKorinGame> {
  String _title = '';
  String _subtitle = '';
  double _timer = 0.0;
  bool _isVisible = false;
  static const double _displayDuration = 4.0;
  static const double _fadeInDuration = 0.5;
  static const double _fadeOutDuration = 0.5;

  MissionNotification() : super(priority: 200); // Higher than HUD

  void show(String title, String subtitle) {
    _title = title;
    _subtitle = subtitle;
    _timer = 0.0;
    _isVisible = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isVisible) {
      _timer += dt;
      if (_timer >= _displayDuration + _fadeInDuration + _fadeOutDuration) {
        _isVisible = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_isVisible) return;

    double alpha = 1.0;
    if (_timer < _fadeInDuration) {
      alpha = _timer / _fadeInDuration;
    } else if (_timer > _displayDuration + _fadeInDuration) {
      alpha = 1.0 - ((_timer - (_displayDuration + _fadeInDuration)) / _fadeOutDuration);
    }
    alpha = alpha.clamp(0.0, 1.0);

    final screenSize = game.size;
    final centerX = screenSize.x / 2;
    final centerY = screenSize.y * 0.15; // Un poco más arriba

    // Dimensiones de la caja de diálogo
    const double boxWidth = 500.0;
    const double boxHeight = 100.0;
    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: boxWidth,
      height: boxHeight,
    );

    // Fondo Café Oscuro
    final bgPaint = Paint()
      ..color = const Color(0xFF1E140C).withValues(alpha: 0.95 * alpha) // Café muy oscuro
      ..style = PaintingStyle.fill;
    
    // Borde Óxido/Bronce
    final borderPaint = Paint()
      ..color = const Color(0xFF8B5A2B).withValues(alpha: 0.9 * alpha) // Color óxido/latón
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Dibujar la caja con bordes ligeramente redondeados o rectos (estilo viejo)
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4)); // Borde sutil
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    // Borde interno sutil para profundidad
    final innerBorderPaint = Paint()
      ..color = const Color(0xFFCDBA96).withValues(alpha: 0.2 * alpha) // Pergamino transparente
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final innerRect = rect.deflate(4);
    final innerRRect = RRect.fromRectAndRadius(innerRect, const Radius.circular(2));
    canvas.drawRRect(innerRRect, innerBorderPaint);


    // Título Principal
    final titlePainter = TextPainter(
      text: TextSpan(
        text: _title,
        style: TextStyle(
          color: const Color(0xFFE8D3A2).withValues(alpha: alpha), // Pergamino pálido
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 2.0,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: alpha), offset: const Offset(2, 2), blurRadius: 2), // Sombra dura clásica
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout(maxWidth: boxWidth - 30);
    titlePainter.paint(
      canvas, 
      Offset(centerX - titlePainter.width / 2, centerY - 25)
    );

    // Subtítulo
    final subPainter = TextPainter(
      text: TextSpan(
        text: _subtitle,
        style: TextStyle(
          color: const Color(0xFFC0A080).withValues(alpha: alpha), // Café claro
          fontSize: 14,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    subPainter.layout(maxWidth: boxWidth - 30);
    subPainter.paint(
      canvas, 
      Offset(centerX - subPainter.width / 2, centerY + 10)
    );
  }
}

