import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
// import 'package:vector_math/vector_math_64.dart' hide Colors; // YA NO ES NECESARIO, Flame lo exporta

import 'narrative/screens/menu_screen.dart';
import 'narrative/screens/splash_screen.dart'; // Importar Splash Screen
import 'game/expediente_game.dart';
import 'game/ui/game_over_with_advice.dart'; // Nuevo import
import 'narrative/components/dialogue_system.dart'; // Importar sistema de diálogos
import 'game/ui/game_ui.dart'; // Importar nueva UI


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
  const ExpedienteKorinApp({Key? key}) : super(key: key);

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
  
  const MyApp({Key? key, this.startInBossMode = false}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Referencia al juego para pasarle inputs
  late ExpedienteKorinGame _game;
  
  // Joystick Virtual (Copiado de HouseScene)
  Offset? _joystickOrigin;
  Offset? _joystickPosition;
  bool _isJoystickActive = false;
  Vector2 _joystickInput = Vector2(0, 0);
  static const double _joystickRadius = 60.0;
  static const double _joystickKnobRadius = 25.0;

  @override
  void initState() {
    super.initState();
    _game = ExpedienteKorinGame(startInBossMode: widget.startInBossMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
        onPointerDown: (event) {
          // Solo activar en la mitad izquierda de la pantalla
          final screenSize = MediaQuery.of(context).size;
          if (event.position.dx < screenSize.width / 2) {
            setState(() {
              _isJoystickActive = true;
              _joystickOrigin = event.position;
              _joystickPosition = event.position;
              _joystickInput = Vector2(0, 0);
            });
            _game.updateJoystickInput(_joystickInput);
          }
        },
        onPointerMove: (event) {
          if (_isJoystickActive && _joystickOrigin != null) {
            setState(() {
              final currentPos = event.position;
              Vector2 delta = Vector2(
                currentPos.dx - _joystickOrigin!.dx,
                currentPos.dy - _joystickOrigin!.dy,
              );
              
              // Limitar el movimiento del knob al radio
              if (delta.length > _joystickRadius) {
                delta = delta.normalized() * _joystickRadius;
              }
              
              _joystickPosition = Offset(
                _joystickOrigin!.dx + delta.x,
                _joystickOrigin!.dy + delta.y,
              );
              
              // Calcular vector normalizado para el movimiento (0.0 a 1.0)
              _joystickInput = delta / _joystickRadius;
            });
            _game.updateJoystickInput(_joystickInput);
          }
        },
        onPointerUp: (event) {
          setState(() {
            _isJoystickActive = false;
            _joystickOrigin = null;
            _joystickPosition = null;
            _joystickInput = Vector2(0, 0);
          });
          _game.updateJoystickInput(_joystickInput);
        },
        child: Stack(
          children: [
            // 1. EL JUEGO (Fondo)
            GameWidget(
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
                'GameUI': (context, game) => GameUI(game: game as ExpedienteKorinGame),
              },
              initialActiveOverlays: const ['GameUI'],
            ),
            
            // 2. JOYSTICK UI (Superpuesto)
            if (_isJoystickActive && _joystickOrigin != null && _joystickPosition != null) ...[
              // Base del joystick
              Positioned(
                left: _joystickOrigin!.dx - _joystickRadius,
                top: _joystickOrigin!.dy - _joystickRadius,
                child: Container(
                  width: _joystickRadius * 2,
                  height: _joystickRadius * 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                ),
              ),
              // Knob del joystick
              Positioned(
                left: _joystickPosition!.dx - _joystickKnobRadius,
                top: _joystickPosition!.dy - _joystickKnobRadius,
                child: Container(
                  width: _joystickKnobRadius * 2,
                  height: _joystickKnobRadius * 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Overlay de Game Over
class GameOverOverlay extends StatelessWidget {
  final ExpedienteKorinGame game;

  const GameOverOverlay({
    Key? key,
    required this.game,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
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
