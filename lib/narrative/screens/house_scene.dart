import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dialogue_data.dart';
import '../models/interactable_data.dart';
import '../components/interactable_object.dart';
import '../components/dialogue_system.dart';
import '../components/skip_button.dart';
import '../services/save_system.dart';
import '../../main.dart'; // Para transición al juego de combate

/// Escena de la casa de Dan (Capítulo 1)
class HouseScene extends StatefulWidget {
  const HouseScene({Key? key}) : super(key: key);

  @override
  State<HouseScene> createState() => _HouseSceneState();
}

class _HouseSceneState extends State<HouseScene> {
  // Posición del jugador
  Vector2 _playerPosition = const Vector2(200, 300);
  final double _playerSpeed = 5.0;
  final double _playerSize = 40.0;

  // Control de movimiento
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  bool _isDialogueActive = false;
  bool _phoneCallCompleted = false;

  // Objetos interactuables
  late List<InteractableData> _interactables;
  
  // Focus y timer para movimiento
  late FocusNode _focusNode;
  Timer? _movementTimer;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _initializeInteractables();
    _showIntroDialogue();
    _startMovementLoop();
  }
  
  @override
  void dispose() {
    _focusNode.dispose();
    _movementTimer?.cancel();
    super.dispose();
  }
  
  void _startMovementLoop() {
    // Actualizar movimiento 60 veces por segundo
    _movementTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (mounted) {
        _updatePlayerPosition();
      }
    });
  }

  void _initializeInteractables() {
    _interactables = [
      // Foto de la esposa
      InteractableData(
        id: 'photo_wife',
        name: 'Foto de familia',
        position: const Vector2(100, 150),
        size: const Vector2(60, 60),
        type: InteractableType.photo,
        dialogue: DialogueSequence(
          id: 'photo_wife_dialogue',
          dialogues: [
            const DialogueData(
              speakerName: 'Dan',
              text: 'Sarah...',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Tres años. Tres años desde que el cáncer te arrebató de mí. Y aún duele como si fuera ayer.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Eras mi ancla, mi brújula moral en un mundo de grises. Sabías exactamente qué decir, cómo calmar mis demonios.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Si estuvieras aquí ahora, sabrías qué hacer. Sabrías cómo proteger a Emma sin asfixiarla.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Pero no estás. Y yo... yo solo soy un cascarón vacío tratando de recordar cómo ser humano.',
              type: DialogueType.internal,
            ),
          ],
        ),
      ),
      // Habitación de la hija
      InteractableData(
        id: 'daughter_room',
        name: 'Habitación de Emma',
        position: const Vector2(500, 150),
        size: const Vector2(80, 80),
        type: InteractableType.door,
        dialogue: DialogueSequence(
          id: 'daughter_room_dialogue',
          dialogues: [
            const DialogueData(
              speakerName: 'Dan',
              text: 'Su habitación... Intacta. Como un santuario a la vida que tenía antes de que yo la dejara ir.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Los pósters de bandas que nunca entendí. Los libros de física cuántica que leía como si fueran novelas.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Ella es tan brillante, tan llena de vida. Todo lo que su madre era, y más.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Cuando me dijo "Papá, es Kioto. Es mi sueño", vi en sus ojos la misma determinación que Sarah tenía.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: '¿Cómo podía negarle eso? ¿Cómo podía ser tan egoísta de mantenerla aquí, cuidando de un fantasma?',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Pero ahora... ahora solo quiero que vuelva a casa. Sana. Salva.',
              type: DialogueType.internal,
            ),
          ],
        ),
      ),
      // Escritorio con documentos
      InteractableData(
        id: 'desk',
        name: 'Escritorio',
        position: const Vector2(300, 400),
        size: const Vector2(70, 50),
        type: InteractableType.furniture,
        dialogue: DialogueSequence(
          id: 'desk_dialogue',
          dialogues: [
            const DialogueData(
              speakerName: 'Dan',
              text: 'Reportes clasificados. Análisis tácticos. Perfiles de amenazas.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Todo abandonado. Polvo acumulándose sobre años de servicio impecable.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Fui el mejor en lo que hacía. Desmantelé células terroristas, previne ataques, salvé vidas.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Pero no pude salvar a la única persona que realmente importaba.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'La agencia fue... comprensiva. "Tómate el tiempo que necesites, Dan." Pero ambos sabíamos la verdad.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Un agente roto es un agente muerto. Y yo estaba completamente destrozado.',
              type: DialogueType.internal,
            ),
          ],
        ),
      ),
      // TELÉFONO - Trigger principal
      InteractableData(
        id: 'phone',
        name: 'Teléfono',
        position: const Vector2(400, 300),
        size: const Vector2(50, 50),
        type: InteractableType.phone,
        isOneTime: true,
        onInteract: () {
          // Este callback se ejecuta ANTES del diálogo
          debugPrint('Teléfono sonando...');
        },
        dialogue: DialogueSequence(
          id: 'phone_call',
          dialogues: [
            const DialogueData(
              speakerName: 'Dan',
              text: '¿Hola?',
              avatarPath: 'assets/avatars/dan.png',
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Dan, soy Marcus. Necesito que escuches con atención.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Marcus... ¿Qué pasa? Hace años que no hablamos. Estoy fuera, lo sabes. Mi placa está oxidada.',
              avatarPath: 'assets/avatars/dan.png',
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Esto no es una reincorporación por rutina. Es sobre Emma. Hay una situación en Japón.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Un brote... de algo que nunca hemos clasificado.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: '¿Emma? ¿Qué quieres decir con situación? ¡¿Qué le pasó a mi hija?!',
              avatarPath: 'assets/avatars/dan.png',
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Está desaparecida. La universidad donde estudia es el epicentro de la actividad.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Dan, no son terroristas, no son soldados. Lo que vemos son mutados.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Seres que surgen tras tragedias extremas, de muertes violentas y un dolor incomprensible. No tienen alma en el sentido convencional.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: '¡Explícate! ¿Por qué me llamas a mí y no a la fuerza local?',
              avatarPath: 'assets/avatars/dan.png',
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'La fuerza local está abrumada. La agencia está saturada.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Tuvimos que crear una jerarquía para la contención, la Cacería de Élite.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Te voy a poner en el Sector 4, Dan, porque tu experiencia no es opcional, es vitalicia.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Sector 1 - Reconocimiento: Apenas pueden notificar bajas y clasificar los eventos de muerte. No pueden luchar.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Sector 2 - Contención Menor: Eliminan a los mutados básicos. Enemigos de bajo nivel que atacan por instinto y carecen de estrategia.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Sector 3 - Investigación: Enfrentan Objetivos de Sector 3, mutados impulsados por la obsesión o la tristeza profunda.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Son "rompecabezas de terror" que no responden a la fuerza bruta.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Sector 4 - Asalto de Élite: Esta es la cúspide. Nos enfrentamos a las Amenazas de Sector 4.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'No son idiotas; son cazadores tácticos, con la inteligencia de un humano, liberados y corrompidos por el odio.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Usan el entorno, flanquean. Son los demonios humanos. Necesitamos tu mente para enfrentarlos.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Nadie sobrevive solo en Sector 4, Dan. Te asignaremos a Mel, nuestra mejor agente de recuperación.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Ella es la única razón por la que no sucumbirás antes de encontrar a Emma.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Emma está allí.',
              avatarPath: 'assets/avatars/dan.png',
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'El brote está concentrado justo donde ella estaba estudiando. Necesitamos tu desesperación, Dan.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Mándame los protocolos y la ubicación exacta de la universidad.',
              avatarPath: 'assets/avatars/dan.png',
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Y envíame a ese apoyo. ¿Mel, dijiste? No me importa quién sea.',
              avatarPath: 'assets/avatars/dan.png',
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Solo dime qué tengo que hacer para traerla de vuelta.',
              avatarPath: 'assets/avatars/dan.png',
            ),
          ],
          onComplete: () {
            // Marcar llamada como completada
            setState(() {
              _phoneCallCompleted = true;
            });
            // Transición al juego de combate después de un delay
            Future.delayed(const Duration(seconds: 2), () {
              _transitionToCombat();
            });
          },
        ),
      ),
    ];
  }

  void _showIntroDialogue() {
    // Mostrar monólogo inicial de Dan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DialogueOverlay.show(
        context,
        DialogueSequence(
          id: 'intro',
          dialogues: const [
            DialogueData(
              speakerName: 'Dan',
              text: 'El silencio. Es más ensordecedor que cualquier explosión en una operación encubierta.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Irónico, ¿no? Yo, que pasé años persiguiendo sombras, protegiendo fronteras, un investigador de élite...',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: '...y mi propia mente se convirtió en la zona de exclusión más peligrosa que jamás pisé.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Me retiré. No, seamos honestos. Fui forzado a retirarme.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Cuando perdí a mi esposa, no perdí solo una persona; perdí el suelo, la gravedad que me mantenía anclado a la realidad.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Fui, en el campo, una responsabilidad, un riesgo de seguridad de proporciones épicas.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'El duelo me convirtió en un desecho, un Yūrei sin misión. ¿De qué sirve la brillantez táctica cuando la voluntad de vivir se ha desvanecido?',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Y luego estaba ella. Mi hija. La única luz que atravesaba esta niebla gris que se asentó sobre mí.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Era mi última línea de defensa contra la Caída total.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Cuando me dijo que le habían aceptado el intercambio a Japón, que su nivel académico era excepcional...',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Sentí el pánico, ese egoísmo crudo que me gritaba que la encadenara aquí, que la obligara a ser mi enfermera emocional.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Era la lucha más difícil que había tenido, muy lejos de cualquier misión antiterrorista.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Pero mi amor por ella, heredado de su madre, era más grande que mi miseria.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'No iba a permitir que mi tragedia se convirtiera en su ancla.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Su futuro es brillante. Kioto, esa universidad que tanto deseaba. Ella es una estudiante excepcional.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Es un orgullo. Es una prueba de que aún existe algo puro en este mundo corrompido que yo patrullaba.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Así que la dejé ir. Actué en contra de mi propio interés.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'La mandé al otro lado del planeta para que pudiera florecer lejos de esta sombra que me consume.',
              type: DialogueType.internal,
            ),
          ],
        ),
      );
    });
  }

  void _transitionToCombat() async {
    // Marcar capítulo 1 como completado
    await SaveSystem.markChapterCompleted(1);
    
    // Transición a la escena de combate (tu juego actual)
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MyApp(), // Tu juego de combate actual
        ),
      );
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (_isDialogueActive) return;

    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }

    // Interacción con E
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyE) {
      _tryInteract();
    }
  }

  void _tryInteract() {
    for (final interactable in _interactables) {
      if (interactable.isInRange(_playerPosition, 80)) {
        // Marcar como interactuado
        if (interactable.isOneTime && interactable.hasBeenInteracted) {
          return;
        }
        
        interactable.hasBeenInteracted = true;
        
        setState(() {
          _isDialogueActive = true;
        });
        
        // Ejecutar callback personalizado si existe
        interactable.onInteract?.call();
        
        // Mostrar diálogo si existe
        if (interactable.dialogue != null) {
          DialogueOverlay.show(
            context,
            interactable.dialogue!,
            onComplete: () {
              setState(() {
                _isDialogueActive = false;
              });
            },
          );
        } else {
          setState(() {
            _isDialogueActive = false;
          });
        }
        break;
      }
    }
  }

  void _updatePlayerPosition() {
    if (_isDialogueActive || DialogueOverlay.isActive) return;
    if (_pressedKeys.isEmpty) return;

    setState(() {
      double dx = 0;
      double dy = 0;

      if (_pressedKeys.contains(LogicalKeyboardKey.keyW) ||
          _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
        dy -= _playerSpeed;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.keyS) ||
          _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
        dy += _playerSpeed;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
          _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
        dx -= _playerSpeed;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
          _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
        dx += _playerSpeed;
      }

      // Aplicar movimiento con límites de pantalla
      final newX = (_playerPosition.x + dx).clamp(0.0, 750.0);
      final newY = (_playerPosition.y + dy).clamp(0.0, 550.0);
      _playerPosition = Vector2(newX, newY);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Solicitar focus cuando se construye por primera vez
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[800],
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          _handleKeyEvent(event);
          return KeyEventResult.handled;
        },
        child: Stack(
          children: [
            // Fondo de la casa (placeholder)
            Container(
              color: Colors.grey[700],
              child: CustomPaint(
                painter: _HouseLayoutPainter(),
                size: Size.infinite,
              ),
            ),
            // Objetos interactuables
            ..._interactables.map((interactable) {
              return InteractableObject(
                data: interactable,
                playerPosition: _playerPosition,
                interactionRadius: 80,
                onInteractionComplete: () {
                  setState(() {
                    _isDialogueActive = false;
                  });
                },
              );
            }),
            // Jugador (Dan)
            Positioned(
              left: _playerPosition.x - _playerSize / 2,
              top: _playerPosition.y - _playerSize / 2,
              child: Container(
                width: _playerSize,
                height: _playerSize,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  border: Border.all(color: Colors.white, width: 2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            // HUD
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CAPÍTULO 1: EL LLAMADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _phoneCallCompleted
                          ? 'Objetivo: Ir a Japón'
                          : 'Objetivo: Explorar la casa',
                      style: TextStyle(
                        color: Colors.yellow[700],
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Botón de skip
            const SkipButton(chapterNumber: 1),
            // Controles
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Text(
                  'WASD/Flechas: Mover\nE: Interactuar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter para el layout de la casa (placeholder visual)
class _HouseLayoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Paredes
    paint.color = Colors.brown;
    canvas.drawRect(
      Rect.fromLTWH(50, 100, 700, 500),
      paint,
    );

    // Divisiones de habitaciones
    paint.color = Colors.brown.withOpacity(0.5);
    canvas.drawLine(
      const Offset(400, 100),
      const Offset(400, 600),
      paint,
    );
    canvas.drawLine(
      const Offset(50, 350),
      const Offset(750, 350),
      paint,
    );

    // Labels de habitaciones
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final textStyle = TextStyle(
      color: Colors.white.withOpacity(0.3),
      fontSize: 14,
      fontFamily: 'monospace',
    );

    // Sala
    textPainter.text = TextSpan(text: 'SALA', style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, const Offset(200, 200));

    // Habitación de Emma
    textPainter.text = TextSpan(text: 'HABITACIÓN EMMA', style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, const Offset(450, 200));

    // Estudio
    textPainter.text = TextSpan(text: 'ESTUDIO', style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, const Offset(200, 450));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
