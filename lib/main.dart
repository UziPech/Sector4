import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
// import 'package:vector_math/vector_math_64.dart' hide Colors; // YA NO ES NECESARIO, Flame lo exporta

import 'narrative/screens/splash_screen.dart'; // Importar Splash Screen
import 'game/expediente_game.dart';
import 'game/ui/game_over_with_advice.dart'; // Nuevo import
import 'narrative/components/dialogue_system.dart'; // Importar sistema de diálogos
import 'game/ui/game_ui.dart'; // Importar nueva UI
import 'narrative/components/flashlight_overlay.dart'; // Efecto linterna


void main() async {
  // Asegurar que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();
  
  // Forzar orientación horizontal (landscape)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Ocultar la barra de estado para experiencia inmersiva
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  // Inicializa y corre la aplicación (empieza en el menú)
  runApp(const ExpedienteKorinApp());
}

/// Aplicación principal - Inicia en el menú
class ExpedienteKorinApp extends StatelessWidget {
  const ExpedienteKorinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // Iniciar con Splash Screen
    );
  }
}

/// Widget para el juego de combate (usado después de las escenas narrativas)
class MyApp extends StatefulWidget {
  final bool startInBossMode;
  
  const MyApp({super.key, this.startInBossMode = false});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Referencia al juego para pasarle inputs
  late ExpedienteKorinGame _game;

  @override
  void initState() {
    super.initState();
    _game = ExpedienteKorinGame(startInBossMode: widget.startInBossMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          'GameOver': (context, game) => GameOverWithAdvice(
            game: game as ExpedienteKorinGame,
          ),
          'DialogueOverlay': (context, game) {
            final korinGame = game as ExpedienteKorinGame;
            if (korinGame.currentDialogue == null) return const SizedBox.shrink();
            return DialogueSystem(
              sequence: korinGame.currentDialogue!,
              onSequenceComplete: korinGame.onDialogueComplete,
            );
          },
          // Linterna con parpadeo â€” capa propia, debajo de GameUI
          'FlashlightLayer': (context, game) => const IgnorePointer(
            child: _CombatFlashlightWidget(),
          ),
          'GameUI': (context, game) => GameUI(game: game as ExpedienteKorinGame),
        },
        // FlashlightLayer va PRIMERO para quedar bajo GameUI en el Stack
        initialActiveOverlays: const ['FlashlightLayer', 'GameUI'],
      ),
    );
  }
}

/// Overlay de Game Over
class GameOverOverlay extends StatelessWidget {
  final ExpedienteKorinGame game;

  const GameOverOverlay({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Colors.red,
                fontSize: 64,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'La Caída fue inevitable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontStyle: FontStyle.italic,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: () {
                game.restart();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
              ),
              child: const Text(
                'REINTENTAR',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const ExpedienteKorinApp(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
              ),
              child: const Text(
                'MENÚ PRINCIPAL',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Linterna de combate con parpadeo atmosférico y radios adaptativos
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CombatFlashlightWidget extends StatefulWidget {
  const _CombatFlashlightWidget();

  @override
  State<_CombatFlashlightWidget> createState() => _CombatFlashlightWidgetState();
}

class _CombatFlashlightWidgetState extends State<_CombatFlashlightWidget>
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
  /// t âˆˆ [0.0, 1.0] â€” valor del AnimationController
  double _flickerOpacity(double t) {
    final v1 = 0.5 + 0.5 * _sinApprox(t * 1.7 * 6.2832);
    final v2 = 0.5 + 0.5 * _sinApprox(t * 2.9 * 6.2832 + 1.1);
    // Opacidad de sombra oscila suavemente entre 0.88 y 0.97
    return 0.88 + 0.09 * (v1 * 0.6 + v2 * 0.4);
  }

  /// Aproximación de sin usando identidades angulares sin importar dart:math
  double _sinApprox(double x) {
    // Normalizar a [-Ï€, Ï€]
    x = x % 6.2832;
    if (x > 3.14159) x -= 6.2832;
    // Polinomio de Bhaskara (muy preciso para este uso)
    final x2 = x * x;
    return x * (1 - x2 * (1 / 6 - x2 / 120));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flickerCtrl,
      builder: (_, __) {
        final size = MediaQuery.of(context).size;
        final shortSide = size.shortestSide;

        // Radios adaptativos: proporcionales al lado corto de la pantalla
        final innerR = (shortSide * 0.20).clamp(80.0, 200.0);
        final outerR = (shortSide * 0.48).clamp(160.0, 400.0);

        // Opacidad de sombra con parpadeo sutil
        final opacity = _flickerOpacity(_flickerCtrl.value);

        return FlashlightOverlay(
          center: Offset(size.width / 2, size.height / 2),
          innerRadius: innerR,
          outerRadius: outerR,
          shadowOpacity: opacity,
        );
      },
    );
  }
}

