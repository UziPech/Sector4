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
    final centerY = screenSize.y * 0.2; // Top 20%

    // Background Strip
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.6 * alpha)
      ..style = PaintingStyle.fill;
    
    // Draw a strip across the screen
    canvas.drawRect(
      Rect.fromLTWH(0, centerY - 40, screenSize.x, 80),
      bgPaint,
    );
    
    // Borders
    final borderPaint = Paint()
      ..color = Colors.red.withOpacity(0.8 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    canvas.drawLine(
      Offset(0, centerY - 40),
      Offset(screenSize.x, centerY - 40),
      borderPaint
    );
    
    canvas.drawLine(
      Offset(0, centerY + 40),
      Offset(screenSize.x, centerY + 40),
      borderPaint
    );

    // Title
    final titlePainter = TextPainter(
      text: TextSpan(
        text: _title,
        style: TextStyle(
          color: Colors.redAccent.withOpacity(alpha),
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 4.0,
          shadows: [
            Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4),
            Shadow(color: Colors.red, offset: Offset(0, 0), blurRadius: 10),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(
      canvas, 
      Offset(centerX - titlePainter.width / 2, centerY - 30)
    );

    // Subtitle
    final subPainter = TextPainter(
      text: TextSpan(
        text: _subtitle,
        style: TextStyle(
          color: Colors.white.withOpacity(alpha),
          fontSize: 16,
          fontStyle: FontStyle.italic,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    subPainter.layout();
    subPainter.paint(
      canvas, 
      Offset(centerX - subPainter.width / 2, centerY + 10)
    );
  }
}
