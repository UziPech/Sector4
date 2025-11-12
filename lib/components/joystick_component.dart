import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// Joystick virtual para controles móviles
class MobileJoystick extends PositionComponent with DragCallbacks {
  final double knobRadius = 30.0;
  final double baseRadius = 60.0;
  
  Vector2 _knobPosition = Vector2.zero();
  Vector2 _direction = Vector2.zero();
  bool _isDragging = false;
  
  final Paint _basePaint = Paint()
    ..color = const Color.fromRGBO(255, 255, 255, 0.3)
    ..style = PaintingStyle.fill;
    
  final Paint _knobPaint = Paint()
    ..color = const Color.fromRGBO(255, 255, 255, 0.7)
    ..style = PaintingStyle.fill;
  
  Vector2 get direction => _direction;
  bool get isActive => _isDragging;
  
  MobileJoystick({required Vector2 position}) : super(position: position) {
    size = Vector2.all(baseRadius * 2);
    anchor = Anchor.center;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Dibujar base del joystick
    canvas.drawCircle(
      Offset(baseRadius, baseRadius),
      baseRadius,
      _basePaint,
    );
    
    // Dibujar knob (perilla)
    final knobOffset = Offset(
      baseRadius + _knobPosition.x,
      baseRadius + _knobPosition.y,
    );
    canvas.drawCircle(knobOffset, knobRadius, _knobPaint);
  }
  
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _isDragging = true;
    _updateKnobPosition(event.canvasPosition - position);
  }
  
  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _updateKnobPosition(event.localEndPosition);
  }
  
  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _isDragging = false;
    _knobPosition = Vector2.zero();
    _direction = Vector2.zero();
  }
  
  void _updateKnobPosition(Vector2 localPosition) {
    // Calcular posición relativa al centro
    final delta = localPosition - Vector2(baseRadius, baseRadius);
    final distance = delta.length;
    
    if (distance > baseRadius - knobRadius) {
      // Limitar el knob al borde del joystick
      _knobPosition = delta.normalized() * (baseRadius - knobRadius);
    } else {
      _knobPosition = delta;
    }
    
    // Calcular dirección normalizada
    _direction = _knobPosition.normalized();
  }
}

/// Botón de disparo para móvil
class ShootButtonComponent extends PositionComponent with TapCallbacks {
  final double radius = 50.0;
  bool _isPressed = false;
  Function()? onPressed;
  
  final Paint _buttonPaint = Paint()
    ..color = const Color.fromRGBO(255, 0, 0, 0.5)
    ..style = PaintingStyle.fill;
    
  final Paint _buttonPressedPaint = Paint()
    ..color = const Color.fromRGBO(255, 100, 100, 0.7)
    ..style = PaintingStyle.fill;
  
  ShootButtonComponent({required Vector2 position, this.onPressed}) : super(position: position) {
    size = Vector2.all(radius * 2);
    anchor = Anchor.center;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final paint = _isPressed ? _buttonPressedPaint : _buttonPaint;
    canvas.drawCircle(Offset(radius, radius), radius, paint);
    
    // Dibujar icono de disparo (círculo pequeño en el centro)
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(radius, radius), radius * 0.3, iconPaint);
  }
  
  @override
  void onTapDown(TapDownEvent event) {
    _isPressed = true;
    onPressed?.call();
  }
  
  @override
  void onTapUp(TapUpEvent event) {
    _isPressed = false;
  }
  
  @override
  void onTapCancel(TapCancelEvent event) {
    _isPressed = false;
  }
}

/// Botón de curación (Mel) para móvil
class HealButtonComponent extends PositionComponent with TapCallbacks {
  final double radius = 45.0;
  bool _isPressed = false;
  bool isReady = true;
  Function()? onPressed;
  
  final Paint _buttonPaint = Paint()
    ..color = const Color.fromRGBO(0, 255, 0, 0.5)
    ..style = PaintingStyle.fill;
    
  final Paint _buttonPressedPaint = Paint()
    ..color = const Color.fromRGBO(100, 255, 100, 0.7)
    ..style = PaintingStyle.fill;
    
  final Paint _buttonDisabledPaint = Paint()
    ..color = const Color.fromRGBO(100, 100, 100, 0.3)
    ..style = PaintingStyle.fill;
  
  HealButtonComponent({required Vector2 position, this.onPressed}) : super(position: position) {
    size = Vector2.all(radius * 2);
    anchor = Anchor.center;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    Paint paint;
    if (!isReady) {
      paint = _buttonDisabledPaint;
    } else if (_isPressed) {
      paint = _buttonPressedPaint;
    } else {
      paint = _buttonPaint;
    }
    
    canvas.drawCircle(Offset(radius, radius), radius, paint);
    
    // Dibujar cruz de curación
    final crossPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
      
    final crossSize = radius * 0.5;
    canvas.drawLine(
      Offset(radius - crossSize, radius),
      Offset(radius + crossSize, radius),
      crossPaint,
    );
    canvas.drawLine(
      Offset(radius, radius - crossSize),
      Offset(radius, radius + crossSize),
      crossPaint,
    );
  }
  
  @override
  void onTapDown(TapDownEvent event) {
    if (isReady) {
      _isPressed = true;
      onPressed?.call();
    }
  }
  
  @override
  void onTapUp(TapUpEvent event) {
    _isPressed = false;
  }
  
  @override
  void onTapCancel(TapCancelEvent event) {
    _isPressed = false;
  }
}
