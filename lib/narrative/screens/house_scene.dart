import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dialogue_data.dart';
import '../models/interactable_data.dart';
import '../models/room_data.dart';
import '../systems/room_manager.dart';
import '../components/interactable_object.dart';
import '../components/dialogue_system.dart';
import '../services/save_system.dart';
import 'bunker_scene.dart';

/// Escena de la casa de Dan (Capítulo 1) - Con sistema de habitaciones
class HouseScene extends StatefulWidget {
  const HouseScene({Key? key}) : super(key: key);

  @override
  State<HouseScene> createState() => _HouseSceneState();
}

class _HouseSceneState extends State<HouseScene> with SingleTickerProviderStateMixin {
  // Posición del jugador
  Vector2 _playerPosition = Vector2(350, 250);
  final double _playerSpeed = 5.0;
  final double _playerSize = 40.0;

  // Joystick Virtual
  Offset? _joystickOrigin;
  Offset? _joystickPosition;
  bool _isJoystickActive = false;
  Vector2 _joystickInput = Vector2(0, 0);
  static const double _joystickRadius = 60.0;
  static const double _joystickKnobRadius = 25.0;

  // Control de movimiento
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  bool _isDialogueActive = false;
  bool _phoneCallCompleted = false;

  // Sistema de habitaciones
  late RoomManager _roomManager;
  bool _isTransitioning = false;
  double _transitionCooldown = 0.0;
  static const double _cooldownDuration = 0.5; // Medio segundo de cooldown
  
  // Animación de transición
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;
  
  // Focus y timer para movimiento
  late FocusNode _focusNode;
  Timer? _movementTimer;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _roomManager = RoomManager();
    
    // Configurar animación de transición
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeInOut),
    );
    
    _showIntroDialogue();
    _startMovementLoop();
  }
  
  @override
  void dispose() {
    _focusNode.dispose();
    _movementTimer?.cancel();
    _transitionController.dispose();
    super.dispose();
  }
  
  void _startMovementLoop() {
    _movementTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (mounted) {
        // Actualizar cooldown de transición
        if (_transitionCooldown > 0) {
          _transitionCooldown -= 0.016; // 16ms en segundos
        }
        
        if (!_isTransitioning) {
          _updatePlayerPosition();
          _checkDoorCollisions();
        }
      }
    });
  }

  void _showIntroDialogue() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isDialogueActive = true;
      });

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
        onComplete: () {
          setState(() {
            _isDialogueActive = false;
          });
        },
      );
    });
  }

  void _transitionToCombat() async {
    await SaveSystem.markChapterCompleted(1);
    
    if (!mounted) return;
    
    // Transición al Capítulo 2 (Búnker)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const BunkerScene()),
    );
  }

  void _updatePlayerPosition() {
    if (_isDialogueActive || _isTransitioning) return;

    Vector2 velocity = const Vector2(0, 0);

    // Detectar teclas presionadas (Teclado)
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      velocity = Vector2(velocity.x, velocity.y - 1);
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      velocity = Vector2(velocity.x, velocity.y + 1);
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      velocity = Vector2(velocity.x - 1, velocity.y);
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      velocity = Vector2(velocity.x + 1, velocity.y);
    }

    // Sumar input del joystick
    if (_isJoystickActive) {
      velocity = velocity + _joystickInput;
    }

    // Normalizar y aplicar velocidad
    if (velocity.x != 0 || velocity.y != 0) {
      final length = (velocity.x * velocity.x + velocity.y * velocity.y);
      if (length > 0) {
        final normalized = Vector2(
          velocity.x / length,
          velocity.y / length,
        );
        
        Vector2 newPosition = Vector2(
          _playerPosition.x + normalized.x * _playerSpeed,
          _playerPosition.y + normalized.y * _playerSpeed,
        );

        // Límites del container (habitación actual)
        final room = _roomManager.currentRoom;
        final padding = _playerSize / 2;
        
        newPosition = Vector2(
          newPosition.x.clamp(padding, room.roomSize.width - padding),
          newPosition.y.clamp(padding, room.roomSize.height - padding),
        );

        setState(() {
          _playerPosition = newPosition;
        });
      }
    }
  }

  void _checkDoorCollisions() {
    if (_isTransitioning || _transitionCooldown > 0) return;

    final room = _roomManager.currentRoom;
    for (final door in room.doors) {
      if (door.isPlayerInRange(_playerPosition, _playerSize)) {
        _transitionToRoom(door.targetRoomId);
        break;
      }
    }
  }

  void _transitionToRoom(String targetRoomId) async {
    setState(() {
      _isTransitioning = true;
    });

    // Fade out
    await _transitionController.forward();
    
    // Cambiar habitación
    setState(() {
      _roomManager.changeRoom(targetRoomId);
      _playerPosition = _roomManager.currentRoom.playerSpawnPosition;
    });

    // Fade in
    await _transitionController.reverse();
    
    setState(() {
      _isTransitioning = false;
      _transitionCooldown = _cooldownDuration; // Activar cooldown después de la transición
    });
  }

  void _tryInteract() {
    final room = _roomManager.currentRoom;
    const interactionRadius = 80.0;

    // Buscar interactable cercano
    for (final interactable in room.interactables) {
      if (interactable.isInRange(_playerPosition, interactionRadius)) {
        debugPrint('Interacting with: ${interactable.id}');
        
        // Verificar si ya fue interactuado (si es one-time)
        if (interactable.isOneTime && interactable.hasBeenInteracted) {
          debugPrint('Already interacted with ${interactable.id}');
          return;
        }

        // Marcar como interactuado
        interactable.hasBeenInteracted = true;

        // Ejecutar callback personalizado si existe
        interactable.onInteract?.call();

        // Mostrar diálogo si existe
        if (interactable.dialogue != null) {
          setState(() {
            _isDialogueActive = true;
          });

          DialogueOverlay.show(
            context,
            interactable.dialogue!,
            onComplete: () {
              setState(() {
                _isDialogueActive = false;
                
                // Lógica específica del teléfono
                if (interactable.id == 'phone') {
                  _phoneCallCompleted = true;
                  debugPrint('Phone call completed, transitioning to combat...');
                  Future.delayed(const Duration(seconds: 2), () {
                    _transitionToCombat();
                  });
                }
              });
            },
          );
        }
        
        return; // Solo interactuar con el primer objeto encontrado
      }
    }
    
    debugPrint('No interactable in range');
  }

  @override
  Widget build(BuildContext context) {
    final room = _roomManager.currentRoom;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            // Saltar diálogo con ESC
            if (event.logicalKey == LogicalKeyboardKey.escape && _isDialogueActive) {
              debugPrint('ESC pressed - skipping dialogue');
              DialogueOverlay.skipCurrent();
              // No cambiar _isDialogueActive aquí, se cambiará en onComplete
              return;
            }
            
            // Interactuar con E
            if (event.logicalKey == LogicalKeyboardKey.keyE && !_isDialogueActive) {
              _tryInteract();
              return;
            }
            
            _pressedKeys.add(event.logicalKey);
          } else if (event is KeyUpEvent) {
            _pressedKeys.remove(event.logicalKey);
          }
        },
        child: Listener(
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
            }
          },
          onPointerUp: (event) {
            setState(() {
              _isJoystickActive = false;
              _joystickOrigin = null;
              _joystickPosition = null;
              _joystickInput = Vector2(0, 0);
            });
          },
          child: Stack(
            children: [
            // Habitación actual con límites
            Center(
              child: Container(
                width: room.roomSize.width,
                height: room.roomSize.height,
                decoration: BoxDecoration(
                  color: room.backgroundColor,
                  border: Border.all(color: Colors.brown, width: 4),
                ),
                child: Stack(
                  children: [
                    // Puertas (visuales)
                    ...room.doors.map((door) {
                      return Positioned(
                        left: door.position.x,
                        top: door.position.y,
                        child: Container(
                          width: door.size.x,
                          height: door.size.y,
                          decoration: BoxDecoration(
                            color: Colors.brown.withOpacity(0.5),
                            border: Border.all(color: Colors.yellow, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              door.label,
                              style: const TextStyle(
                                color: Colors.yellow,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }),
                    // Interactables
                    ...room.interactables.map((interactable) {
                      return InteractableObject(
                        data: interactable,
                        playerPosition: _playerPosition,
                        interactionRadius: 80,
                        onInteractionComplete: () {
                          setState(() {
                            _isDialogueActive = false;
                            if (interactable.id == 'phone') {
                              _phoneCallCompleted = true;
                              Future.delayed(const Duration(seconds: 2), () {
                                _transitionToCombat();
                              });
                            }
                          });
                        },
                      );
                    }),
                    // Jugador
                    Positioned(
                      left: _playerPosition.x - _playerSize / 2,
                      top: _playerPosition.y - _playerSize / 2,
                      child: SizedBox(
                        width: _playerSize,
                        height: _playerSize,
                        child: Image.asset(
                          'assets/avatars/full_body/dan_fullbody.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
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
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Overlay de transición (pantalla negra)
            if (_isTransitioning)
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Container(
                    color: Colors.black.withOpacity(_fadeAnimation.value),
                  );
                },
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
                      room.name,
                      style: TextStyle(
                        color: Colors.cyan[300],
                        fontSize: 12,
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
                child: Text(
                  _isDialogueActive
                      ? 'ESC: Saltar diálogo'
                      : 'WASD/Flechas: Mover\nE: Interactuar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            // Joystick UI
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
    ),
  );
}
}
