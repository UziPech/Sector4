import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../expediente_game.dart';
import '../../components/stalker_enemy.dart';
import '../../components/obsession_object.dart';
import '../components/player.dart';
import '../../narrative/components/dialogue_system.dart';
import '../../narrative/models/dialogue_data.dart';
import '../../narrative/screens/role_selection_screen.dart';
import '../components/tiled_wall.dart'; // Import shared TiledWall
import '../../components/destructible_object.dart';
import 'dart:math' as math;

class BunkerBossLevel extends Component with HasGameReference<ExpedienteKorinGame> {
  StalkerEnemy? _stalker;
  bool _bossDefeated = false;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 1. Crear paredes del búnker (Layout Completo)
    _createBunkerLayout();
    
    // 2.Spawnear al Jugador (Centro de Comando)
    // Command Room center is roughly (0, -600) relative to Hallway (0,0)
    // Adjusted to (350, 250) to be safely inside the room with 100px thick walls
    game.player.position = Vector2(350, 250); 
    
    // 3. Spawnear al Stalker (VESTÍBULO - Salida)
    // El Stalker bloquea la salida, añadiendo tensión
    _stalker = StalkerEnemy();
    _stalker!.position = Vector2(350, 1750); // Vestíbulo (salida del bunker)
    _stalker!.playerToTrack = game.player;
    game.world.add(_stalker!);
    
    // 4. Spawnear el Objeto Obsesivo REAL + DECOYS
    // Definir posiciones para los objetos (7 en total)
    // Basadas en el layout real del bunker
    final objectPositions = [
      // LABORATORIO (700-1400, 500-1000)
      Vector2(950, 700),   // Lab - esquina izquierda
      Vector2(1250, 850),  // Lab - centro-derecha
      
      // CAFETERIA (1400-2100, 500-1000)
      Vector2(1600, 700),  // Cafetería - izquierda
      Vector2(1900, 850),  // Cafetería - centro
      
      // DORMITORIOS (0-700, 1000-1500)
      Vector2(350, 1250),  // Dormitorios - centro
      
      // ARMERIA (-700-0, 500-1000)
      Vector2(-350, 750),  // Armería - centro
      
      // BIBLIOTECA (-700-0, 0-500)
      Vector2(-350, 250),  // Biblioteca - centro
    ];
    
    // Randomizar cuál es el real
    final random = math.Random();
    final realObjectIndex = random.nextInt(objectPositions.length);
    
    // Crear objetos
    for (int i = 0; i < objectPositions.length; i++) {
      if (i == realObjectIndex) {
        // Este es el REAL
        final object = ObsessionObject(
          id: 'stalker_obj',
          linkedEnemy: _stalker!,
          position: objectPositions[i],
        );
        game.world.add(object);
        _stalker!.obsessionObjectId = object.id;
      } else {
        // Este es un DECOY
        final decoy = DestructibleObject(
          position: objectPositions[i],
        );
        game.world.add(decoy);
      }
    }
    
    // 5. Efecto de Alerta Roja
    game.camera.viewport.add(RedAlertOverlay());
    
    // 5.5. Mensaje de advertencia de zona peligrosa
    game.notificationSystem.show(
      '⚠️ ZONA PELIGROSA ⚠️',
      'ENTIDAD HOSTIL DETECTADA - NIVEL DE AMENAZA: CRÍTICO',
    );
    
    // 6. Pantalla Negra de Transición
    final blackScreen = BlackScreenOverlay();
    game.camera.viewport.add(blackScreen);
    
    // Guardar referencia para el tutorial
    _blackScreen = blackScreen;
  }

  late BlackScreenOverlay _blackScreen;

  @override
  void update(double dt) {
    super.update(dt);
    
    // Verificar si el Stalker fue derrotado
    if (!_bossDefeated && _stalker != null && _stalker!.health <= 0) {
      _bossDefeated = true;
      _onBossDefeated();
    }
  }

  @override
  void onMount() {
    super.onMount();
    // Mostrar tutorial al iniciar
    // Usamos un pequeño delay para asegurar que el contexto esté listo
    Future.delayed(const Duration(milliseconds: 500), () {
      _showTutorial();
    });
  }

  void _showTutorial() {
    if (game.buildContext == null) return;

    game.pauseEngine();

    final tutorialSequence = DialogueSequence(
      id: 'boss_tutorial',
      dialogues: [
        const DialogueData(
          speakerName: 'Sistema',
          text: 'ALERTA: Entidad Hostil "The Stalker" detectada. Nivel de amenaza: CRÍTICO.',
          type: DialogueType.system,
        ),
        const DialogueData(
          speakerName: 'Dan',
          text: 'Maldición, es rápido. Y mis armas no le hacen nada.',
          avatarPath: 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
        ),
        const DialogueData(
          speakerName: 'Mel',
          text: 'Escucha, Dan. Es un Resonante. Es invulnerable mientras su "Objeto Obsesivo" exista.',
          avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
        ),
        const DialogueData(
          speakerName: 'Mel',
          text: 'He detectado una firma de energía en el LABORATORIO (Derecha). Encuentra el objeto y destrúyelo.',
          avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
        ),
        const DialogueData(
          speakerName: 'Sistema',
          text: 'TUTORIAL DE COMBATE:\n1. HUD Inferior: Muestra tus armas y munición.\n2. Presiona "Q" para cambiar entre Cuchillo y Pistola.',
          type: DialogueType.system,
        ),
        const DialogueData(
          speakerName: 'Sistema',
          text: '3. Mel (Barra Azul) te curará automáticamente si sufres daño crítico.\n4. ¡Sobrevive y destruye el objeto!',
          type: DialogueType.system,
        ),
      ],
      onComplete: () {
        _blackScreen.fadeOut(); // Desvanecer pantalla negra al terminar diálogos
        game.resumeEngine();
      },
    );

    DialogueOverlay.show(game.buildContext!, tutorialSequence, onComplete: () {
      _blackScreen.fadeOut();
      game.resumeEngine();
    });
  }
  
  void _createBunkerLayout() {
    // Definimos las habitaciones conectadas espacialmente.
    // Usaremos coordenadas absolutas.
    
    // --- COMMAND ROOM (Top) ---
    // Bounds: Rect(0, 0, 700, 500)
    _addRoomWalls(Vector2(0, 0), Vector2(700, 500), doors: [DoorPos.bottom]);
    _addFloor(Vector2(0, 0), Vector2(700, 500), const Color(0xFF3A3A5A), textureFile: 'metal_floor_clean.png');
    _addLabel(Vector2(350, 250), "CENTRO DE COMANDO");

    // --- HALLWAY (Center) ---
    // Bounds: Rect(0, 500, 700, 500)
    _addRoomWalls(Vector2(0, 500), Vector2(700, 500), doors: [DoorPos.top, DoorPos.left, DoorPos.right, DoorPos.bottom]);
    _addFloor(Vector2(0, 500), Vector2(700, 500), const Color(0xFF3A3A4A), textureFile: 'metal_floor_dark.png');
    _addLabel(Vector2(350, 750), "PASILLO PRINCIPAL");

    // --- ARMORY (Left) ---
    // Bounds: Rect(-700, 500, 700, 500)
    _addRoomWalls(Vector2(-700, 500), Vector2(700, 500), doors: [DoorPos.right, DoorPos.top]);
    _addFloor(Vector2(-700, 500), Vector2(700, 500), const Color(0xFF4A4A3A), textureFile: 'metal_floor_dark.png');
    _addLabel(Vector2(-350, 750), "ARMERÍA");

    // --- LIBRARY (Left-Top of Hallway) ---
    // Bounds: Rect(-700, 0, 700, 500)
    _addRoomWalls(Vector2(-700, 0), Vector2(700, 500), doors: [DoorPos.bottom]);
    _addFloor(Vector2(-700, 0), Vector2(700, 500), const Color(0xFF3A3A4A));
    _addLabel(Vector2(-350, 250), "ARCHIVO / BIBLIOTECA");

    // --- LAB (Right) ---
    // Bounds: Rect(700, 500, 700, 500)
    _addRoomWalls(Vector2(700, 500), Vector2(700, 500), doors: [DoorPos.left, DoorPos.right]);
    _addFloor(Vector2(700, 500), Vector2(700, 500), const Color(0xFF2A4A5A), textureFile: 'metal_floor_clean.png');
    _addLabel(Vector2(1050, 750), "LABORATORIO");
    
    // --- CAFETERIA (Right of Lab) ---
    // Bounds: Rect(1400, 500, 700, 500)
    _addRoomWalls(Vector2(1400, 500), Vector2(700, 500), doors: [DoorPos.left]);
    _addFloor(Vector2(1400, 500), Vector2(700, 500), const Color(0xFF4A4A3A), textureFile: 'metal_floor_dark.png');
    _addLabel(Vector2(1750, 750), "COMEDOR");
    
    // --- DORMS (Bottom) ---
    // Bounds: Rect(0, 1000, 700, 500)
    _addRoomWalls(Vector2(0, 1000), Vector2(700, 500), doors: [DoorPos.top, DoorPos.bottom]);
    _addFloor(Vector2(0, 1000), Vector2(700, 500), const Color(0xFF3A3A4A), textureFile: 'metal_floor_quarters.png');
    _addLabel(Vector2(350, 1250), "DORMITORIOS");
    
    // --- VESTIBULE (Bottom of Dorms) ---
    // Bounds: Rect(0, 1500, 700, 500)
    _addRoomWalls(Vector2(0, 1500), Vector2(700, 500), doors: [DoorPos.top]);
    _addFloor(Vector2(0, 1500), Vector2(700, 500), const Color(0xFF3A3A4A), textureFile: 'metal_floor_dark.png');
    _addLabel(Vector2(350, 1750), "VESTÍBULO (SALIDA)");
  }
  
  void _addRoomWalls(Vector2 pos, Vector2 size, {required List<DoorPos> doors}) {
    const double thickness = 100.0; // Increased to match visual asset size
    const double doorSize = 150.0;
    
    // Top Wall
    if (doors.contains(DoorPos.top)) {
      game.world.add(Wall(pos, Vector2((size.x - doorSize)/2, thickness), side: WallSide.top)); // Left part
      game.world.add(Wall(pos + Vector2((size.x + doorSize)/2, 0), Vector2((size.x - doorSize)/2, thickness), side: WallSide.top)); // Right part
    } else {
      game.world.add(Wall(pos, Vector2(size.x, thickness), side: WallSide.top));
    }
    
    // Bottom Wall
    if (doors.contains(DoorPos.bottom)) {
      game.world.add(Wall(pos + Vector2(0, size.y - thickness), Vector2((size.x - doorSize)/2, thickness), side: WallSide.bottom));
      game.world.add(Wall(pos + Vector2((size.x + doorSize)/2, size.y - thickness), Vector2((size.x - doorSize)/2, thickness), side: WallSide.bottom));
    } else {
      game.world.add(Wall(pos + Vector2(0, size.y - thickness), Vector2(size.x, thickness), side: WallSide.bottom));
    }
    
    // Left Wall
    if (doors.contains(DoorPos.left)) {
      game.world.add(Wall(pos, Vector2(thickness, (size.y - doorSize)/2), side: WallSide.left));
      game.world.add(Wall(pos + Vector2(0, (size.y + doorSize)/2), Vector2(thickness, (size.y - doorSize)/2), side: WallSide.left));
    } else {
      game.world.add(Wall(pos, Vector2(thickness, size.y), side: WallSide.left));
    }
    
    // Right Wall
    if (doors.contains(DoorPos.right)) {
      game.world.add(Wall(pos + Vector2(size.x - thickness, 0), Vector2(thickness, (size.y - doorSize)/2), side: WallSide.right));
      game.world.add(Wall(pos + Vector2(size.x - thickness, (size.y + doorSize)/2), Vector2(thickness, (size.y - doorSize)/2), side: WallSide.right));
    } else {
      game.world.add(Wall(pos + Vector2(size.x - thickness, 0), Vector2(thickness, size.y), side: WallSide.right));
    }
  }
  
  void _addFloor(Vector2 pos, Vector2 size, Color color, {String? textureFile}) {
    game.world.add(Floor(pos, size, color, textureFile: textureFile));
  }
  
  void _addLabel(Vector2 pos, String text) {
    game.world.add(TextComponent(
      text: text,
      position: pos,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    ));
  }
  
  /// Método llamado cuando el Stalker es derrotado
  void _onBossDefeated() {
    if (game.buildContext == null) return;
    
    // Verificar que realmente destruyó el objeto real
    if (_stalker!.isInvincible) {
      debugPrint('WARNING: Stalker defeated but still invincible! This should not happen.');
      return; // No activar diálogos si aún es invencible
    }
    
    game.pauseEngine();
    
    // Diálogos inmediatos post-derrota (Mel urge a salir)
    final immediateDialogue = DialogueSequence(
      id: 'immediate_post_defeat',
      dialogues: const [
        DialogueData(
          speakerName: 'Sistema',
          text: 'AMENAZA NEUTRALIZADA. Resonante eliminado.',
          type: DialogueType.system,
        ),
        DialogueData(
          speakerName: 'Mel',
          text: '¡Dan! Los sensores detectan más firmas biológicas convergiendo en nuestra posición. ¡Debemos salir del búnker AHORA!',
          avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
          type: DialogueType.normal,
        ),
        DialogueData(
          speakerName: 'Dan',
          text: 'Entendido. Vamos al vestíbulo, la salida está cerca.',
          avatarPath: 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
          type: DialogueType.normal,
        ),
      ],
      onComplete: () {
        game.resumeEngine();
        _activateExitDoor();
      },
    );
    
    DialogueOverlay.show(game.buildContext!, immediateDialogue);
  }
  
  /// Activa la zona de salida del búnker
  void _activateExitDoor() {
    // Crear trigger zone en la puerta de salida
    // Posición: En el centro del vestíbulo, fácil de alcanzar
    final exitTrigger = ExitDoorTrigger(
      position: Vector2(200, 1850), // Más arriba, centrado en el vestíbulo
      onPlayerEnter: _onPlayerExitBunker,
    );
    game.world.add(exitTrigger);
    debugPrint('EXIT DOOR TRIGGER CREATED at position: ${exitTrigger.position}');
  }
  
  /// Llamado cuando el jugador cruza la puerta de salida
  void _onPlayerExitBunker() {
    debugPrint('_onPlayerExitBunker called');
    
    if (game.buildContext == null) {
      debugPrint('ERROR: game.buildContext is null!');
      return;
    }
    
    debugPrint('Adding fade overlay (NOT pausing engine so it can update)');
    
    // NO pausar el engine para que el overlay pueda actualizarse
    // El overlay bloqueará visualmente la pantalla
    
    // Efecto de transición (fade to black + texto)
    final fadeOverlay = ExitTransitionOverlay(
      onComplete: _showRoleSelectionDialogues,
    );
    game.camera.viewport.add(fadeOverlay);
    debugPrint('Fade overlay added successfully');
  }
  
  /// Muestra los diálogos completos de selección de rol
  void _showRoleSelectionDialogues() {
    if (game.buildContext == null) return;
    
    // Diálogos post-resonante completos (del documento ROLE_SELECTION_DIALOGUES.md)
    final postResonanteSequence = DialogueSequence(
      id: 'post_resonante',
      dialogues: const [
        DialogueData(
          speakerName: 'Sistema',
          text: 'UBICACIÓN: Exterior del Búnker. Escaneando perímetro...',
          type: DialogueType.system,
        ),
        DialogueData(
          speakerName: 'Dan',
          text: 'Por supuesto. Nunca es solo uno. La Caída no funciona así. Es como una infección... se propaga.',
          type: DialogueType.internal,
        ),
        DialogueData(
          speakerName: 'Mel',
          text: 'Son irracionales. Mutados de bajo nivel, pero en número. Necesitamos aguantar mientras preparo la ruta de evacuación.',
          avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
          type: DialogueType.normal,
        ),
        DialogueData(
          speakerName: 'Dan',
          text: 'Aguantar. Siempre aguantar. Como si mi vida entera no hubiera sido eso... aguantar hasta que algo se rompa.',
          type: DialogueType.internal,
        ),
        DialogueData(
          speakerName: 'Mel',
          text: 'Dan, escúchame. Podemos hacer esto de dos formas.',
          avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
          type: DialogueType.normal,
        ),
        DialogueData(
          speakerName: 'Mel',
          text: 'Tú puedes liderar con tus armas, tu entrenamiento. O... yo puedo usar esto.',
          avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
          type: DialogueType.normal,
        ),
        DialogueData(
          speakerName: 'Dan',
          text: 'Su brazo. Esa cosa que crece en ella. Parte orgánica, parte... otra cosa. La Caída la marcó, pero no la destruyó.',
          type: DialogueType.internal,
        ),
        DialogueData(
          speakerName: 'Mel',
          text: 'He estado aprendiendo a controlarlo. Puedo absorber energía vital, incluso... traer de vuelta a los caídos. Temporalmente.',
          avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
          type: DialogueType.normal,
        ),
        DialogueData(
          speakerName: 'Dan',
          text: 'Resurrección. Qué ironía. Yo que no pude salvar a nadie, y ella puede devolver la vida. Aunque sea por un momento.',
          type: DialogueType.internal,
        ),
        DialogueData(
          speakerName: 'Mel',
          text: 'La decisión es tuya, Dan. ¿Quién toma el punto?',
          avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
          type: DialogueType.normal,
        ),
      ],
      onComplete: () {
        // Navegar a la pantalla de selección de rol
        Navigator.of(game.buildContext!).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const RoleSelectionScreen(),
          ),
        );
      },
    );
    
    DialogueOverlay.show(game.buildContext!, postResonanteSequence);
  }
}

enum DoorPos { top, bottom, left, right }



enum WallSide { top, bottom, left, right }

class Wall extends TiledWall with HasGameReference<ExpedienteKorinGame> {
  Sprite? _panelSprite;
  final WallSide side;
  
  Wall(Vector2 pos, Vector2 sz, {required this.side}) {
    position = pos;
    size = sz;
    priority = -90;
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()..collisionType = CollisionType.passive);
    
    // Cargar textura según orientación
    final isHorizontal = side == WallSide.top || side == WallSide.bottom;
    final panelFile = isHorizontal ? 'wall_panel_horizontal.png' : 'wall_panel_vertical.png';
    
    try {
      _panelSprite = await game.loadSprite(panelFile);
    } catch (e) {
      debugPrint('Error loading wall panel $panelFile: $e');
    }
  }
  
  @override
  void render(Canvas canvas) {
    if (_panelSprite != null) {
      final image = _panelSprite!.image;
      final imgWidth = image.width.toDouble();
      final imgHeight = image.height.toDouble();
      
      // Definir el recorte (slice) según el lado de la pared
      // Asumimos que el grosor visual de la pared en la textura es igual al grosor físico (100px)
      Rect srcRect;
      
      switch (side) {
        case WallSide.top:
          // Barra superior de la textura horizontal
          srcRect = Rect.fromLTWH(0, 0, imgWidth, size.y); 
          break;
        case WallSide.bottom:
          // Barra inferior de la textura horizontal
          srcRect = Rect.fromLTWH(0, imgHeight - size.y, imgWidth, size.y);
          break;
        case WallSide.left:
          // Barra izquierda de la textura vertical
          srcRect = Rect.fromLTWH(0, 0, size.x, imgHeight);
          break;
        case WallSide.right:
          // Barra derecha de la textura vertical
          srcRect = Rect.fromLTWH(imgWidth - size.x, 0, size.x, imgHeight);
          break;
      }
      
      // Renderizar el recorte repetido a lo largo de la pared
      if (side == WallSide.top || side == WallSide.bottom) {
        // Horizontal: Repetir en X
        for (double x = 0; x < size.x; x += imgWidth) {
          final w = (x + imgWidth > size.x) ? size.x - x : imgWidth;
          
          canvas.drawImageRect(
            image,
            Rect.fromLTWH(srcRect.left, srcRect.top, w, srcRect.height), // Recorte ajustado al ancho restante
            Rect.fromLTWH(x, 0, w, size.y),
            Paint(),
          );
        }
      } else {
        // Vertical: Repetir en Y
        for (double y = 0; y < size.y; y += imgHeight) {
          final h = (y + imgHeight > size.y) ? size.y - y : imgHeight;
          
          canvas.drawImageRect(
            image,
            Rect.fromLTWH(srcRect.left, srcRect.top, srcRect.width, h), // Recorte ajustado al alto restante
            Rect.fromLTWH(0, y, size.x, h),
            Paint(),
          );
        }
      }
    } else {
      canvas.drawRect(size.toRect(), Paint()..color = Colors.grey);
    }
  }
}


class Floor extends PositionComponent with HasGameReference<ExpedienteKorinGame> {
  final Color color;
  final String? textureFile;
  Sprite? _floorSprite;
  
  Floor(Vector2 position, Vector2 size, this.color, {this.textureFile}) 
      : super(position: position, size: size, priority: -100);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    if (textureFile != null) {
      try {
        _floorSprite = await game.loadSprite(textureFile!);
      } catch (e) {
        debugPrint('Error loading floor texture $textureFile: $e');
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    if (textureFile != null && _floorSprite != null) {
      // Renderizar textura escalada para cubrir el área
      _floorSprite!.render(
        canvas,
        size: size,
      );
    } else {
      // Fallback a color sólido
      canvas.drawRect(size.toRect(), Paint()..color = color);
    }
  }
}

class RedAlertOverlay extends Component with HasGameReference<ExpedienteKorinGame> {
  double _timer = 0;
  
  @override
  void render(Canvas canvas) {
    final opacity = (0.1 + 0.1 * (_timer % 1.0)).clamp(0.0, 0.3);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.size.x, game.size.y),
      Paint()..color = Colors.red.withOpacity(opacity),
    );
  }
  
  @override
  void update(double dt) {
    _timer += dt;
  }
}

class BlackScreenOverlay extends Component with HasGameReference<ExpedienteKorinGame> {
  double opacity = 1.0;
  bool _fadingOut = false;
  final double fadeSpeed = 1.0;

  void fadeOut() {
    _fadingOut = true;
  }

  @override
  void update(double dt) {
    if (_fadingOut) {
      opacity -= fadeSpeed * dt;
      if (opacity <= 0) {
        opacity = 0;
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (opacity > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, game.size.x, game.size.y),
        Paint()..color = Colors.black.withOpacity(opacity),
      );
    }
  }
}

/// Trigger zone para detectar cuando el jugador sale del búnker
class ExitDoorTrigger extends PositionComponent with CollisionCallbacks, HasGameReference<ExpedienteKorinGame> {
  final VoidCallback onPlayerEnter;
  bool _triggered = false;
  
  ExitDoorTrigger({
    required Vector2 position,
    required this.onPlayerEnter,
  }) : super(position: position, size: Vector2(300, 150)); // Zona más grande
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Usar passive para detectar colisiones con el jugador (que es active)
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }
  
  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    debugPrint('EXIT TRIGGER: Collision detected with ${other.runtimeType}');
    
    if (!_triggered && other is PlayerCharacter) {
      _triggered = true;
      debugPrint('EXIT TRIGGER ACTIVATED! Calling onPlayerEnter');
      onPlayerEnter();
    }
  }
  
  double _pulseTimer = 0.0;
  
  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt;
  }
  
  @override
  void render(Canvas canvas) {
    // Efecto de pulso
    final pulse = (math.sin(_pulseTimer * 3) * 0.5 + 0.5).clamp(0.0, 1.0);
    
    // Renderizar indicador visual de la salida con pulso
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.2 + pulse * 0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(size.toRect(), paint);
    
    // Borde brillante
    final borderPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.5 + pulse * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawRect(size.toRect(), borderPaint);
    
    // Texto "SALIDA ►" con pulso
    final textPainter = TextPainter(
      text: TextSpan(
        text: '► SALIDA ►',
        style: TextStyle(
          color: Colors.white.withOpacity(0.7 + pulse * 0.3),
          fontSize: 28,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.green.withOpacity(pulse),
              blurRadius: 10,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
    );
  }
}

/// Overlay de transición al salir del búnker
class ExitTransitionOverlay extends Component with HasGameReference<ExpedienteKorinGame> {
  final VoidCallback onComplete;
  double _timer = 0.0;
  double opacity = 0.0;
  final double fadeDuration = 2.0;
  final double textDisplayDuration = 3.0;
  bool _completed = false;
  
  ExitTransitionOverlay({required this.onComplete});
  
  @override
  void onMount() {
    super.onMount();
    debugPrint('ExitTransitionOverlay mounted');
  }
  
  @override
  void update(double dt) {
    _timer += dt;
    
    if (_timer < 0.5) {
      debugPrint('ExitTransitionOverlay updating: timer=$_timer, opacity=$opacity');
    }
    
    // Fade in (0-2s)
    if (_timer < fadeDuration) {
      opacity = (_timer / fadeDuration).clamp(0.0, 1.0);
    }
    // Mantener negro con texto (2-5s)
    else if (_timer < fadeDuration + textDisplayDuration) {
      opacity = 1.0;
    }
    // Completar
    else if (!_completed) {
      _completed = true;
      debugPrint('ExitTransitionOverlay complete, calling onComplete');
      onComplete();
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    // Fondo negro
    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.size.x, game.size.y),
      Paint()..color = Colors.black.withOpacity(opacity),
    );
    
    // Texto "SALIENDO DEL BÚNKER..."
    if (_timer > fadeDuration && _timer < fadeDuration + textDisplayDuration) {
      final textOpacity = (opacity * 0.9).clamp(0.0, 1.0);
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'SALIENDO DEL BÚNKER...',
          style: TextStyle(
            color: Colors.white.withOpacity(textOpacity),
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (game.size.x - textPainter.width) / 2,
          (game.size.y - textPainter.height) / 2,
        ),
      );
    }
  }
}
