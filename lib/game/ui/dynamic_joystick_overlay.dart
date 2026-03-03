import 'package:flutter/material.dart';
import 'package:flame/game.dart';

/// Joystick dinÃ¡mico que aparece donde el usuario toca (lado izquierdo)
/// Basado en la implementaciÃ³n de HouseScene (CapÃ­tulo 1)
class DynamicJoystickOverlay extends StatefulWidget {
  final Function(Vector2) onInput;

  const DynamicJoystickOverlay({super.key, required this.onInput});

  @override
  State<DynamicJoystickOverlay> createState() => _DynamicJoystickOverlayState();
}

class _DynamicJoystickOverlayState extends State<DynamicJoystickOverlay> {
  Offset? _joystickOrigin;
  Offset? _joystickPosition;
  bool _isJoystickActive = false;
  static const double _joystickRadius = 60.0;
  static const double _joystickKnobRadius = 25.0;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // 1. Ãrea sensible al tacto (Solo mitad izquierda)
        Positioned(
          left: 0,
          top: 0,
          width: screenSize.width / 2, // Limitar a la mitad izquierda
          height: screenSize.height,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (details) {
              // Ya no es necesario verificar dx < width / 2 porque el widget estÃ¡ limitado
              setState(() {
                _isJoystickActive = true;
                _joystickOrigin = details.globalPosition;
                _joystickPosition = details.globalPosition;
                widget.onInput(Vector2.zero());
              });
            },
            onPanUpdate: (details) {
              if (_isJoystickActive && _joystickOrigin != null) {
                setState(() {
                  final currentPos = details.globalPosition;
                  Vector2 delta = Vector2(
                    currentPos.dx - _joystickOrigin!.dx,
                    currentPos.dy - _joystickOrigin!.dy,
                  );
                  
                  if (delta.length > _joystickRadius) {
                    delta = delta.normalized() * _joystickRadius;
                  }
                  
                  _joystickPosition = Offset(
                    _joystickOrigin!.dx + delta.x,
                    _joystickOrigin!.dy + delta.y,
                  );
                  
                  // Normalizar input (-1.0 a 1.0)
                  final input = delta / _joystickRadius;
                  widget.onInput(input);
                });
              }
            },
            onPanEnd: (details) {
              _resetJoystick();
            },
            onPanCancel: () {
              _resetJoystick();
            },
            child: Container(color: Colors.transparent), // Necesario para capturar toques
          ),
        ),

        // 2. VisualizaciÃ³n del Joystick (Global, para no ser recortado)
        if (_isJoystickActive && _joystickOrigin != null && _joystickPosition != null) ...[
          // Base
          Positioned(
            left: _joystickOrigin!.dx - _joystickRadius,
            top: _joystickOrigin!.dy - _joystickRadius,
            child: IgnorePointer( // Ignorar toques en los visuales
              child: Container(
                width: _joystickRadius * 2,
                height: _joystickRadius * 2,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                ),
              ),
            ),
          ),
          // Knob (Perilla)
          Positioned(
            left: _joystickPosition!.dx - _joystickKnobRadius,
            top: _joystickPosition!.dy - _joystickKnobRadius,
            child: IgnorePointer(
              child: Container(
                width: _joystickKnobRadius * 2,
                height: _joystickKnobRadius * 2,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _resetJoystick() {
    setState(() {
      _isJoystickActive = false;
      _joystickOrigin = null;
      _joystickPosition = null;
      widget.onInput(Vector2.zero());
    });
  }
}

