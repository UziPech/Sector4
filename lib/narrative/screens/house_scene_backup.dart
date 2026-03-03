import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dialogue_data.dart';
import '../models/interactable_data.dart';
import '../components/interactable_object.dart';
import '../components/dialogue_system.dart';
import '../components/skip_button.dart';
import '../services/save_system.dart';
import '../../main.dart'; // Para transiciÃ³n al juego de combate

/// Escena de la casa de Dan (CapÃ­tulo 1)
class HouseScene extends StatefulWidget {
  const HouseScene({super.key});

  @override
  State<HouseScene> createState() => _HouseSceneState();
}

class _HouseSceneState extends State<HouseScene> {
  // PosiciÃ³n del jugador
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
              text: 'Tres aÃ±os. Tres aÃ±os desde que el cÃ¡ncer te arrebatÃ³ de mÃ­. Y aÃºn duele como si fuera ayer.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Eras mi ancla, mi brÃºjula moral en un mundo de grises. SabÃ­as exactamente quÃ© decir, cÃ³mo calmar mis demonios.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Si estuvieras aquÃ­ ahora, sabrÃ­as quÃ© hacer. SabrÃ­as cÃ³mo proteger a Emma sin asfixiarla.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Pero no estÃ¡s. Y yo... yo solo soy un cascarÃ³n vacÃ­o tratando de recordar cÃ³mo ser humano.',
              type: DialogueType.internal,
            ),
          ],
        ),
      ),
      // HabitaciÃ³n de la hija
      InteractableData(
        id: 'daughter_room',
        name: 'HabitaciÃ³n de Emma',
        position: const Vector2(500, 150),
        size: const Vector2(80, 80),
        type: InteractableType.door,
        dialogue: DialogueSequence(
          id: 'daughter_room_dialogue',
          dialogues: [
            const DialogueData(
              speakerName: 'Dan',
              text: 'Su habitaciÃ³n... Intacta. Como un santuario a la vida que tenÃ­a antes de que yo la dejara ir.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Los pÃ³sters de bandas que nunca entendÃ­. Los libros de fÃ­sica cuÃ¡ntica que leÃ­a como si fueran novelas.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Ella es tan brillante, tan llena de vida. Todo lo que su madre era, y mÃ¡s.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Cuando me dijo "PapÃ¡, es Kioto. Es mi sueÃ±o", vi en sus ojos la misma determinaciÃ³n que Sarah tenÃ­a.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Â¿CÃ³mo podÃ­a negarle eso? Â¿CÃ³mo podÃ­a ser tan egoÃ­sta de mantenerla aquÃ­, cuidando de un fantasma?',
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
              text: 'Reportes clasificados. AnÃ¡lisis tÃ¡cticos. Perfiles de amenazas.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Todo abandonado. Polvo acumulÃ¡ndose sobre aÃ±os de servicio impecable.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Fui el mejor en lo que hacÃ­a. DesmantelÃ© cÃ©lulas terroristas, previne ataques, salvÃ© vidas.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Pero no pude salvar a la Ãºnica persona que realmente importaba.',
              type: DialogueType.internal,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'La agencia fue... comprensiva. "TÃ³mate el tiempo que necesites, Dan." Pero ambos sabÃ­amos la verdad.',
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
      // TELÃ‰FONO - Trigger principal
      InteractableData(
        id: 'phone',
        name: 'TelÃ©fono',
        position: const Vector2(400, 300),
        size: const Vector2(50, 50),
        type: InteractableType.phone,
        isOneTime: true,
        onInteract: () {
          // Este callback se ejecuta ANTES del diÃ¡logo
          debugPrint('TelÃ©fono sonando...');
        },
        dialogue: DialogueSequence(
          id: 'phone_call',
          dialogues: [
            const DialogueData(
              speakerName: 'Dan',
              text: 'Â¿Hola?',
              avatarPath: 'assets/avatars/dan.png',
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Dan, soy Marcus. Necesito que escuches con atenciÃ³n.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Marcus... Â¿QuÃ© pasa? Hace aÃ±os que no hablamos. Estoy fuera, lo sabes. Mi placa estÃ¡ oxidada.',
              avatarPath: 'assets/avatars/dan.png',
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Esto no es una reincorporaciÃ³n por rutina. Es sobre Emma. Hay una situaciÃ³n en JapÃ³n.',
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
              text: 'Â¿Emma? Â¿QuÃ© quieres decir con situaciÃ³n? Â¡Â¿QuÃ© le pasÃ³ a mi hija?!',
              avatarPath: 'assets/avatars/dan.png',
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'EstÃ¡ desaparecida. La universidad donde estudia es el epicentro de la actividad.',
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
              text: 'Â¡ExplÃ­cate! Â¿Por quÃ© me llamas a mÃ­ y no a la fuerza local?',
              avatarPath: 'assets/avatars/dan.png',
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'La fuerza local estÃ¡ abrumada. La agencia estÃ¡ saturada.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Tuvimos que crear una jerarquÃ­a para la contenciÃ³n, la CacerÃ­a de Ã‰lite.',
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
              text: 'Sector 2 - ContenciÃ³n Menor: Eliminan a los mutados bÃ¡sicos. Enemigos de bajo nivel que atacan por instinto y carecen de estrategia.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Sector 3 - InvestigaciÃ³n: Enfrentan Objetivos de Sector 3, mutados impulsados por la obsesiÃ³n o la tristeza profunda.',
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
              text: 'Sector 4 - Asalto de Ã‰lite: Esta es la cÃºspide. Nos enfrentamos a las Amenazas de Sector 4.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'No son idiotas; son cazadores tÃ¡cticos, con la inteligencia de un humano, liberados y corrompidos por el odio.',
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
              text: 'Nadie sobrevive solo en Sector 4, Dan. Te asignaremos a Mel, nuestra mejor agente de recuperaciÃ³n.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'Ella es la Ãºnica razÃ³n por la que no sucumbirÃ¡s antes de encontrar a Emma.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Emma estÃ¡ allÃ­.',
              avatarPath: 'assets/avatars/dan.png',
            ),
            const DialogueData(
              speakerName: 'Marcus',
              text: 'El brote estÃ¡ concentrado justo donde ella estaba estudiando. Necesitamos tu desesperaciÃ³n, Dan.',
              avatarPath: 'assets/avatars/marcus.png',
              type: DialogueType.phone,
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'MÃ¡ndame los protocolos y la ubicaciÃ³n exacta de la universidad.',
              avatarPath: 'assets/avatars/dan.png',
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Y envÃ­ame a ese apoyo. Â¿Mel, dijiste? No me importa quiÃ©n sea.',
              avatarPath: 'assets/avatars/dan.png',
            ),
            const DialogueData(
              speakerName: 'Dan',
              text: 'Solo dime quÃ© tengo que hacer para traerla de vuelta.',
              avatarPath: 'assets/avatars/dan.png',
            ),
          ],
          onComplete: () {
            // Marcar llamada como completada
            setState(() {
              _phoneCallCompleted = true;
            });
            // TransiciÃ³n al juego de combate despuÃ©s de un delay
            Future.delayed(const Duration(seconds: 2), () {
              _transitionToCombat();
            });
          },
        ),
      ),
    ];
  }

  void _showIntroDialogue() {
    // Mostrar monÃ³logo inicial de Dan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DialogueOverlay.show(
        context,
        DialogueSequence(
          id: 'intro',
          dialogues: const [
            DialogueData(
              speakerName: 'Dan',
              text: 'El silencio. Es mÃ¡s ensordecedor que cualquier explosiÃ³n en una operaciÃ³n encubierta.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'IrÃ³nico, Â¿no? Yo, que pasÃ© aÃ±os persiguiendo sombras, protegiendo fronteras, un investigador de Ã©lite...',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: '...y mi propia mente se convirtiÃ³ en la zona de exclusiÃ³n mÃ¡s peligrosa que jamÃ¡s pisÃ©.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Me retirÃ©. No, seamos honestos. Fui forzado a retirarme.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Cuando perdÃ­ a mi esposa, no perdÃ­ solo una persona; perdÃ­ el suelo, la gravedad que me mantenÃ­a anclado a la realidad.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Fui, en el campo, una responsabilidad, un riesgo de seguridad de proporciones Ã©picas.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'El duelo me convirtiÃ³ en un desecho, un YÅ«rei sin misiÃ³n. Â¿De quÃ© sirve la brillantez tÃ¡ctica cuando la voluntad de vivir se ha desvanecido?',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Y luego estaba ella. Mi hija. La Ãºnica luz que atravesaba esta niebla gris que se asentÃ³ sobre mÃ­.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Era mi Ãºltima lÃ­nea de defensa contra la CaÃ­da total.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Cuando me dijo que le habÃ­an aceptado el intercambio a JapÃ³n, que su nivel acadÃ©mico era excepcional...',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'SentÃ­ el pÃ¡nico, ese egoÃ­smo crudo que me gritaba que la encadenara aquÃ­, que la obligara a ser mi enfermera emocional.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Era la lucha mÃ¡s difÃ­cil que habÃ­a tenido, muy lejos de cualquier misiÃ³n antiterrorista.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Pero mi amor por ella, heredado de su madre, era mÃ¡s grande que mi miseria.',
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
              text: 'Es un orgullo. Es una prueba de que aÃºn existe algo puro en este mundo corrompido que yo patrullaba.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'AsÃ­ que la dejÃ© ir. ActuÃ© en contra de mi propio interÃ©s.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'La mandÃ© al otro lado del planeta para que pudiera florecer lejos de esta sombra que me consume.',
              type: DialogueType.internal,
            ),
          ],
        ),
      );
    });
  }

  void _transitionToCombat() async {
    // Marcar capÃ­tulo 1 como completado
    await SaveSystem.markChapterCompleted(1);
    
    // TransiciÃ³n a la escena de combate (tu juego actual)
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

    // InteracciÃ³n con E
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
        
        // Mostrar diÃ¡logo si existe
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

      // Aplicar movimiento con lÃ­mites de pantalla
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
                  color: Colors.black.withValues(alpha: 0.7),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CAPÃTULO 1: EL LLAMADO',
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
                          ? 'Objetivo: Ir a JapÃ³n'
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
            // BotÃ³n de skip
            const SkipButton(chapterNumber: 1),
            // Controles
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
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
    paint.color = Colors.brown.withValues(alpha: 0.5);
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
      color: Colors.white.withValues(alpha: 0.3),
      fontSize: 14,
      fontFamily: 'monospace',
    );

    // Sala
    textPainter.text = TextSpan(text: 'SALA', style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, const Offset(200, 200));

    // HabitaciÃ³n de Emma
    textPainter.text = TextSpan(text: 'HABITACIÃ“N EMMA', style: textStyle);
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

