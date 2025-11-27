import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/dialogue_data.dart';
import '../models/interactable_data.dart';
import '../models/room_data.dart';
import '../systems/room_manager.dart';
import '../components/interactable_object.dart';
import '../components/dialogue_system.dart';
import '../components/animated_sprite.dart';
import '../components/room_shape_clipper.dart';
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
  final double _playerSpeed = 3.0;
  final double _playerSize = 80.0;

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
  bool _canInteract = false;

  // Sistema de habitaciones
  late RoomManager _roomManager;
  bool _isTransitioning = false;
  double _transitionCooldown = 0.0;
  static const double _cooldownDuration = 0.5;
  
  // Animación de transición
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;
  
  // Focus y timer para movimiento
  late FocusNode _focusNode;
  Timer? _movementTimer;
  
  // Animación de sprite
  AnimatedSprite? _danSprite;
  AnimatedSprite? _danSpriteNorth;
  AnimatedSprite? _danSpriteSouth;
  AnimatedSprite? _doorSprite;
  AnimatedSprite? _stairsDownSprite; // Nuevo sprite para escaleras
  String _currentDirection = 'SOUTH';
  int _currentFrame = 0;
  double _animationTimer = 0.0;
  static const double _frameRate = 0.15;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _roomManager = RoomManager();
    
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeInOut),
    );
    
    _loadDanSprite();
    _showIntroDialogue();
    _startMovementLoop();
  }
  
  Future<void> _loadDanSprite() async {
    try {
      final spriteNorth = await AnimatedSprite.load('assets/sprites/dan_walk_north.png');
      final spriteSouth = await AnimatedSprite.load('assets/sprites/dan_walk_south.png');
      final doorSprite = await AnimatedSprite.load(
        'assets/images/doors_sprite_sheet.png',
        columns: 2,
        rows: 1,
      );
      
      // Intentar cargar sprite de escaleras (si existe)
      AnimatedSprite? stairsDown;
      try {
        stairsDown = await AnimatedSprite.load(
          'assets/images/stairs_down.png',
          columns: 1,
          rows: 1,
        );
      } catch (e) {
        print('Warning: stairs_down.png not found yet.');
      }
      
      if (mounted) {
        setState(() {
          _danSpriteNorth = spriteNorth;
          _danSpriteSouth = spriteSouth;
          _danSprite = spriteSouth;
          _doorSprite = doorSprite;
          _stairsDownSprite = stairsDown;
        });
      }
    } catch (e) {
      print('Error loading sprites: $e');
    }
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
        if (_transitionCooldown > 0) {
          _transitionCooldown -= 0.016;
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
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const BunkerScene()),
    );
  }

  void _updatePlayerPosition() {
    if (_isDialogueActive || _isTransitioning) return;

    Vector2 velocity = const Vector2(0, 0);

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

    if (_isJoystickActive) {
      velocity = velocity + _joystickInput;
    }

    if (velocity.x != 0 || velocity.y != 0) {
      if (velocity.length > 1) {
        velocity = velocity.normalized();
      } else if (velocity.length == 0) {
        // do nothing
      } else {
        velocity = velocity.normalized();
      }
      
      velocity = velocity * _playerSpeed;

      final room = _roomManager.currentRoom;
      
      final newX = (_playerPosition.x + velocity.x);
      final newY = (_playerPosition.y + velocity.y);
      final newPos = Vector2(newX, newY);
      
      if (_isValidPosition(newPos, room)) {
        setState(() {
          _playerPosition = newPos;
          
          if (velocity.y < -0.1) {
            _currentDirection = 'NORTH';
            _danSprite = _danSpriteNorth;
          } else if (velocity.y > 0.1) {
            _currentDirection = 'SOUTH';
            _danSprite = _danSpriteSouth;
          }
          
          _animationTimer += 0.016;
          if (_animationTimer >= _frameRate) {
            _animationTimer = 0.0;
            _currentFrame = (_currentFrame + 1) % 9;
          }
        });
      }
    } else {
      if (_currentFrame != 0) {
        setState(() {
          _currentFrame = 0;
        });
      }
    }
      
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

  bool _isValidPosition(Vector2 pos, RoomData room) {
    // Aumentamos un poco el padding para evitar que el sprite se salga visualmente
    final padding = _playerSize / 1.8; 
    
    if (pos.x < padding || pos.x > room.roomSize.width - padding ||
        pos.y < padding || pos.y > room.roomSize.height - padding) {
      return false;
    }

    if (room.shape == RoomShape.cutCorners) {
      final hallwayWidth = room.roomSize.width * 0.25;
      final hallwayHeight = room.roomSize.height * 0.25;
      final hallwayY = room.roomSize.height * 0.4;
      
      // Bloquear SOLO las esquinas cortadas, NO el pasillo lateral
      // Esquina superior izquierda (arriba del pasillo)
      // Ajuste visual: incluir la altura de la pared (aprox 50-60px) para no caminar sobre ella
      if (pos.x < hallwayWidth + padding && pos.y < hallwayY + 50) {
        return false;
      }
      
      // Esquina inferior izquierda (abajo del pasillo)
      // ELIMINADO padding vertical para permitir paso fluido al pasillo
      if (pos.x < hallwayWidth + padding && pos.y > hallwayY + hallwayHeight) {
        return false;
      }
    }
    
    // Colisiones para habitaciones hexagonales (esquinas cortadas diagonalmente)
    if (room.shape == RoomShape.hexagon) {
      final cornerCut = room.roomSize.height * 0.15;
      
      // Esquina superior izquierda
      if (pos.y < cornerCut + padding && pos.x < cornerCut + padding) {
        return false;
      }
      
      // Esquina superior derecha
      if (pos.y < cornerCut + padding && pos.x > room.roomSize.width - cornerCut - padding) {
        return false;
      }
      
      // Esquina inferior izquierda
      if (pos.y > room.roomSize.height - cornerCut - padding && pos.x < cornerCut + padding) {
        return false;
      }
      
      // Esquina inferior derecha
      if (pos.y > room.roomSize.height - cornerCut - padding && 
          pos.x > room.roomSize.width - cornerCut - padding) {
        return false;
      }
    }
    
    // Colisiones para habitaciones en forma de L
    if (room.shape == RoomShape.lShape) {
      final cutWidth = room.roomSize.width * 0.4;
      final cutHeight = room.roomSize.height * 0.4;
      
      // Bloquear la esquina inferior DERECHA (área cortada)
      // El corte está en X > (width - cutWidth) y Y > (height - cutHeight)
      if (pos.x > room.roomSize.width - cutWidth - padding && 
          pos.y > room.roomSize.height - cutHeight - padding) {
        return false;
      }
    }
    
    // Colisiones para habitaciones en forma de U
    if (room.shape == RoomShape.uShape) {
      final towerWidth = room.roomSize.width * 0.17; 
      final towerHeight = room.roomSize.height * 0.2; 
      
      // 1. Pared Central (Detrás del sofá)
      if (pos.x > towerWidth && pos.x < room.roomSize.width - towerWidth) {
         // Ajuste visual: La pared tiene 60px de alto. El límite debe estar cerca de eso.
         double wallLimitY = towerHeight + 55; 
         
         // Verificar si hay una puerta en esta sección para permitir el paso
         bool isNearDoor = false;
         for (final door in room.doors) {
            // Si la puerta está en la pared norte (o cerca de la pared central)
            if (door.position.dy < towerHeight + 50) {
               // Si estamos alineados horizontalmente con la puerta
               if ((pos.x - (door.position.dx + door.size.x/2)).abs() < door.size.x / 2) {
                  isNearDoor = true;
                  break;
               }
            }
         }
         
         // Si hay puerta, permitimos subir más (el límite es la puerta misma, no la pared)
         if (isNearDoor) {
            wallLimitY = towerHeight - 20; // Permitir entrar al pasillo de la puerta
         }

         if (pos.y < wallLimitY) {
           return false;
         }
      }
      
      // 2. Paredes Laterales Superiores (Torres)
      // Torre Izquierda: X < towerWidth, Y < padding (solo pared norte)
      // Torre Derecha: X > width - towerWidth, Y < padding
      // Las paredes verticales internas de las torres ya están cubiertas por los límites generales o lógica específica si fuera necesario.
      
      // Excepción para puertas:
      // Si hay una puerta en la pared norte de las torres, permitir paso.
      // Pero aquí estamos definiendo PAREDES SÓLIDAS.
      
      // Pared superior de torre izquierda
      // Ajuste visual: pared de 60px de alto
      if (pos.x < towerWidth && pos.y < 55) {
         // Verificar si hay puerta aquí antes de bloquear?
         // Simplificación: Bloquear pared norte siempre, las puertas suelen tener su propia lógica o estar desplazadas.
         // Pero si la puerta está en (x, 0), necesitamos permitir paso.
         bool isDoorHere = false;
         for (final door in room.doors) {
            if (door.position.dy < 50 && door.position.dx < towerWidth) {
               if ((pos.x - door.position.dx).abs() < 40) isDoorHere = true;
            }
         }
         if (!isDoorHere) return false;
      }
      
      // Pared superior de torre derecha
      // Ajuste visual: pared de 60px de alto
      if (pos.x > room.roomSize.width - towerWidth && pos.y < 55) {
         bool isDoorHere = false;
         for (final door in room.doors) {
            if (door.position.dy < 50 && door.position.dx > room.roomSize.width - towerWidth) {
               if ((pos.x - door.position.dx).abs() < 40) isDoorHere = true;
            }
         }
         if (!isDoorHere) return false;
      }
    }
    
    // Colisiones con MUEBLES (Interactables tipo furniture)
    for (final interactable in room.interactables) {
      if (interactable.type == InteractableType.furniture) {
        // Hitbox del mueble
        final furnitureRect = Rect.fromLTWH(
          interactable.position.dx,
          interactable.position.dy,
          interactable.size.x,
          interactable.size.y,
        );
        
        // Hitbox del jugador (pies)
        final playerRect = Rect.fromLTWH(
          pos.x - _playerSize / 4,
          pos.y - _playerSize / 4,
          _playerSize / 2,
          _playerSize / 2,
        );

        // Lógica específica para el SOFÁ
        if (interactable.id == 'sofa') {
           // Crear una hitbox MUY ajustada al centro visual del sofá
           final sofaHitbox = Rect.fromLTWH(
             interactable.position.dx + 50, // +50 margen izq
             interactable.position.dy + 90, // +90 margen sup (casi todo el respaldo libre)
             interactable.size.x - 100,  // -100 ancho total
             interactable.size.y - 130, // -130 alto total (muy delgado, solo el asiento)
           );
           
           if (sofaHitbox.overlaps(playerRect)) {
             return false;
           }
        } else {
           // Muebles genéricos
           // Reducir un poco la hitbox del mueble para ser permisivos
           final collisionPadding = 30.0; 
           final paddedRect = furnitureRect.deflate(collisionPadding);
           
           if (paddedRect.overlaps(playerRect)) {
             return false;
           }
        }
      }
    }

    return true;
  }

  Future<void> _transitionToRoom(String targetRoomId, {Vector2? spawnPosition}) async {
    if (_isTransitioning || _transitionCooldown > 0) return;
    
    setState(() {
      _isTransitioning = true;
    });

    await _transitionController.forward();
    
    setState(() {
      _roomManager.changeRoom(targetRoomId);
      _playerPosition = spawnPosition ?? _roomManager.currentRoom.playerSpawnPosition;
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

    // Prioridad: Puertas
    for (final door in room.doors) {
      if (door.isPlayerInRange(_playerPosition, _playerSize)) {
        _transitionToRoom(door.targetRoomId, spawnPosition: door.targetSpawnPosition);
        return;
      }
    }

    for (final interactable in room.interactables) {
      if (interactable.isInRange(_playerPosition, interactionRadius)) {
        debugPrint('Interacting with: ${interactable.id}');
        
        if (interactable.isOneTime && interactable.hasBeenInteracted) {
          debugPrint('Already interacted with ${interactable.id}');
          return;
        }

        interactable.hasBeenInteracted = true;
        interactable.onInteract?.call();

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
        
        return;
      }
    }
    
    debugPrint('No interactable in range');
  }

  Widget buildPipe({double? width, double? height, bool isVertical = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[800]!,
            Colors.grey[400]!,
            Colors.grey[800]!,
          ],
          begin: isVertical ? Alignment.centerLeft : Alignment.topCenter,
          end: isVertical ? Alignment.centerRight : Alignment.bottomCenter,
        ),
      ),
    );
  }

  List<Widget> _buildRectangularWalls(RoomData room) {
    return [
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: 60,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/wall_texture.jpg'),
              repeat: ImageRepeat.repeatX,
              alignment: Alignment.bottomCenter,
            ),
            border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: 20,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.brown[900],
            border: const Border(top: BorderSide(color: Colors.black, width: 2)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                offset: Offset(0, -2),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        width: 20,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.brown[900],
            border: const Border(right: BorderSide(color: Colors.black, width: 2)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                offset: Offset(2, 0),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        top: 0,
        bottom: 0,
        right: 0,
        width: 20,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.brown[900],
            border: const Border(left: BorderSide(color: Colors.black, width: 2)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                offset: Offset(-2, 0),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildCutCornersWalls(RoomData room) {
    final hallwayWidth = room.roomSize.width * 0.25;
    final hallwayHeight = room.roomSize.height * 0.25; // Coincidir con RoomShapeClipper
    final hallwayY = room.roomSize.height * 0.4;
    
    const wallHeight = 60.0;
    const wallThickness = 20.0;
    const pipeThickness = 8.0;

    Widget buildPipe({double? width, double? height, bool isVertical = false}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF5D4037),
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(
            colors: [Color(0xFF4E342E), Color(0xFF8D6E63), Color(0xFF4E342E)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      );
    }

    return [
      Positioned(
        top: 0,
        left: hallwayWidth,
        right: 0,
        height: wallHeight,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/wall_texture.jpg'),
                  repeat: ImageRepeat.repeatX,
                  alignment: Alignment.bottomCenter,
                ),
                border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pipeThickness,
              child: buildPipe(height: pipeThickness),
            ),
          ],
        ),
      ),
      Positioned(
        top: 0,
        left: hallwayWidth,
        width: wallThickness,
        height: hallwayY,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(right: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: pipeThickness,
              child: buildPipe(width: pipeThickness, isVertical: true),
            ),
          ],
        ),
      ),
      Positioned(
        top: hallwayY,
        left: 0,
        width: hallwayWidth + wallThickness,
        height: wallHeight,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/wall_texture.jpg'),
                  repeat: ImageRepeat.repeatX,
                  alignment: Alignment.bottomCenter,
                ),
                border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pipeThickness,
              child: buildPipe(height: pipeThickness),
            ),
          ],
        ),
      ),
      Positioned(
        top: hallwayY + hallwayHeight,
        left: 0,
        width: hallwayWidth,
        height: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(top: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
             Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pipeThickness,
              child: buildPipe(height: pipeThickness),
            ),
          ],
        ),
      ),
      Positioned(
        top: hallwayY + hallwayHeight,
        bottom: 0,
        left: hallwayWidth,
        width: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(right: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: pipeThickness,
              child: buildPipe(width: pipeThickness, isVertical: true),
            ),
          ],
        ),
      ),
      Positioned(
        top: 0,
        bottom: 0,
        right: 0,
        width: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(left: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: pipeThickness,
              child: buildPipe(width: pipeThickness, isVertical: true),
            ),
          ],
        ),
      ),
      Positioned(
        bottom: 0,
        left: hallwayWidth,
        right: 0,
        height: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(top: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
             Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pipeThickness,
              child: buildPipe(height: pipeThickness),
            ),
          ],
        ),
      ),
      Positioned(
        top: hallwayY,
        left: 0,
        width: wallThickness, 
        height: hallwayHeight + wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(right: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: pipeThickness,
              child: buildPipe(width: pipeThickness, isVertical: true),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildHexagonWalls(RoomData room) {
    const wallHeight = 60.0;
    const wallThickness = 20.0;
    const pipeThickness = 8.0;
    final cornerCut = room.roomSize.height * 0.15;

    Widget buildPipe({double? width, double? height, bool isVertical = false}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF5D4037),
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(
            colors: [Color(0xFF4E342E), Color(0xFF8D6E63), Color(0xFF4E342E)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      );
    }

    return [
      // Pared superior (con cortes en esquinas)
      Positioned(
        top: 0,
        left: cornerCut,
        right: cornerCut,
        height: wallHeight,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/wall_texture.jpg'),
                  repeat: ImageRepeat.repeatX,
                  alignment: Alignment.bottomCenter,
                ),
                border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pipeThickness,
              child: buildPipe(height: pipeThickness),
            ),
          ],
        ),
      ),
      
      // Pared inferior (con cortes en esquinas)
      Positioned(
        bottom: 0,
        left: cornerCut,
        right: cornerCut,
        height: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(top: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pipeThickness,
              child: buildPipe(height: pipeThickness),
            ),
          ],
        ),
      ),
      
      // Pared izquierda (con cortes en esquinas)
      Positioned(
        top: cornerCut,
        bottom: cornerCut,
        left: 0,
        width: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(right: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: pipeThickness,
              child: buildPipe(width: pipeThickness, isVertical: true),
            ),
          ],
        ),
      ),
      
      // Pared derecha (con cortes en esquinas)
      Positioned(
        top: cornerCut,
        bottom: cornerCut,
        right: 0,
        width: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(left: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: pipeThickness,
              child: buildPipe(width: pipeThickness, isVertical: true),
            ),
          ],
        ),
      ),
      
      // Esquinas diagonales (4 bloques sólidos)
      // Esquina superior izquierda
      Positioned(
        top: 0,
        left: 0,
        width: cornerCut,
        height: cornerCut,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.brown[900],
            border: const Border(
              bottom: BorderSide(color: Colors.black, width: 2),
              right: BorderSide(color: Colors.black, width: 2),
            ),
          ),
        ),
      ),
      
      // Esquina superior derecha
      Positioned(
        top: 0,
        right: 0,
        width: cornerCut,
        height: cornerCut,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.brown[900],
            border: const Border(
              bottom: BorderSide(color: Colors.black, width: 2),
              left: BorderSide(color: Colors.black, width: 2),
            ),
          ),
        ),
      ),
      
      // Esquina inferior izquierda
      Positioned(
        bottom: 0,
        left: 0,
        width: cornerCut,
        height: cornerCut,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.brown[900],
            border: const Border(
              top: BorderSide(color: Colors.black, width: 2),
              right: BorderSide(color: Colors.black, width: 2),
            ),
          ),
        ),
      ),
      
      // Esquina inferior derecha
      Positioned(
        bottom: 0,
        right: 0,
        width: cornerCut,
        height: cornerCut,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.brown[900],
            border: const Border(
              top: BorderSide(color: Colors.black, width: 2),
              left: BorderSide(color: Colors.black, width: 2),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildLShapeWalls(RoomData room) {
    const wallHeight = 60.0;
    const wallThickness = 20.0;
    const pipeThickness = 8.0;
    final cutWidth = room.roomSize.width * 0.4;
    final cutHeight = room.roomSize.height * 0.4;

    Widget buildPipe({double? width, double? height, bool isVertical = false}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF5D4037),
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(
            colors: [Color(0xFF4E342E), Color(0xFF8D6E63), Color(0xFF4E342E)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      );
    }

    return [
      // 1. Pared Superior (Completa)
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: wallHeight,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/wall_texture.jpg'),
                  repeat: ImageRepeat.repeatX,
                  alignment: Alignment.bottomCenter,
                ),
                border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pipeThickness,
              child: buildPipe(height: pipeThickness),
            ),
          ],
        ),
      ),

      // 2. Pared Izquierda (Completa)
      Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        width: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(right: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: pipeThickness,
              child: buildPipe(width: pipeThickness, isVertical: true),
            ),
          ],
        ),
      ),

      // 3. Pared Derecha Superior (Hasta el corte)
      Positioned(
        top: 0,
        right: 0,
        height: room.roomSize.height - cutHeight,
        width: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(left: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: pipeThickness,
              child: buildPipe(width: pipeThickness, isVertical: true),
            ),
          ],
        ),
      ),

      // 4. Pared Inferior Izquierda (Hasta el corte)
      Positioned(
        bottom: 0,
        left: 0,
        right: cutWidth, // Llega hasta donde empieza el corte desde la derecha
        height: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/wall_texture.jpg'),
                  repeat: ImageRepeat.repeatX,
                  alignment: Alignment.bottomCenter,
                ),
                border: Border(top: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
          ],
        ),
      ),

      // 5. Paredes del Corte (Esquina Inferior Derecha)
      
      // Pared Vertical del Corte (baja desde el techo del corte hasta el suelo)
      Positioned(
        top: room.roomSize.height - cutHeight,
        bottom: 0,
        right: cutWidth,
        width: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(right: BorderSide(color: Colors.black, width: 2)), // Borde derecho porque es pared externa del cuarto
              ),
            ),
             Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: pipeThickness,
              child: buildPipe(width: pipeThickness, isVertical: true),
            ),
          ],
        ),
      ),

      // Pared Horizontal del Corte (techo del corte)
      Positioned(
        top: room.roomSize.height - cutHeight,
        right: 0,
        width: cutWidth,
        height: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/wall_texture.jpg'),
                  repeat: ImageRepeat.repeatX,
                  alignment: Alignment.bottomCenter,
                ),
                border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
             Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pipeThickness,
              child: buildPipe(height: pipeThickness),
            ),
          ],
        ),
      ),

      
      // Pared inferior (solo la parte derecha, desde el corte)
      Positioned(
        bottom: 0,
        left: cutWidth,
        right: 0,
        height: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(top: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pipeThickness,
              child: buildPipe(height: pipeThickness),
            ),
          ],
        ),
      ),
      
      // Pared vertical interna (borde del corte, lado derecho)
      Positioned(
        top: room.roomSize.height - cutHeight,
        bottom: 0,
        left: cutWidth,
        width: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(
                  left: BorderSide(color: Colors.black, width: 2),
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: pipeThickness,
              child: buildPipe(width: pipeThickness, isVertical: true),
            ),
          ],
        ),
      ),
      
      // Pared horizontal interna (borde del corte, lado superior)
      Positioned(
        top: room.roomSize.height - cutHeight,
        left: 0,
        width: cutWidth,
        height: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pipeThickness,
              child: buildPipe(height: pipeThickness),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildBottomEntranceWalls(RoomData room) {
    final wallThickness = 60.0;
    final pipeThickness = 10.0;
    
    // Dimensiones del pasillo (mismas que en RoomShapeClipper)
    final hallwayWidth = 120.0;
    final hallwayHeight = 150.0;
    final mainRoomHeight = room.roomSize.height - hallwayHeight;
    final hallwayX = (room.roomSize.width - hallwayWidth) / 2;

    Widget buildPipe({double? width, double? height, bool isVertical = false}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF5D4037),
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(
            colors: [Color(0xFF4E342E), Color(0xFF8D6E63), Color(0xFF4E342E)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      );
    }
    
    return [
      // 1. Pared Norte (Top) - Completa
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/wall_texture.jpg'),
                  repeat: ImageRepeat.repeatX,
                  alignment: Alignment.bottomCenter,
                ),
                border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pipeThickness,
              child: buildPipe(height: pipeThickness),
            ),
          ],
        ),
      ),
      
      // 2. Pared Oeste (Izquierda) - Completa hasta mainRoomHeight
      Positioned(
        top: 0,
        left: 0,
        height: mainRoomHeight,
        width: wallThickness, // Pared vertical izquierda
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(right: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: pipeThickness,
              child: buildPipe(width: pipeThickness, isVertical: true),
            ),
          ],
        ),
      ),
      
      // 3. Pared Este (Derecha) - Completa hasta mainRoomHeight
      Positioned(
        top: 0,
        right: 0,
        height: mainRoomHeight,
        width: wallThickness, // Pared vertical derecha
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(left: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: pipeThickness,
              child: buildPipe(width: pipeThickness, isVertical: true),
            ),
          ],
        ),
      ),
      
      // 4. Pared Sur Izquierda (Main Room)
      Positioned(
        top: mainRoomHeight - wallThickness,
        left: 0,
        width: hallwayX, // Hasta el inicio del pasillo
        height: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/wall_texture.jpg'),
                  repeat: ImageRepeat.repeatX,
                  alignment: Alignment.bottomCenter,
                ),
                border: Border(top: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
          ],
        ),
      ),
      
      // 5. Pared Sur Derecha (Main Room)
      Positioned(
        top: mainRoomHeight - wallThickness,
        left: hallwayX + hallwayWidth,
        right: 0, // Hasta el final a la derecha
        height: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/wall_texture.jpg'),
                  repeat: ImageRepeat.repeatX,
                  alignment: Alignment.bottomCenter,
                ),
                border: Border(top: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
          ],
        ),
      ),
      
      // 6. Paredes del Pasillo (Verticales)
      // Izquierda del pasillo
      Positioned(
        top: mainRoomHeight,
        left: hallwayX,
        height: hallwayHeight,
        width: 20, // Pared delgada para pasillo
        child: Container(
          decoration: BoxDecoration(
            color: Colors.brown[900],
            border: const Border(right: BorderSide(color: Colors.black, width: 2)),
          ),
        ),
      ),
      
      // Derecha del pasillo
      Positioned(
        top: mainRoomHeight,
        left: hallwayX + hallwayWidth - 20,
        height: hallwayHeight,
        width: 20, // Pared delgada para pasillo
        child: Container(
          decoration: BoxDecoration(
            color: Colors.brown[900],
            border: const Border(left: BorderSide(color: Colors.black, width: 2)),
          ),
        ),
      ),
      
      // 7. Fondo del pasillo (Sur final) - Donde irán las escaleras
      // No dibujamos pared aquí para dejar que las escaleras "salgan"
    ];
  }

  List<Widget> _buildUShapeWalls(RoomData room) {
    const wallHeight = 60.0;
    const wallThickness = 20.0;
    const pipeThickness = 8.0;
    final towerWidth = room.roomSize.width * 0.17; // 120px
    final towerHeight = room.roomSize.height * 0.2; // 120px

    Widget buildPipe({double? width, double? height, bool isVertical = false}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF5D4037),
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(
            colors: [Color(0xFF4E342E), Color(0xFF8D6E63), Color(0xFF4E342E)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      );
    }

    return [
      // --- PAREDES EXTERIORES ---
      
      // Pared superior izquierda (Torre Izq Top)
      Positioned(
        top: 0,
        left: 0,
        width: towerWidth,
        height: wallHeight,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/wall_texture.jpg'),
                  repeat: ImageRepeat.repeatX,
                  alignment: Alignment.bottomCenter,
                ),
                border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pipeThickness,
              child: buildPipe(height: pipeThickness),
            ),
          ],
        ),
      ),

      // Pared superior derecha (Torre Der Top)
      Positioned(
        top: 0,
        right: 0,
        width: towerWidth,
        height: wallHeight,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/wall_texture.jpg'),
                  repeat: ImageRepeat.repeatX,
                  alignment: Alignment.bottomCenter,
                ),
                border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pipeThickness,
              child: buildPipe(height: pipeThickness),
            ),
          ],
        ),
      ),

      // Pared izquierda (Completa)
      Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        width: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(right: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: pipeThickness,
              child: buildPipe(width: pipeThickness, isVertical: true),
            ),
          ],
        ),
      ),

      // Pared derecha (Completa)
      Positioned(
        top: 0,
        bottom: 0,
        right: 0,
        width: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(left: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: pipeThickness,
              child: buildPipe(width: pipeThickness, isVertical: true),
            ),
          ],
        ),
      ),

      // Pared inferior (Completa)
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(top: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pipeThickness,
              child: buildPipe(height: pipeThickness),
            ),
          ],
        ),
      ),

      // --- PAREDES INTERNAS (HUECO U) ---

      // Pared vertical interna izquierda (Lado derecho de torre izq)
      Positioned(
        top: 0,
        left: towerWidth,
        height: towerHeight,
        width: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(left: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: pipeThickness,
              child: buildPipe(width: pipeThickness, isVertical: true),
            ),
          ],
        ),
      ),

      // Pared vertical interna derecha (Lado izquierdo de torre der)
      Positioned(
        top: 0,
        right: towerWidth,
        height: towerHeight,
        width: wallThickness,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.brown[900],
                border: const Border(right: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: pipeThickness,
              child: buildPipe(width: pipeThickness, isVertical: true),
            ),
          ],
        ),
      ),

      // Pared horizontal central (Fondo del hueco - donde va la puerta del Hallway)
      // Esta pared mira al SUR, pero visualmente es como una pared norte para la sala principal
      Positioned(
        top: towerHeight,
        left: towerWidth,
        right: towerWidth,
        height: wallHeight,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/wall_texture.jpg'),
                  repeat: ImageRepeat.repeatX,
                  alignment: Alignment.bottomCenter,
                ),
                border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pipeThickness,
              child: buildPipe(height: pipeThickness),
            ),
          ],
        ),
      ),
    ];
  }

  void _checkDoorCollisions() {
    final room = _roomManager.currentRoom;
    bool nearDoor = false;
    
    for (final door in room.doors) {
      if (door.isPlayerInRange(_playerPosition, _playerSize)) {
        nearDoor = true;
        break;
      }
    }
    
    if (_canInteract != nearDoor) {
      setState(() {
        _canInteract = nearDoor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = _roomManager.currentRoom;
    
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
                debugPrint('ESC pressed - skipping dialogue');
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
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              final screenSize = MediaQuery.of(context).size;
              if (details.globalPosition.dx < screenSize.width / 2) {
                setState(() {
                  _isJoystickActive = true;
                  _joystickOrigin = details.globalPosition;
                  _joystickPosition = details.globalPosition;
                  _joystickInput = Vector2(0, 0);
                });
              }
            },
            onPanUpdate: (details) {
              if (_isJoystickActive && _joystickOrigin != null) {
                setState(() {
                  final currentPos = details.globalPosition;
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
            onPanEnd: (details) {
              setState(() {
                _isJoystickActive = false;
                _joystickOrigin = null;
                _joystickPosition = null;
                _joystickInput = Vector2(0, 0);
              });
            },
            child: Stack(
              children: [
                Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: room.roomSize.width,
                      height: room.roomSize.height,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipPath(
                            clipper: RoomShapeClipper(shape: room.shape),
                            child: Container(
                              width: room.roomSize.width,
                              height: room.roomSize.height,
                              decoration: BoxDecoration(
                                color: room.backgroundColor,
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/wood_floor.jpg'),
                                  repeat: ImageRepeat.repeat,
                                  scale: 4.0, 
                                ),
                              ),
                            ),
                          ),

                          if (room.shape == RoomShape.cutCorners)
                            ..._buildCutCornersWalls(room)
                          else if (room.shape == RoomShape.hexagon)
                            ..._buildHexagonWalls(room)
                          else if (room.shape == RoomShape.lShape)
                            ..._buildLShapeWalls(room)
                          else if (room.shape == RoomShape.uShape)
                            ..._buildUShapeWalls(room)
                          else
                            ..._buildRectangularWalls(room),

                          ...room.doors.map((door) {
                            final dist = _playerPosition.distanceTo(Vector2(
                              door.position.dx + door.size.x / 2,
                              door.position.dy + door.size.y / 2,
                            ));
                            final isOpen = dist < 80.0;
                            
                            // LÓGICA ESPECIAL PARA SALA DE ESTAR
                            final isLivingRoom = room.id == 'living_room';
                            final isHorizontal = door.size.x > door.size.y;
                              
                            if (isHorizontal && _doorSprite != null) {
                              final visualWidth = door.size.x * 1.2;
                              // Altura ajustada para que la puerta quepa sin salirse del mapa
                              final visualHeight = door.size.y * 4.5; 
                              
                              final isNorth = door.position.dy < room.roomSize.height / 2;
                              final isSouth = door.position.dy > room.roomSize.height / 2;
                              
                              double topPos;
                              
                              if (isNorth) {
                                // Lógica específica para sala en U
                                if (isLivingRoom && door.position.dy > 50) {
                                  // Puerta central (Hallway) - La pared está más abajo (y=120)
                                  topPos = 120.0 + 60.0 - visualHeight + door.size.y;
                                } else if (door.position.dy < 100) {
                                  // Puertas norte estándar
                                  topPos = 60.0 - visualHeight + door.size.y;
                                } else {
                                  topPos = door.position.dy - visualHeight + door.size.y;
                                }
                              } else if (isSouth) {
                                // Puerta en pared sur (abajo)
                                topPos = room.roomSize.height - visualHeight + 5; 
                              } else {
                                // Puertas en paredes internas
                                topPos = door.position.dy - visualHeight + door.size.y;
                                
                                if (room.shape == RoomShape.cutCorners && door.position.dy > 100 && door.position.dy < room.roomSize.height / 2) {
                                   topPos -= 10.0; 
                                }
                              }

                              return Positioned(
                                left: door.position.x - (visualWidth - door.size.x) / 2, // Centrar horizontalmente
                                top: topPos, 
                                child: SizedBox(
                                  width: visualWidth,
                                  height: visualHeight,
                                  child: AnimatedSpriteWidget(
                                    sprite: _doorSprite!,
                                    direction: 'DOOR',
                                    frameIndex: isOpen ? 1 : 0,
                                    size: visualWidth,
                                  ),
                                ),
                              );
                            } else {
                              // Puertas verticales (izquierda/derecha)
                              if (_doorSprite != null) {
                                // Para puertas verticales, intercambiamos dimensiones porque rotaremos 90°
                                final spriteWidth = door.size.y * 4.5; // Aumentado para que la puerta sea alta
                                final spriteHeight = door.size.x * 1.2; // El ancho del sprite (después de rotar)
                                
                                final isWest = door.position.dx < room.roomSize.width / 2;
                                final isEast = door.position.dx > room.roomSize.width / 2;
                                
                                double leftPos;
                                
                                if (isWest && door.position.dx < 100) {
                                  // Puerta en pared oeste (izquierda) - pegada a la pared
                                  leftPos = 20.0 - spriteHeight + door.size.x; 
                                } else if (isEast) {
                                  // Puerta en pared este (derecha) - PEGADA A LA PARED
                                  leftPos = room.roomSize.width - 20.0 - spriteHeight + door.size.x;
                                } else {
                                  // Puertas internas
                                  leftPos = door.position.x - (spriteHeight - door.size.x) / 2;
                                }
                                
                                return Positioned(
                                  left: leftPos,
                                  top: door.position.y - (spriteWidth - door.size.y) / 2, // Centrar verticalmente
                                  child: SizedBox(
                                    width: spriteHeight, // Ancho del contenedor (antes de rotar)
                                    height: spriteWidth, // Alto del contenedor (antes de rotar)
                                    child: Transform.rotate(
                                      angle: 1.5708, // 90 grados en radianes (π/2)
                                      child: AnimatedSpriteWidget(
                                        sprite: _doorSprite!,
                                        direction: 'DOOR',
                                        frameIndex: isOpen ? 1 : 0,
                                        size: spriteWidth,
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                // Fallback si no hay sprite
                                return Positioned(
                                  left: door.position.x,
                                  top: door.position.y,
                                  child: Container(
                                    width: door.size.x,
                                    height: door.size.y,
                                    decoration: BoxDecoration(
                                      color: isOpen ? Colors.black : Colors.brown[800],
                                      border: Border.all(color: Colors.brown[900]!, width: 2),
                                    ),
                                  ),
                                );
                              }
                            }
                          }),

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

                          Positioned(
                            left: _playerPosition.x - _playerSize / 2,
                            top: _playerPosition.y - _playerSize / 2,
                            child: _danSprite != null
                                ? AnimatedSpriteWidget(
                                    sprite: _danSprite!,
                                    direction: _currentDirection,
                                    frameIndex: _currentFrame,
                                    size: _playerSize,
                                  )
                                : SizedBox(
                                    width: _playerSize,
                                    height: _playerSize,
                                    child: Container(
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
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                if (_isTransitioning)
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Container(
                        color: Colors.black.withOpacity(_fadeAnimation.value),
                      );
                    },
                  ),
                  
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
                
                if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS))
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
}
