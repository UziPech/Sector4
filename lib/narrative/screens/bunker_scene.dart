import 'dart:async';
import 'dart:ui' as ui; // Import dart:ui for Image
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/dialogue_data.dart';
import '../models/interactable_data.dart';
import '../models/room_data.dart';
import '../systems/bunker_room_manager.dart';
import '../components/interactable_object.dart';
import '../components/dialogue_system.dart';
import '../components/animated_sprite.dart';
import '../components/forest_painter.dart'; // Import ForestPainter
import '../components/wall_widget.dart'; // Import WallWidget
import '../components/automatic_door_widget.dart'; // Import AutomaticDoorWidget
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
  final double _playerSize = 80.0; // Aumentado a 80 para mejor visibilidad
  final double _playerSpeed = 6.0; // Velocidad balanceada para móvil y desktop
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  bool _isDialogueActive = false;
  bool _melMetCompleted = false;
  bool _briefingCompleted = false;
  bool _isTransitioning = false;
  bool _transitionScheduled = false; // Prevenir múltiples llamadas al delay
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;
  // Cooldown removido - _transitionScheduled ya previene transiciones múltiples
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
  
  // Animación de sprite
  AnimatedSprite? _danSpriteNorth;
  AnimatedSprite? _danSpriteSouth;
  ui.Image? _treeSprite; // Sprite sheet para los árboles
  ui.Image? _wallHorizontal;
  ui.Image? _wallVertical;
  
  String _currentDirection = 'SOUTH';
  int _currentFrame = 0;
  double _animationTimer = 0.0;
  static const double _frameRate = 0.15; // 6.67 FPS

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
    
    // Cargar sprites de Dan (Norte y Sur)
    _loadDanSprites();
    // Cargar sprite sheet de árboles
    _loadTreeSprite();
    // Cargar texturas de paredes
    _loadWallTextures();
    
    _showArrivalMonologue();
  }
  
  Future<void> _loadDanSprites() async {
    try {
      final spriteNorth = await AnimatedSprite.load('assets/sprites/dan_walk_north.png');
      final spriteSouth = await AnimatedSprite.load('assets/sprites/dan_walk_south.png');
      
      if (mounted) {
        setState(() {
          _danSpriteNorth = spriteNorth;
          _danSpriteSouth = spriteSouth;
        });
      }
    } catch (e) {
      debugPrint('Error loading Dan sprites: $e');
    }
  }

  Future<void> _loadTreeSprite() async {
    final data = await rootBundle.load('assets/sprites/pine_trees.png');
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _treeSprite = frame.image;
      });
    }
  }

  Future<void> _loadWallTextures() async {
    try {
      final dataH = await rootBundle.load('assets/images/wall_panel_horizontal.png');
      final bytesH = dataH.buffer.asUint8List();
      final codecH = await ui.instantiateImageCodec(bytesH);
      final frameH = await codecH.getNextFrame();
      
      final dataV = await rootBundle.load('assets/images/wall_panel_vertical.png');
      final bytesV = dataV.buffer.asUint8List();
      final codecV = await ui.instantiateImageCodec(bytesV);
      final frameV = await codecV.getNextFrame();
      
      if (mounted) {
        setState(() {
          _wallHorizontal = frameH.image;
          _wallVertical = frameV.image;
        });
      }
    } catch (e) {
      debugPrint('Error loading wall textures: $e');
    }
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
    // Cooldown removido - ya no es necesario
  }

  void _checkDoorCollisions() {
    if (_isTransitioning || _transitionScheduled) return; // Cooldown removido
    final room = _roomManager.currentRoom;
    for (final door in room.doors) {
      // Usar área de colisión más pequeña (90% del tamaño de la puerta, centrado)
      final collisionSizeFactor = 0.9;
      final collisionWidth = door.size.x * collisionSizeFactor;
      final collisionHeight = door.size.y * collisionSizeFactor;
      final collisionX = door.position.x + (door.size.x - collisionWidth) / 2;
      final collisionY = door.position.y + (door.size.y - collisionHeight) / 2;
      
      final doorRect = Rect.fromLTWH(collisionX, collisionY, collisionWidth, collisionHeight);
      final playerRect = Rect.fromCenter(center: Offset(_playerPosition.x, _playerPosition.y), width: _playerSize, height: _playerSize);
      
      if (doorRect.overlaps(playerRect)) {
        _transitionScheduled = true; // Marcar que hay una transición programada
        // Delay para permitir que la animación de apertura se muestre
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && _transitionScheduled) {
            _transitionToRoom(door.targetRoomId, spawnPosition: door.targetSpawnPosition);
          }
        });
        return;
      }
    }
  }


  void _transitionToRoom(String targetRoomId, {Vector2? spawnPosition}) async {
    if (_isTransitioning) return; // Prevenir transiciones múltiples
    setState(() { 
      _isTransitioning = true;
      _transitionScheduled = false; // Resetear flag
    });
    await _transitionController.forward();
    setState(() {
      _roomManager.changeRoom(targetRoomId);
      _playerPosition = spawnPosition ?? _roomManager.currentRoom.playerSpawnPosition;
    });
    await _transitionController.reverse();
    setState(() {
      _isTransitioning = false;
      // Cooldown removido
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
    // Iniciar en modo Boss (Stalker)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MyApp(startInBossMode: true))
    );
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
      // Normalizar y aplicar velocidad de manera consistente
      if (velocity.length > 0) {
        velocity = velocity.normalized() * _playerSpeed;
      }

      final room = _roomManager.currentRoom;
      
      // Intentar mover en X
      double nextX = (_playerPosition.x + velocity.x).clamp(_playerSize / 2, room.roomSize.width - _playerSize / 2);
      if (_isPositionValid(Vector2(nextX, _playerPosition.y))) {
        _playerPosition = Vector2(nextX, _playerPosition.y);
      }
      
      // Intentar mover en Y
      double nextY = (_playerPosition.y + velocity.y).clamp(_playerSize / 2, room.roomSize.height - _playerSize / 2);
      if (_isPositionValid(Vector2(_playerPosition.x, nextY))) {
        _playerPosition = Vector2(_playerPosition.x, nextY);
      }
      
      setState(() { 
        // Calcular dirección
        _currentDirection = AnimatedSprite.calculateDirection(velocity.x, velocity.y);
        
        // Animar frames
        _animationTimer += 0.016; // ~16ms por frame
        if (_animationTimer >= _frameRate) {
          _animationTimer = 0;
          _currentFrame = (_currentFrame + 1) % 3; // Ciclar entre 3 frames
        }
      });
    } else {
      // Si no se mueve, resetear a frame 0 (idle)
      if (_currentFrame != 0) {
        setState(() {
          _currentFrame = 0;
        });
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

  bool _isPositionValid(Vector2 pos) {
    // Si estamos en exterior_large (mapa abierto), usar lógica simple o límites del mapa
    if (_roomManager.currentRoom.id == 'exterior_large') return true;

    final room = _roomManager.currentRoom;
    const double thickness = 100.0;
    final double halfSize = _playerSize / 4; // Usar un hitbox más pequeño (20px) para los pies/centro, no todo el sprite (80px)
    
    // Límites del cuarto (hard bounds) ya manejados por clamp, pero doble check
    if (pos.x < 0 || pos.x > room.roomSize.width ||
        pos.y < 0 || pos.y > room.roomSize.height) {
      print('DEBUG: Out of bounds: $pos. Room: ${room.roomSize}');
      return false;
    }

    // Chequear colisión con paredes
    // Izquierda
    if (pos.x - halfSize < thickness) {
      bool inDoor = false;
      for (final door in room.doors) {
        if (door.position.x <= 10) {
           // Permitir paso si estamos alineados con la puerta
           if (pos.y >= door.position.y && pos.y <= door.position.y + door.size.y) {
             inDoor = true; 
             break;
           }
        }
      }
      if (!inDoor) {
        print('DEBUG: Collision Left. Pos: $pos, HalfSize: $halfSize, Thickness: $thickness');
        return false;
      }
    }
    
    // Derecha
    if (pos.x + halfSize > room.roomSize.width - thickness) {
       bool inDoor = false;
       for (final door in room.doors) {
         if (door.position.x >= room.roomSize.width - thickness - 10) {
            if (pos.y >= door.position.y && pos.y <= door.position.y + door.size.y) {
              inDoor = true;
              break;
            }
         }
       }
       if (!inDoor) {
         print('DEBUG: Collision Right. Pos: $pos, HalfSize: $halfSize, Thickness: $thickness, RoomWidth: ${room.roomSize.width}');
         return false;
       }
    }

    // Arriba
    if (pos.y - halfSize < thickness) {
       bool inDoor = false;
       for (final door in room.doors) {
         if (door.position.y <= 10) {
            if (pos.x >= door.position.x && pos.x <= door.position.x + door.size.x) {
              inDoor = true;
              break;
            }
         }
       }
       if (!inDoor) {
         print('DEBUG: Collision Top. Pos: $pos, HalfSize: $halfSize, Thickness: $thickness');
         return false;
       }
    }

    // Abajo
    if (pos.y + halfSize > room.roomSize.height - thickness) {
       bool inDoor = false;
       for (final door in room.doors) {
         if (door.position.y >= room.roomSize.height - thickness - 10) {
            if (pos.x >= door.position.x && pos.x <= door.position.x + door.size.x) {
              inDoor = true;
              break;
            }
         }
       }
       if (!inDoor) {
         print('DEBUG: Collision Bottom. Pos: $pos, HalfSize: $halfSize, Thickness: $thickness, RoomHeight: ${room.roomSize.height}');
         return false;
       }
    }

    return true;
  }


  Widget _buildRoomWithCamera(RoomData room, Size screenSize) {
    if (room.cameraMode == CameraMode.follow) {
      // Para el mapa exterior en móvil, usar FittedBox para que se vea completo
      if (room.id == 'exterior_large' && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        return Center(
          child: FittedBox(
            fit: BoxFit.contain,
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
        );
      }
      
      // Cámara que sigue al jugador - usar Positioned para mover el contenido (Desktop)
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
        child: FittedBox(
          fit: BoxFit.contain,
          child: Container(
            width: room.roomSize.width,
            height: room.roomSize.height,
          decoration: BoxDecoration(color: room.backgroundColor, border: Border.all(color: Colors.white.withOpacity(0.3), width: 2)),
          child: Stack(children: _buildRoomContent(room)),
          ),
        ),
      );
    }
  }

  List<Widget> _buildRoomContent(RoomData room) {
    // Separar árboles de otros interactables
    final trees = room.interactables.where((i) => i.type == InteractableType.decoration).toList();
    final otherInteractables = room.interactables.where((i) => i.type != InteractableType.decoration).toList();

    return [
      // Fondo del mapa (textura o color)
      if (room.id == 'exterior_large')
        // Textura de piso para el mapa exterior grande
        Positioned.fill(
          child: Image.asset(
            'assets/images/bunker_exterior_floor.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: room.backgroundColor);
            },
          ),
        )
      else if (room.id == 'laboratory' || room.id == 'command')
        // Piso metálico limpio para laboratorio y centro de comando
        Positioned.fill(
          child: Image.asset(
            'assets/images/metal_floor_clean.png',
            fit: BoxFit.cover,
            repeat: ImageRepeat.repeat,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: room.backgroundColor);
            },
          ),
        )
      else if (room.id == 'hallway' || room.id == 'armory' || room.id == 'vestibule' || room.id == 'cafeteria')
        // Piso metálico oscuro para pasillo, armería, vestíbulo y comedor
        Positioned.fill(
          child: Image.asset(
            'assets/images/metal_floor_dark.png',
            fit: BoxFit.cover,
            repeat: ImageRepeat.repeat,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: room.backgroundColor);
            },
          ),
        )
      else if (room.id == 'quarters')
        // Piso metálico envejecido para dormitorios
        Positioned.fill(
          child: Image.asset(
            'assets/images/metal_floor_quarters.png',
            fit: BoxFit.cover,
            repeat: ImageRepeat.repeat,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: room.backgroundColor);
            },
          ),
        )
      else if (room.id == 'exterior')
        // Piso de hierba oscura para el exterior del búnker
        Positioned.fill(
          child: Image.asset(
            'assets/images/exterior_floor.png',
            fit: BoxFit.cover,
            repeat: ImageRepeat.repeat,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: room.backgroundColor);
            },
          ),
        )
      else
        // Grid de fondo para otras habitaciones (biblioteca)
        CustomPaint(
          size: Size(room.roomSize.width, room.roomSize.height),
          painter: GridPainter(),
        ),
      
      // Renderizado optimizado de árboles (ForestPainter)
      if (_treeSprite != null && trees.isNotEmpty)
        Positioned.fill(
          child: CustomPaint(
            painter: ForestPainter(
              image: _treeSprite!,
              trees: trees,
            ),
          ),
        ),

      // Paredes (WallWidgets)
      if (_wallHorizontal != null && _wallVertical != null && room.id != 'exterior_large')
        ..._buildWalls(room),

      // Puertas
      // Puertas (AutomaticDoorWidget)
      ...room.doors.map((door) => Positioned(
        left: door.position.x, top: door.position.y,
        child: AutomaticDoorWidget(
          doorData: door,
          playerPosition: _playerPosition,
        ),
      )),
      // Interactables (Solo los que NO son decoración/árboles)
      ...otherInteractables.map((interactable) => InteractableObject(
        data: interactable, 
        playerPosition: _playerPosition, 
        interactionRadius: 80,
        onInteractionComplete: () { setState(() { _isDialogueActive = false; }); },
      )),
      // Jugador (Dan - Sprite Animado)
      Positioned(
        left: _playerPosition.x - _playerSize / 2, 
        top: _playerPosition.y - _playerSize / 2,
        child: Builder(
          builder: (context) {
            // Seleccionar sprite basado en dirección
            AnimatedSprite? spriteToUse;
            
            if (_currentDirection.contains('NORTH')) {
              spriteToUse = _danSpriteNorth;
            } else {
              spriteToUse = _danSpriteSouth;
            }
            
            // Fallback si alguno es null
            spriteToUse ??= _danSpriteSouth ?? _danSpriteNorth;
            
            if (spriteToUse != null) {
              return AnimatedSpriteWidget(
                sprite: spriteToUse,
                direction: _currentDirection, // AnimatedSprite ignorará esto si rows=1
                frameIndex: _currentFrame,
                size: _playerSize,
              );
            } else {
              return SizedBox(
                width: _playerSize,
                height: _playerSize,
                child: Container(
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
                    size: 40,
                  ),
                ),
              );
            }
          }
        ),
      ),
    ];
  }

  List<Widget> _buildWalls(RoomData room) {
    final List<Widget> walls = [];
    const double thickness = 100.0;
    const double overlap = 30.0; // Increased from 15px to fully cover edges
    
    // Top Wall
    final topDoors = room.doors.where((d) => d.position.y <= 10).toList(); // Tolerancia
    if (topDoors.isEmpty) {
      walls.add(Positioned(
        top: 0, left: 0,
        child: WallWidget(width: room.roomSize.width, height: thickness, side: WallSide.top, image: _wallHorizontal),
      ));
    } else {
      // Ordenar puertas por X
      topDoors.sort((a, b) => a.position.x.compareTo(b.position.x));
      double currentX = 0;
      for (final door in topDoors) {
        // Draw wall up to door start + overlap
        double wallWidth = (door.position.x + overlap) - currentX;
        if (wallWidth > 0) {
          walls.add(Positioned(
            top: 0, left: currentX,
            child: WallWidget(width: wallWidth, height: thickness, side: WallSide.top, image: _wallHorizontal),
          ));
        }
        // Start next wall at door end - overlap
        currentX = door.position.x + door.size.x - overlap;
      }
      if (currentX < room.roomSize.width) {
        walls.add(Positioned(
          top: 0, left: currentX,
          child: WallWidget(width: room.roomSize.width - currentX, height: thickness, side: WallSide.top, image: _wallHorizontal),
        ));
      }
    }
    
    // Bottom Wall
    final bottomDoors = room.doors.where((d) => d.position.y >= room.roomSize.height - thickness - 10).toList();
    if (bottomDoors.isEmpty) {
      walls.add(Positioned(
        bottom: 0, left: 0,
        child: WallWidget(width: room.roomSize.width, height: thickness, side: WallSide.bottom, image: _wallHorizontal),
      ));
    } else {
      bottomDoors.sort((a, b) => a.position.x.compareTo(b.position.x));
      double currentX = 0;
      for (final door in bottomDoors) {
        double wallWidth = (door.position.x + overlap) - currentX;
        if (wallWidth > 0) {
          walls.add(Positioned(
            bottom: 0, left: currentX,
            child: WallWidget(width: wallWidth, height: thickness, side: WallSide.bottom, image: _wallHorizontal),
          ));
        }
        currentX = door.position.x + door.size.x - overlap;
      }
      if (currentX < room.roomSize.width) {
        walls.add(Positioned(
          bottom: 0, left: currentX,
          child: WallWidget(width: room.roomSize.width - currentX, height: thickness, side: WallSide.bottom, image: _wallHorizontal),
        ));
      }
    }
    
    // Left Wall
    final leftDoors = room.doors.where((d) => d.position.x <= 10).toList();
    if (leftDoors.isEmpty) {
      walls.add(Positioned(
        top: 0, left: 0,
        child: WallWidget(width: thickness, height: room.roomSize.height, side: WallSide.left, image: _wallVertical),
      ));
    } else {
      leftDoors.sort((a, b) => a.position.y.compareTo(b.position.y));
      double currentY = 0;
      for (final door in leftDoors) {
        double wallHeight = (door.position.y + overlap) - currentY;
        if (wallHeight > 0) {
          walls.add(Positioned(
            top: currentY, left: 0,
            child: WallWidget(width: thickness, height: wallHeight, side: WallSide.left, image: _wallVertical),
          ));
        }
        currentY = door.position.y + door.size.y - overlap;
      }
      if (currentY < room.roomSize.height) {
        walls.add(Positioned(
          top: currentY, left: 0,
          child: WallWidget(width: thickness, height: room.roomSize.height - currentY, side: WallSide.left, image: _wallVertical),
        ));
      }
    }
    
    // Right Wall
    final rightDoors = room.doors.where((d) => d.position.x >= room.roomSize.width - thickness - 10).toList();
    if (rightDoors.isEmpty) {
      walls.add(Positioned(
        top: 0, right: 0,
        child: WallWidget(width: thickness, height: room.roomSize.height, side: WallSide.right, image: _wallVertical),
      ));
    } else {
      rightDoors.sort((a, b) => a.position.y.compareTo(b.position.y));
      double currentY = 0;
      for (final door in rightDoors) {
        double wallHeight = (door.position.y + overlap) - currentY;
        if (wallHeight > 0) {
          walls.add(Positioned(
            top: currentY, right: 0,
            child: WallWidget(width: thickness, height: wallHeight, side: WallSide.right, image: _wallVertical),
          ));
        }
        currentY = door.position.y + door.size.y - overlap;
      }
      if (currentY < room.roomSize.height) {
        walls.add(Positioned(
          top: currentY, right: 0,
          child: WallWidget(width: thickness, height: room.roomSize.height - currentY, side: WallSide.right, image: _wallVertical),
        ));
      }
    }
    
    return walls;
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
          behavior: HitTestBehavior.opaque,
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
            
            // Controles (Solo Web/Desktop)
            if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS))
            Positioned(
              bottom: 16,
              left: 16,
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
