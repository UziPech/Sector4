import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dialogue_data.dart';
import '../models/interactable_data.dart';
import '../models/room_data.dart';
import '../systems/bunker_room_manager.dart';
import '../components/interactable_object.dart';
import '../components/dialogue_system.dart';
import '../services/save_system.dart';
import '../../main.dart';

/// Capítulo 2: El Búnker - Sistema de habitaciones
class BunkerScene extends StatefulWidget {
  const BunkerScene({Key? key}) : super(key: key);

  @override
  State<BunkerScene> createState() => _BunkerSceneState();
}

class _BunkerSceneState extends State<BunkerScene> with SingleTickerProviderStateMixin {
  late final BunkerRoomManager _roomManager;
  Vector2 _playerPosition = const Vector2(350, 400);
  final double _playerSize = 40.0;
  final double _playerSpeed = 3.0;
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  bool _isDialogueActive = false;
  bool _melMetCompleted = false;
  bool _briefingCompleted = false;
  bool _isTransitioning = false;
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;
  double _transitionCooldown = 0;
  final double _cooldownDuration = 0.5;
  final FocusNode _focusNode = FocusNode();
  // Joystick Virtual
  Offset? _joystickOrigin;
  Offset? _joystickPosition;
  bool _isJoystickActive = false;
  Vector2 _joystickInput = Vector2(0, 0);
  static const double _joystickRadius = 60.0;
  static const double _joystickKnobRadius = 25.0;
  bool _canInteract = false;

  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _roomManager = BunkerRoomManager();
    _playerPosition = _roomManager.currentRoom.playerSpawnPosition;
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_transitionController);
    _updateTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _updatePlayerPosition();
      _checkDoorCollisions();
      _updateCooldown();
    });
    _showArrivalMonologue();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _transitionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showArrivalMonologue() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() { _isDialogueActive = true; });
      DialogueOverlay.show(context, DialogueSequence(
        id: 'arrival',
        dialogues: const [
          DialogueData(speakerName: 'Dan', text: 'El camino al búnker. Zona restringida.', type: DialogueType.internal),
          DialogueData(speakerName: 'Dan', text: 'Hace años que no venía por aquí. Todo está abandonado.', type: DialogueType.internal),
          DialogueData(speakerName: 'Dan', text: 'Mel me está esperando. Necesito llegar a la entrada.', type: DialogueType.internal),
        ],
      ), onComplete: () { setState(() { _isDialogueActive = false; }); });
    });
  }

  void _updateCooldown() {
    if (_transitionCooldown > 0) {
      setState(() {
        _transitionCooldown -= 0.016;
        if (_transitionCooldown < 0) _transitionCooldown = 0;
      });
    }
  }

  void _checkDoorCollisions() {
    if (_isTransitioning || _transitionCooldown > 0) return;
    final room = _roomManager.currentRoom;
    for (final door in room.doors) {
      final doorRect = Rect.fromLTWH(door.position.x, door.position.y, door.size.x, door.size.y);
      final playerRect = Rect.fromCenter(center: Offset(_playerPosition.x, _playerPosition.y), width: _playerSize, height: _playerSize);
      if (doorRect.overlaps(playerRect)) {
        _transitionToRoom(door.targetRoomId);
        return;
      }
    }
  }

  void _transitionToRoom(String targetRoomId) async {
    setState(() { _isTransitioning = true; });
    await _transitionController.forward();
    setState(() {
      _roomManager.changeRoom(targetRoomId);
      _playerPosition = _roomManager.currentRoom.playerSpawnPosition;
    });
    await _transitionController.reverse();
    setState(() {
      _isTransitioning = false;
      _transitionCooldown = _cooldownDuration;
    });
  }

  void _tryInteract() {
    final room = _roomManager.currentRoom;
    const interactionRadius = 80.0;
    for (final interactable in room.interactables) {
      if (interactable.isInRange(_playerPosition, interactionRadius)) {
        if (interactable.isOneTime && interactable.hasBeenInteracted) return;
        interactable.hasBeenInteracted = true;
        interactable.onInteract?.call();
        if (interactable.dialogue != null) {
          setState(() { _isDialogueActive = true; });
          DialogueOverlay.show(context, interactable.dialogue!, onComplete: () {
            setState(() {
              _isDialogueActive = false;
              if (interactable.id == 'mel_capsule') _melMetCompleted = true;
              else if (interactable.id == 'main_console') {
                _briefingCompleted = true;
                Future.delayed(const Duration(seconds: 2), () { _transitionToCombat(); });
              }
            });
          });
        }
        return;
      }
    }
  }

  void _transitionToCombat() async {
    await SaveSystem.markChapterCompleted(2);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MyApp()));
  }

  void _updatePlayerPosition() {
    if (_isDialogueActive || _isTransitioning) return;
    Vector2 velocity = const Vector2(0, 0);
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) velocity = Vector2(velocity.x, velocity.y - 1);
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) velocity = Vector2(velocity.x, velocity.y + 1);
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) velocity = Vector2(velocity.x - 1, velocity.y);
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) velocity = Vector2(velocity.x + 1, velocity.y);
    // Joystick Input
    if (_isJoystickActive) {
      velocity = velocity + _joystickInput;
    }

    if (velocity.x != 0 || velocity.y != 0) {
      // Use length for normalization to match HouseScene logic
      final length = (velocity.x * velocity.x + velocity.y * velocity.y);
      if (length > 0) {
        // Manual normalization if needed, or use normalized() if available
        // Assuming Vector2 has normalized() from previous fixes
        // But let's be safe and use the same logic as HouseScene if possible, 
        // or trust the existing normalized() method if it works.
        // The existing code used velocity.normalized() * _playerSpeed.
        // We will stick to that but ensure we handle the joystick input correctly.
        
        // Re-normalize only if magnitude > 1 (to allow slow movement with joystick)?
        // Or just normalize always for constant speed.
        // Let's normalize always for now.
        if (velocity.length > 1) {
             velocity = velocity.normalized();
        } else if (velocity.length == 0) {
             // do nothing
        } else {
             // if joystick is partial, we might want to keep it? 
             // But for consistency with keyboard, let's normalize direction and apply speed.
             velocity = velocity.normalized();
        }
        
        velocity = velocity * _playerSpeed;

        final room = _roomManager.currentRoom;
        final newX = (_playerPosition.x + velocity.x).clamp(_playerSize / 2, room.roomSize.width - _playerSize / 2);
        final newY = (_playerPosition.y + velocity.y).clamp(_playerSize / 2, room.roomSize.height - _playerSize / 2);
        setState(() { _playerPosition = Vector2(newX, newY); });
      }
    }
    
    // Check for interactables
    final room = _roomManager.currentRoom;
    bool canInteract = false;
    for (final interactable in room.interactables) {
       if (interactable.isInRange(_playerPosition, 80.0)) {
         if (!interactable.isOneTime || !interactable.hasBeenInteracted) {
           canInteract = true;
           break;
         }
       }
    }
    
    if (_canInteract != canInteract) {
       setState(() {
         _canInteract = canInteract;
       });
    }
  }


  Widget _buildRoomWithCamera(RoomData room, Size screenSize) {
    if (room.cameraMode == CameraMode.follow) {
      // Cámara que sigue al jugador - usar Positioned para mover el contenido
      final cameraX = (_playerPosition.x - screenSize.width / 2).clamp(
        0.0,
        room.roomSize.width - screenSize.width,
      );
      final cameraY = (_playerPosition.y - screenSize.height / 2).clamp(
        0.0,
        room.roomSize.height - screenSize.height,
      );
      
      return ClipRect(
        child: SizedBox(
          width: screenSize.width,
          height: screenSize.height,
          child: Stack(
            children: [
              Positioned(
                left: -cameraX,
                top: -cameraY,
                child: Container(
                  width: room.roomSize.width,
                  height: room.roomSize.height,
                  decoration: BoxDecoration(
                    color: room.backgroundColor,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: Stack(children: _buildRoomContent(room)),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Cámara fija
      return Center(
        child: Container(
          width: room.roomSize.width,
          height: room.roomSize.height,
          decoration: BoxDecoration(color: room.backgroundColor, border: Border.all(color: Colors.white.withOpacity(0.3), width: 2)),
          child: Stack(children: _buildRoomContent(room)),
        ),
      );
    }
  }

  List<Widget> _buildRoomContent(RoomData room) {
    return [
      // Grid de fondo para visualización
      CustomPaint(
        size: Size(room.roomSize.width, room.roomSize.height),
        painter: GridPainter(),
      ),
      // Puertas
      ...room.doors.map((door) => Positioned(
        left: door.position.x, top: door.position.y,
        child: Container(
          width: door.size.x, height: door.size.y,
          decoration: BoxDecoration(
            color: Colors.yellow.withOpacity(0.3), 
            border: Border.all(color: Colors.yellow, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              door.label, 
              style: const TextStyle(
                color: Colors.yellow, 
                fontSize: 12, 
                fontWeight: FontWeight.bold, 
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      )),
      // Interactables
      ...room.interactables.map((interactable) => InteractableObject(
        data: interactable, 
        playerPosition: _playerPosition, 
        interactionRadius: 80,
        onInteractionComplete: () { setState(() { _isDialogueActive = false; }); },
      )),
      // Jugador (Dan)
      Positioned(
        left: _playerPosition.x - _playerSize / 2, 
        top: _playerPosition.y - _playerSize / 2,
        child: Container(
          width: _playerSize, 
          height: _playerSize,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.8),
            border: Border.all(color: Colors.white, width: 3),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.person, 
            color: Colors.white, 
            size: 28,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final room = _roomManager.currentRoom;
    final screenSize = MediaQuery.of(context).size;
    
    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape && _isDialogueActive) {
              DialogueOverlay.skipCurrent();
              return;
            }
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
                
                if (delta.length > _joystickRadius) {
                  delta = delta.normalized() * _joystickRadius;
                }
                
                _joystickPosition = Offset(
                  _joystickOrigin!.dx + delta.x,
                  _joystickOrigin!.dy + delta.y,
                );
                
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
            _buildRoomWithCamera(room, screenSize),
            if (_isTransitioning) AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) => Container(color: Colors.black.withOpacity(_fadeAnimation.value)),
            ),
            Positioned(
              top: 16, left: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), border: Border.all(color: Colors.white, width: 2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CAPÍTULO 2: EL BÚNKER', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    const SizedBox(height: 4),
                    Text(room.name, style: TextStyle(color: Colors.cyan[300], fontSize: 14, fontFamily: 'monospace')),
                    const SizedBox(height: 4),
                    Text(_getObjectiveText(), style: TextStyle(color: Colors.yellow[700], fontSize: 12, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16, left: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), border: Border.all(color: Colors.white, width: 2)),
                child: Text(_isDialogueActive ? 'ESC: Saltar diálogo' : 'WASD/Flechas: Mover\nE: Interactuar', style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
              ),
            ),
            
            // Joystick UI
            if (_isJoystickActive && _joystickOrigin != null && _joystickPosition != null) ...[
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

            // Interaction Button
            if (_canInteract && !_isDialogueActive)
              Positioned(
                bottom: 80,
                right: 40,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _tryInteract,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.yellow.withOpacity(0.8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.touch_app,
                        color: Colors.black,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    ),
  );
  }

  String _getObjectiveText() {
    if (_briefingCompleted) return 'Objetivo: Prepararse para el combate';
    if (_melMetCompleted) return 'Objetivo: Ir al Centro de Comando';
    if (_roomManager.currentRoom.id == 'exterior_large') return 'Objetivo: Llegar a la entrada del búnker';
    if (_roomManager.currentRoom.id == 'exterior') return 'Objetivo: Entrar al búnker';
    return 'Objetivo: Encontrar a Mel';
  }
}

/// Painter para dibujar un grid de fondo
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    const gridSize = 50.0;

    // Líneas verticales
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Líneas horizontales
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
