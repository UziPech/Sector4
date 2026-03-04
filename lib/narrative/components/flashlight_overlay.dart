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

  /// Calcula el radio interno global estandarizado para la linterna, basado en una dimensión de referencia.
  /// Se ha aumentado a petición del usuario para más luz.
  static double globalInnerRadius(double referenceDimension) {
    return (referenceDimension * 0.18).clamp(110.0, 200.0);
  }

  /// Calcula el radio externo global estandarizado para la linterna, basado en una dimensión de referencia.
  static double globalOuterRadius(double referenceDimension) {
    return (referenceDimension * 0.60).clamp(240.0, 400.0);
  }

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

    // ratio: qué fracción del outerRadius representa el innerRadius
    final ratio = (innerRadius / outerRadius).clamp(0.0, 0.9);

    final gradient = RadialGradient(
      center: Alignment.center,
      // 0.5 = el gradiente llena exactamente el rectGradient (círculo perfecto).
      // Antes era 1.0, lo que hacía el degradado el DOBLE de grande y
      // empujaba el negro completamente fuera de la pantalla.
      radius: 0.5,
      colors: [
        const Color(0x18FFA040), // Tinte cálido muy sutil en el centro
        Colors.transparent,
        shadowColor.withValues(alpha: 0.0),
        shadowColor.withValues(alpha: shadowOpacity * 0.6),
        shadowColor.withValues(alpha: shadowOpacity),
      ],
      stops: [
        0.0,
        ratio * 0.55,           // Fin de la zona central cálida
        ratio,                   // Inicio del negro (borde del círculo de luz)
        ratio + 0.15,           // Transición rápida al negro total
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
