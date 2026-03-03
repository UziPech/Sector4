import 'package:flutter/material.dart';
import '../../game/expediente_game.dart';
import '../../narrative/components/flashlight_overlay.dart';

/// Linterna de combate con parpadeo atmosférico y radios adaptativos
class CombatFlashlightWidget extends StatefulWidget {
  final ExpedienteKorinGame game;

  const CombatFlashlightWidget({super.key, required this.game});

  @override
  State<CombatFlashlightWidget> createState() => _CombatFlashlightWidgetState();
}

class _CombatFlashlightWidgetState extends State<CombatFlashlightWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _flickerCtrl;

  @override
  void initState() {
    super.initState();
    // Ciclo rápido para update continuo del flicker
    _flickerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _flickerCtrl.dispose();
    super.dispose();
  }

  /// Combina dos senos a frecuencias ligeramente distintas
  /// para producir un parpadeo no periódico, similar a una vela real.
  /// t ∈ [0.0, 1.0] — valor del AnimationController
  double _flickerOpacity(double t) {
    final v1 = 0.5 + 0.5 * _sinApprox(t * 1.7 * 6.2832);
    final v2 = 0.5 + 0.5 * _sinApprox(t * 2.9 * 6.2832 + 1.1);
    // Opacidad de sombra oscila suavemente entre 0.95 y 1.0 (negro casi total siempre)
    return 0.95 + 0.05 * (v1 * 0.6 + v2 * 0.4);
  }

  /// Aproximación de sin usando identidades angulares sin importar dart:math
  double _sinApprox(double x) {
    // Normalizar a [-π, π]
    x = x % 6.2832;
    if (x > 3.14159) x -= 6.2832;
    // Polinomio de Bhaskara (muy preciso para este uso)
    final x2 = x * x;
    return x * (1 - x2 * (1 / 6 - x2 / 120));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.game.isExteriorNotifier,
      builder: (context, isExterior, child) {
        return AnimatedBuilder(
          animation: _flickerCtrl,
          builder: (_, __) {
            final size = MediaQuery.of(context).size;

            // Radios adaptativos 
            // Para que la oscuridad se note más, reduciremos los radios un poco
            // innerR dictamina dónde empieza a desvanecerse la luz central al negro.
            // outerR dictamina dónde el negro se vuelve opaco por completo.
            final innerR = isExterior ? size.width * 0.25 : FlashlightOverlay.globalInnerRadius(size.width);
            final outerR = isExterior ? size.width * 0.45 : FlashlightOverlay.globalOuterRadius(size.width);

            // Opacidad de sombra con parpadeo sutil
            // El usuario pidió que se note un poco más la oscuridad en el exterior.
            // Regresaremos el multiplicador a 0.9 en lugar de 0.8 para una negrura más profunda.
            final baseOpacity = _flickerOpacity(_flickerCtrl.value);
            final opacity = isExterior ? baseOpacity * 0.9 : baseOpacity;

            return FlashlightOverlay(
              center: Offset(size.width / 2, size.height / 2),
              innerRadius: innerR,
              outerRadius: outerR,
              shadowOpacity: opacity,
            );
          },
        );
      },
    );
  }
}
