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
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Gradiente radial: transparente en el centro → opaco en el borde
    final gradient = RadialGradient(
      center: Alignment(
        (center.dx / size.width) * 2 - 1,
        (center.dy / size.height) * 2 - 1,
      ),
      radius: outerRadius / (size.shortestSide * 0.5),
      colors: [
        const Color(0x12FFA040),                                      // Núcleo ámbar cálido (muy sutil)
        Colors.transparent,                                           // Centro iluminado
        shadowColor.withValues(alpha: 0.0),                           // Aún claro
        shadowColor.withValues(alpha: shadowOpacity * 0.5),           // Transición suave
        shadowColor.withValues(alpha: shadowOpacity),                 // Sombra completa
      ],
      stops: [
        0.0,
        innerRadius / outerRadius * 0.5,                              // Borde del núcleo cálido
        innerRadius / outerRadius,                                    // Donde empieza la sombra
        (innerRadius / outerRadius) + 0.25,                           // Zona de transición
        1.0,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..blendMode = BlendMode.srcOver;

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_FlashlightPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.innerRadius != innerRadius ||
        oldDelegate.outerRadius != outerRadius ||
        oldDelegate.shadowOpacity != shadowOpacity;
  }
}
