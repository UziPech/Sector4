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
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _roomManager = BunkerRoomManager();
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
    if (velocity.x != 0 || velocity.y != 0) {
      velocity = velocity.normalized() * _playerSpeed;
      final room = _roomManager.currentRoom;
      final newX = (_playerPosition.x + velocity.x).clamp(_playerSize / 2, room.roomSize.width - _playerSize / 2);
      final newY = (_playerPosition.y + velocity.y).clamp(_playerSize / 2, room.roomSize.height - _playerSize / 2);
      setState(() { _playerPosition = Vector2(newX, newY); });
    }
  }

  Widget _buildRoomWithCamera(RoomData room, Size screenSize) {
    if (room.cameraMode == CameraMode.follow) {
      // Cámara que sigue al jugador
      final cameraX = (screenSize.width / 2 - _playerPosition.x).clamp(
        screenSize.width - room.roomSize.width,
        0.0,
      );
      final cameraY = (screenSize.height / 2 - _playerPosition.y).clamp(
        screenSize.height - room.roomSize.height,
        0.0,
      );
      
      return Transform.translate(
        offset: Offset(cameraX, cameraY),
        child: Container(
          width: room.roomSize.width,
          height: room.roomSize.height,
          decoration: BoxDecoration(color: room.backgroundColor, border: Border.all(color: Colors.white.withOpacity(0.3), width: 2)),
          child: Stack(children: _buildRoomContent(room)),
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
      ...room.doors.map((door) => Positioned(
        left: door.position.x, top: door.position.y,
        child: Container(
          width: door.size.x, height: door.size.y,
          decoration: BoxDecoration(color: Colors.yellow.withOpacity(0.3), border: Border.all(color: Colors.yellow, width: 2)),
          child: Center(child: Text(door.label, style: const TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'))),
        ),
      )),
      ...room.interactables.map((interactable) => InteractableObject(
        data: interactable, playerPosition: _playerPosition, interactionRadius: 80,
        onInteractionComplete: () { setState(() { _isDialogueActive = false; }); },
      )),
      Positioned(
        left: _playerPosition.x - _playerSize / 2, top: _playerPosition.y - _playerSize / 2,
        child: Container(
          width: _playerSize, height: _playerSize,
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.7), border: Border.all(color: Colors.white, width: 2), shape: BoxShape.circle),
          child: const Icon(Icons.person, color: Colors.white, size: 24),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final room = _roomManager.currentRoom;
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
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
          ],
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
