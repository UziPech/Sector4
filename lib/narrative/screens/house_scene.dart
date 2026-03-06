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
import '../components/flashlight_overlay.dart';
import '../services/save_system.dart';
import 'bunker_scene.dart';
import '../../game/audio_manager.dart';
import 'package:flame_audio/flame_audio.dart';
import 'menu_screen.dart';
import '../../game/ui/settings_overlay.dart';

/// Escena de la casa de Dan (Capítulo 1) - Con sistema de habitaciones
class HouseScene extends StatefulWidget {
  const HouseScene({super.key});

  @override
  State<HouseScene> createState() => _HouseSceneState();
}

class _HouseSceneState extends State<HouseScene>
    with SingleTickerProviderStateMixin {
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

  AnimatedSprite? _danSprite;
  AnimatedSprite? _danSpriteNorth;
  AnimatedSprite? _doorSprite;
  String _currentDirection = 'SOUTH';
  int _currentFrameOffset = 6; // Default to row 3 (South)
  int _currentFrame = 0;
  double _animationTimer = 0.0;
  static const double _frameRate = 0.15;

  // Configuración In-Game
  bool _isConfigOpen = false;
  bool _isPaused = false; // Estado de pausa
  double _volume = 0.5; // Default music volume
  double _sfxVolume = 0.8; // Default SFX volume

  // HUD dinámico
  bool _isHudVisible = true;
  Timer? _hudTimer;

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

    // Iniciar música del capítulo
    AudioManager().playHouseMusic();

    // Iniciar temporizador del HUD
    WidgetsBinding.instance.addPostFrameCallback((_) => _resetHudTimer());
  }

  Future<void> _loadDanSprite() async {
    try {
      final spriteMain = await AnimatedSprite.load(
        'assets/sprites/caminar_dan.png',
        columns: 3,
        rows: 3,
      );
      final spriteNorth = await AnimatedSprite.load(
        'assets/sprites/dan_walk_north.png',
      );
      final doorSprite = await AnimatedSprite.load(
        'assets/images/doors_sprite_sheet.png',
        columns: 2,
        rows: 1,
      );

      if (mounted) {
        setState(() {
          _danSprite = spriteMain;
          _danSpriteNorth = spriteNorth;
          _doorSprite = doorSprite;
        });
      }
    } catch (e) {
      // print('Error loading sprites: $e');
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _movementTimer?.cancel();
    _hudTimer?.cancel();
    _transitionController.dispose();
    super.dispose();
  }

  void _resetHudTimer() {
    if (!mounted) return;
    setState(() {
      _isHudVisible = true;
    });
    _hudTimer?.cancel();
    _hudTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isHudVisible = false;
        });
      }
    });
  }

  void _startMovementLoop() {
    _movementTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (mounted) {
        if (_transitionCooldown > 0) {
          _transitionCooldown -= 0.016;
        }

        if (_transitionCooldown > 0) {
          _transitionCooldown -= 0.016;
        }

        // Pausar lógica si el juego está pausado
        if (_isPaused) return;

        if (!_isTransitioning) {
          _updatePlayerPosition();
          _checkInteractions();
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
              text:
                  'El silencio. Es más ensordecedor que cualquier explosión en una operación encubierta.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text:
                  'Irónico, ¿no? Yo, que pasé años persiguiendo sombras, protegiendo fronteras, un investigador de élite...',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text:
                  '...y mi propia mente se convirtió en la zona de exclusión más peligrosa que jamás pisé.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Me retiré. No, seamos honestos. Fui forzado a retirarme.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text:
                  'Cuando perdí a mi esposa, no perdí solo una persona; perdí el suelo, la gravedad que me mantenía anclado a la realidad.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text:
                  'Fui, en el campo, una responsabilidad, un riesgo de seguridad de proporciones épicas.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text:
                  'El duelo me convirtió en un desecho, un YÅ«rei sin misión. ¿De qué sirve la brillantez táctica cuando la voluntad de vivir se ha desvanecido?',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text:
                  'Y luego estaba ella. Mi hija. La única luz que atravesaba esta niebla gris que se asentó sobre mí.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Era mi última línea de defensa contra la Caída total.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text:
                  'Cuando me dijo que le habían aceptado el intercambio a Japón, que su nivel académico era excepcional...',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text:
                  'Sentí el pánico, ese egoísmo crudo que me gritaba que la encadenara aquí, que la obligara a ser mi enfermera emocional.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text:
                  'Era la lucha más difícil que había tenido, muy lejos de cualquier misión antiterrorista.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text:
                  'Pero mi amor por ella, heredado de su madre, era más grande que mi miseria.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text:
                  'No iba a permitir que mi tragedia se convirtiera en su ancla.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text:
                  'Su futuro es brillante. Kioto, esa universidad que tanto deseaba. Ella es una estudiante excepcional.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text:
                  'Es un orgullo. Es una prueba de que aún existe algo puro en este mundo corrompido que yo patrullaba.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Así que la dejé ir. Actué en contra de mi propio interés.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text:
                  'La mandé al otro lado del planeta para que pudiera florecer lejos de esta sombra que me consume.',
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

          // Update direction and frame offset
          if (velocity.y < -0.1) {
            _currentDirection = 'NORTH';
            _currentFrameOffset = 0; // Utiliza índice 0 para dan_walk_north
          } else if (velocity.y > 0.1) {
            _currentDirection = 'SOUTH';
            _currentFrameOffset = 6; // Fila 3 de caminar_dan
          } else if (velocity.x < -0.1) {
            _currentDirection = 'WEST';
            _currentFrameOffset = 3; // Fila 2
          } else if (velocity.x > 0.1) {
            _currentDirection = 'EAST';
            _currentFrameOffset = 0; // Fila 1
          }

          _animationTimer += 0.016;
          if (_animationTimer >= _frameRate) {
            _animationTimer = 0.0;
            // Solo animar entre 0 y 2 y sumarle el offset respectivo de la fila
            int nextAnimFrame = ((_currentFrame - _currentFrameOffset + 1) % 3);
            if (nextAnimFrame < 0) nextAnimFrame = 0;
            _currentFrame = _currentFrameOffset + nextAnimFrame;
          }
        });
      }
    } else {
      // Idle frame for current direction
      int idleFrame = _currentFrameOffset;
      if (_currentFrame != idleFrame) {
        setState(() {
          _currentFrame = idleFrame;
        });
      }
    }

    // We don't set _canInteract here anymore, we will do it in _checkInteractions instead
  }

  bool _isValidPosition(Vector2 pos, RoomData room) {
    // Aumentamos un poco el padding para evitar que el sprite se salga visualmente
    final padding = _playerSize / 1.8;

    if (pos.x < padding ||
        pos.x > room.roomSize.width - padding ||
        pos.y < padding ||
        pos.y > room.roomSize.height - padding) {
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
      if (pos.y < cornerCut + padding &&
          pos.x > room.roomSize.width - cornerCut - padding) {
        return false;
      }

      // Esquina inferior izquierda
      if (pos.y > room.roomSize.height - cornerCut - padding &&
          pos.x < cornerCut + padding) {
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

        // Verificar si hay una puerta FUNCIONAL en esta sección para permitir el paso
        bool isNearDoor = false;
        for (final door in room.doors) {
          // Ignorar puertas decorativas (sin destino)
          if (door.targetRoomId.isEmpty) continue;
          // Si la puerta está en la pared norte (o cerca de la pared central)
          if (door.position.dy < towerHeight + 50) {
            // Si estamos alineados horizontalmente con la puerta
            if ((pos.x - (door.position.dx + door.size.x / 2)).abs() <
                door.size.x / 2) {
              isNearDoor = true;
              break;
            }
          }
        }

        // Si hay puerta, permitimos subir más (el límite es la puerta misma, no la pared)
        if (isNearDoor) {
          wallLimitY =
              towerHeight - 20; // Permitir entrar al pasillo de la puerta
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
          if (door.position.dy < 50 &&
              door.position.dx > room.roomSize.width - towerWidth) {
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

        // Lógica específica para el SOFÁ
        if (interactable.id == 'sofa') {
          // Crear una hitbox MUY ajustada al centro visual del sofá
          final sofaHitbox = Rect.fromLTWH(
            interactable.position.dx + 50, // +50 margen izq
            interactable.position.dy +
                90, // +90 margen sup (casi todo el respaldo libre)
            interactable.size.x - 100, // -100 ancho total
            interactable.size.y -
                130, // -130 alto total (muy delgado, solo el asiento)
          );

          if (sofaHitbox.overlaps(playerRect)) {
            return false;
          }
        } else if (interactable.id == 'emma_desk') {
          // Hitbox ajustada para el escritorio (menos permisiva que muebles genéricos)
          final deskHitbox = furnitureRect.deflate(10.0);
          if (deskHitbox.overlaps(playerRect)) {
            return false;
          }
        } else if (interactable.id == 'emma_bed') {
          // Hitbox ajustada para la cama
          final bedHitbox = furnitureRect.deflate(10.0);
          if (bedHitbox.overlaps(playerRect)) {
            return false;
          }
        } else if (interactable.id == 'furniture_1') {
          // Mueble 1 (grande): Deflate mayor para no bloquear (compensando aumento de tamaño)
          final itemHitbox = furnitureRect.deflate(30.0);
          if (itemHitbox.overlaps(playerRect)) {
            return false;
          }
        } else if (interactable.id == 'furniture_2') {
          // Mueble 2 (delgado): Deflate ajustado
          final itemHitbox = furnitureRect.deflate(15.0);
          if (itemHitbox.overlaps(playerRect)) {
            return false;
          }
        } else if (interactable.id == 'furniture_3') {
          // Mueble 3 (pequeño): Deflate menor para no perder colisión
          final itemHitbox = furnitureRect.deflate(5.0);
          if (itemHitbox.overlaps(playerRect)) {
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

  Future<void> _transitionToRoom(
    String targetRoomId, {
    Vector2? spawnPosition,
  }) async {
    if (_isTransitioning || _transitionCooldown > 0) return;

    setState(() {
      _isTransitioning = true;
    });

    await _transitionController.forward();

    setState(() {
      _roomManager.changeRoom(targetRoomId);
      _playerPosition =
          spawnPosition ?? _roomManager.currentRoom.playerSpawnPosition;
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
      // Ignorar puertas decorativas (sin destino definido)
      if (door.targetRoomId.isEmpty) continue;
      if (door.isPlayerInRange(_playerPosition, _playerSize)) {
        _transitionToRoom(
          door.targetRoomId,
          spawnPosition: door.targetSpawnPosition,
        );
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
                  debugPrint(
                    'Phone call completed, transitioning to combat...',
                  );
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
          colors: [Colors.grey[800]!, Colors.grey[400]!, Colors.grey[800]!],
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
            border: const Border(
              top: BorderSide(color: Colors.black, width: 2),
            ),
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
            border: const Border(
              right: BorderSide(color: Colors.black, width: 2),
            ),
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
            border: const Border(
              left: BorderSide(color: Colors.black, width: 2),
            ),
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
    final hallwayHeight =
        room.roomSize.height * 0.25; // Coincidir con RoomShapeClipper
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
                border: Border(
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
                border: const Border(
                  right: BorderSide(color: Colors.black, width: 2),
                ),
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
                border: Border(
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
                border: const Border(
                  top: BorderSide(color: Colors.black, width: 2),
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
                border: const Border(
                  right: BorderSide(color: Colors.black, width: 2),
                ),
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
                border: const Border(
                  top: BorderSide(color: Colors.black, width: 2),
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
                border: const Border(
                  right: BorderSide(color: Colors.black, width: 2),
                ),
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
                border: Border(
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
                border: const Border(
                  top: BorderSide(color: Colors.black, width: 2),
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
                border: const Border(
                  right: BorderSide(color: Colors.black, width: 2),
                ),
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
                border: Border(
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
                border: const Border(
                  right: BorderSide(color: Colors.black, width: 2),
                ),
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
                border: const Border(
                  right: BorderSide(color: Colors.black, width: 2),
                ), // Borde derecho porque es pared externa del cuarto
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
                border: Border(
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
                border: const Border(
                  top: BorderSide(color: Colors.black, width: 2),
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
                border: Border(
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
                border: Border(
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
                border: const Border(
                  right: BorderSide(color: Colors.black, width: 2),
                ),
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
                border: const Border(
                  top: BorderSide(color: Colors.black, width: 2),
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
                border: const Border(
                  right: BorderSide(color: Colors.black, width: 2),
                ),
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
                border: Border(
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

  void _checkInteractions() {
    final room = _roomManager.currentRoom;
    bool canInteractNow = false;

    // Check doors
    for (final door in room.doors) {
      // Ignorar puertas decorativas (sin destino definido)
      if (door.targetRoomId.isEmpty) continue;
      if (door.isPlayerInRange(_playerPosition, _playerSize)) {
        canInteractNow = true;
        break;
      }
    }

    // Check objects if not near a door
    if (!canInteractNow) {
      for (final interactable in room.interactables) {
        if (interactable.isInRange(_playerPosition, 80.0)) {
          if (!interactable.isOneTime || !interactable.hasBeenInteracted) {
            canInteractNow = true;
            break;
          }
        }
      }
    }

    if (_canInteract != canInteractNow) {
      setState(() {
        _canInteract = canInteractNow;
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
              if (event.logicalKey == LogicalKeyboardKey.escape &&
                  _isDialogueActive) {
                debugPrint('ESC pressed - skipping dialogue');
                DialogueOverlay.skipCurrent();
                return;
              }

              if (event.logicalKey == LogicalKeyboardKey.keyE &&
                  !_isDialogueActive) {
                _tryInteract();
                return;
              }

              _pressedKeys.add(event.logicalKey);
            } else if (event is KeyUpEvent) {
              _pressedKeys.remove(event.logicalKey);
            }
          },
          child: RepaintBoundary(
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
                                  image: AssetImage(
                                    'assets/images/wood_floor.jpg',
                                  ),
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
                            final dist = _playerPosition.distanceTo(
                              Vector2(
                                door.position.dx + door.size.x / 2,
                                door.position.dy + door.size.y / 2,
                              ),
                            );
                            final isOpen = dist < 80.0;

                            // LÓGICA ESPECIAL PARA SALA DE ESTAR
                            final isLivingRoom = room.id == 'living_room';
                            final isHorizontal = door.size.x > door.size.y;

                            if (isHorizontal && _doorSprite != null) {
                              final visualWidth = door.size.x * 1.2;
                              // Altura ajustada para que la puerta quepa sin salirse del mapa
                              final visualHeight = door.size.y * 4.5;

                              final isNorth =
                                  door.position.dy < room.roomSize.height / 2;
                              final isSouth =
                                  door.position.dy > room.roomSize.height / 2;

                              double topPos;

                              if (isNorth) {
                                // Lógica específica para sala en U
                                if (isLivingRoom && door.position.dy > 50) {
                                  // Puerta central (Hallway) - La pared está más abajo (y=120)
                                  topPos =
                                      120.0 + 60.0 - visualHeight + door.size.y;
                                } else if (door.position.dy < 100) {
                                  // Puertas norte estándar
                                  topPos = 60.0 - visualHeight + door.size.y;
                                } else {
                                  topPos =
                                      door.position.dy -
                                      visualHeight +
                                      door.size.y;
                                }
                              } else if (isSouth) {
                                // Puerta en pared sur (abajo)
                                topPos =
                                    room.roomSize.height - visualHeight + 5;
                              } else {
                                // Puertas en paredes internas
                                topPos =
                                    door.position.dy -
                                    visualHeight +
                                    door.size.y;

                                if (room.shape == RoomShape.cutCorners &&
                                    door.position.dy > 100 &&
                                    door.position.dy <
                                        room.roomSize.height / 2) {
                                  topPos -= 10.0;
                                }
                              }

                              return Positioned(
                                left:
                                    door.position.x -
                                    (visualWidth - door.size.x) /
                                        2, // Centrar horizontalmente
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
                                // Para puertas verticales, intercambiamos dimensiones porque rotaremos 90Â°
                                final spriteWidth =
                                    door.size.y *
                                    4.5; // Aumentado para que la puerta sea alta
                                final spriteHeight =
                                    door.size.x *
                                    1.2; // El ancho del sprite (después de rotar)

                                final isWest =
                                    door.position.dx < room.roomSize.width / 2;
                                final isEast =
                                    door.position.dx > room.roomSize.width / 2;

                                double leftPos;

                                if (isWest && door.position.dx < 100) {
                                  // Puerta en pared oeste (izquierda) - pegada a la pared
                                  leftPos = 20.0 - spriteHeight + door.size.x;
                                } else if (isEast) {
                                  // Puerta en pared este (derecha) - PEGADA A LA PARED
                                  leftPos =
                                      room.roomSize.width -
                                      20.0 -
                                      spriteHeight +
                                      door.size.x;
                                } else {
                                  // Puertas internas
                                  leftPos =
                                      door.position.x -
                                      (spriteHeight - door.size.x) / 2;
                                }

                                return Positioned(
                                  left: leftPos,
                                  top:
                                      door.position.y -
                                      (spriteWidth - door.size.y) /
                                          2, // Centrar verticalmente
                                  child: SizedBox(
                                    width:
                                        spriteHeight, // Ancho del contenedor (antes de rotar)
                                    height:
                                        spriteWidth, // Alto del contenedor (antes de rotar)
                                    child: Transform.rotate(
                                      angle:
                                          1.5708, // 90 grados en radianes (Ãâ‚¬/2)
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
                                      color: isOpen
                                          ? Colors.black
                                          : Colors.brown[800],
                                      border: Border.all(
                                        color: Colors.brown[900]!,
                                        width: 2,
                                      ),
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
                                    Future.delayed(
                                      const Duration(seconds: 2),
                                      () {
                                        _transitionToCombat();
                                      },
                                    );
                                  }
                                });
                              },
                            );
                          }),

                          Positioned(
                            left: _playerPosition.x - _playerSize / 2,
                            top: _playerPosition.y - _playerSize / 2,
                            child: Builder(
                              builder: (context) {
                                // Seleccionar sprite
                                AnimatedSprite? spriteToUse =
                                    _currentDirection == 'NORTH'
                                    ? _danSpriteNorth
                                    : _danSprite;

                                if (spriteToUse != null) {
                                  return AnimatedSpriteWidget(
                                    sprite: spriteToUse,
                                    direction: _currentDirection,
                                    frameIndex: _currentFrame,
                                    size: _playerSize,
                                  );
                                } else {
                                  return SizedBox(
                                    width: _playerSize,
                                    height: _playerSize,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // EFECTO LINTERNA - Sobre el juego, bajo la UI
                LayoutBuilder(
                  builder: (context, constraints) {
                    final room = _roomManager.currentRoom;
                    final screenW = constraints.maxWidth;
                    final screenH = constraints.maxHeight;
                    final worldW = room.roomSize.width;
                    final worldH = room.roomSize.height;

                    // Replicar el cálculo de BoxFit.contain
                    final scaleX = screenW / worldW;
                    final scaleY = screenH / worldH;
                    final scale = scaleX < scaleY ? scaleX : scaleY;

                    // Offset de centrado (igual que Center + FittedBox)
                    final offsetX = (screenW - worldW * scale) / 2;
                    final offsetY = (screenH - worldH * scale) / 2;

                    final screenCenter = Offset(
                      _playerPosition.x * scale + offsetX,
                      _playerPosition.y * scale + offsetY,
                    );

                    // Radios adaptativos globales
                    final renderedW = worldW * scale;
                    final innerR = FlashlightOverlay.globalInnerRadius(
                      renderedW,
                    );
                    final outerR = FlashlightOverlay.globalOuterRadius(
                      renderedW,
                    );

                    return FlashlightOverlay(
                      center: screenCenter,
                      innerRadius: innerR,
                      outerRadius: outerR,
                      shadowOpacity: 0.97,
                    );
                  },
                ),

                // CAPA DE INPUT (JOYSTICK) - Detrás de la UI
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
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
                    child: Container(color: Colors.transparent),
                  ),
                ),

                if (_isTransitioning)
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Container(
                        color: Colors.black.withValues(
                          alpha: _fadeAnimation.value,
                        ),
                      );
                    },
                  ),

                // HUD Dinámico y Ocultable (Top Left)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: 16,
                  left: _isHudVisible ? 16 : -250,
                  child: GestureDetector(
                    onTap: () {
                      if (_isHudVisible) {
                        setState(() {
                          _isHudVisible = false;
                        });
                        _hudTimer?.cancel();
                      } else {
                        _resetHudTimer();
                      }
                    },
                    child: Builder(
                      builder: (context) {
                        final maxW = MediaQuery.of(context).size.width;
                        final hudW = (maxW * 0.65).clamp(180.0, 260.0);
                        return Container(
                          width: hudW,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.85),
                                Colors.black.withValues(alpha: 0.4),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            border: Border(
                              left: BorderSide(
                                color: Colors.amber.withValues(alpha: 0.5),
                                width: 3,
                              ),
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.bookmark,
                                    color: Colors.amber,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'CAPÍTULO 1: EL LLAMADO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                room.name,
                                style: TextStyle(
                                  color: Colors.amber[200],
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.gps_fixed,
                                    color: Colors.yellow[700],
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _phoneCallCompleted
                                          ? 'Objetivo: Ir a Japón'
                                          : 'Objetivo: Explorar la casa',
                                      style: TextStyle(
                                        color: Colors.yellow[700],
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Pestaña para reabrir el HUD cuando está oculto
                if (!_isHudVisible && !_isDialogueActive)
                  Positioned(
                    top: 24,
                    left: 0,
                    child: GestureDetector(
                      onTap: _resetHudTimer,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.menu_open,
                            color: Colors.amber[300],
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Hint de teclado SOLO en escritorio nativo (no web, no móvil)
                if (!kIsWeb &&
                    defaultTargetPlatform != TargetPlatform.android &&
                    defaultTargetPlatform != TargetPlatform.iOS)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
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

                if (_isJoystickActive &&
                    _joystickOrigin != null &&
                    _joystickPosition != null) ...[
                  Positioned(
                    left: _joystickOrigin!.dx - _joystickRadius,
                    top: _joystickOrigin!.dy - _joystickRadius,
                    child: Container(
                      width: _joystickRadius * 2,
                      height: _joystickRadius * 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 2,
                        ),
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
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
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
                    child: GestureDetector(
                      onTap: _tryInteract,
                      child: _InteractButton(),
                    ),
                  ),

                // BOTÓN DE CONFIGURACIÓN (Top Right)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 16,
                  child: SettingsOverlay(
                    isOpen: _isConfigOpen,
                    onToggle: () {
                      setState(() {
                        _isConfigOpen = !_isConfigOpen;
                        _isPaused = _isConfigOpen;
                      });
                    },
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

// ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬
// Botón de interacción — estilo horror ámbar oscuro
// ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬ââ€â‚¬
class _InteractButton extends StatefulWidget {
  const _InteractButton();

  @override
  State<_InteractButton> createState() => _InteractButtonState();
}

class _InteractButtonState extends State<_InteractButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.55,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1A0800).withValues(alpha: _pulseAnim.value),
          border: Border.all(
            color: const Color(0xFFD4A96A).withValues(alpha: _pulseAnim.value),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFFD4A96A,
              ).withValues(alpha: _pulseAnim.value * 0.35),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'E',
            style: TextStyle(
              color: const Color(
                0xFFD4A96A,
              ).withValues(alpha: _pulseAnim.value + 0.1),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
