import 'package:flutter/material.dart';

/// Overlay de efecto linterna que crea una zona de visibilidad circular
/// centrada en la posición del jugador. Usa un [CustomPainter] con GPU
/// para mantener el rendimiento óptimo.
class FlashlightOverlay extends StatelessWidget {
  /// Posición central de la luz en coordenadas de pantalla.
  final Offset center;

  /// Radio del círculo de visión completamente iluminado.
  final double innerRadius;

  /// Radio donde la sombra es completamente opaca (borde exterior del gradiente).
  final double outerRadius;

  /// Opacidad máxima de la sombra (0.0 - 1.0).
  final double shadowOpacity;

  /// Color base de la sombra.
  final Color shadowColor;

  const FlashlightOverlay({
    super.key,
    required this.center,
    this.innerRadius = 130.0,
    this.outerRadius = 250.0,
    this.shadowOpacity = 0.97,
    this.shadowColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _FlashlightPainter(
            center: center,
            innerRadius: innerRadius,
            outerRadius: outerRadius,
            shadowOpacity: shadowOpacity,
            shadowColor: shadowColor,
          ),
          // Ocupa todo el espacio disponible del padre
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _FlashlightPainter extends CustomPainter {
  final Offset center;
  final double innerRadius;
  final double outerRadius;
  final double shadowOpacity;
  final Color shadowColor;

  _FlashlightPainter({
    required this.center,
    required this.innerRadius,
    required this.outerRadius,
    required this.shadowOpacity,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Gradiente radial en un cuadrado perfecto anclado al centro de la luz
    // Así evitamos que se convierta en una elipse por el aspecto de la pantalla
    final rectGradient = Rect.fromCircle(center: center, radius: outerRadius);

    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        const Color(0x12FFA040),
        Colors.transparent,
        shadowColor.withValues(alpha: 0.0),
        shadowColor.withValues(alpha: shadowOpacity * 0.5),
        shadowColor.withValues(alpha: shadowOpacity),
      ],
      stops: [
        0.0,
        innerRadius / outerRadius * 0.5,
        innerRadius / outerRadius,
        (innerRadius / outerRadius) + 0.25,
        1.0,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rectGradient)
      ..blendMode = BlendMode.srcOver;

    // Pintamos toda la pantalla. Gracias a TileMode.clamp (por defecto en RadialGradient),
    // todo lo que quede fuera de `rectGradient` tomará el color del borde exterior de la sombra.
    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(screenRect, paint);
  }

  @override
  bool shouldRepaint(_FlashlightPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.innerRadius != innerRadius ||
        oldDelegate.outerRadius != outerRadius ||
        oldDelegate.shadowOpacity != shadowOpacity;
  }
}
