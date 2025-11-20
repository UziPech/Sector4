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
import '../components/tiled_wall.dart'; // Import shared TiledWall
import '../../components/destructible_object.dart';
import 'dart:math' as math;

class BunkerBossLevel extends Component with HasGameReference<ExpedienteKorinGame> {
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 1. Crear paredes del búnker (Layout Completo)
    _createBunkerLayout();
    
    // 2.Spawnear al Jugador (Centro de Comando)
    // Command Room center is roughly (0, -600) relative to Hallway (0,0)
    game.player.position = Vector2(350, 100); 
    
    // 3. Spawnear al Stalker (VESTÍBULO - Salida)
    // El Stalker bloquea la salida, añadiendo tensión
    final stalker = StalkerEnemy();
    stalker.position = Vector2(350, 1750); // Vestíbulo (salida del bunker)
    stalker.playerToTrack = game.player;
    game.world.add(stalker);
    
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
          linkedEnemy: stalker,
          position: objectPositions[i],
        );
        game.world.add(object);
        stalker.obsessionObjectId = object.id;
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
    
    // 6. Pantalla Negra de Transición
    final blackScreen = BlackScreenOverlay();
    game.camera.viewport.add(blackScreen);
    
    // Guardar referencia para el tutorial
    _blackScreen = blackScreen;
  }

  late BlackScreenOverlay _blackScreen;

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
    _addFloor(Vector2(0, 0), Vector2(700, 500), const Color(0xFF3A3A5A));
    _addLabel(Vector2(350, 250), "CENTRO DE COMANDO");

    // --- HALLWAY (Center) ---
    // Bounds: Rect(0, 500, 700, 500)
    _addRoomWalls(Vector2(0, 500), Vector2(700, 500), doors: [DoorPos.top, DoorPos.left, DoorPos.right, DoorPos.bottom]);
    _addFloor(Vector2(0, 500), Vector2(700, 500), const Color(0xFF3A3A4A));
    _addLabel(Vector2(350, 750), "PASILLO PRINCIPAL");

    // --- ARMORY (Left) ---
    // Bounds: Rect(-700, 500, 700, 500)
    _addRoomWalls(Vector2(-700, 500), Vector2(700, 500), doors: [DoorPos.right, DoorPos.top]);
    _addFloor(Vector2(-700, 500), Vector2(700, 500), const Color(0xFF4A4A3A));
    _addLabel(Vector2(-350, 750), "ARMERÍA");

    // --- LIBRARY (Left-Top of Hallway) ---
    // Bounds: Rect(-700, 0, 700, 500)
    _addRoomWalls(Vector2(-700, 0), Vector2(700, 500), doors: [DoorPos.bottom]);
    _addFloor(Vector2(-700, 0), Vector2(700, 500), const Color(0xFF3A3A4A));
    _addLabel(Vector2(-350, 250), "ARCHIVO / BIBLIOTECA");

    // --- LAB (Right) ---
    // Bounds: Rect(700, 500, 700, 500)
    _addRoomWalls(Vector2(700, 500), Vector2(700, 500), doors: [DoorPos.left, DoorPos.right]);
    _addFloor(Vector2(700, 500), Vector2(700, 500), const Color(0xFF2A4A5A));
    _addLabel(Vector2(1050, 750), "LABORATORIO");
    
    // --- CAFETERIA (Right of Lab) ---
    // Bounds: Rect(1400, 500, 700, 500)
    _addRoomWalls(Vector2(1400, 500), Vector2(700, 500), doors: [DoorPos.left]);
    _addFloor(Vector2(1400, 500), Vector2(700, 500), const Color(0xFF4A4A3A));
    _addLabel(Vector2(1750, 750), "COMEDOR");
    
    // --- DORMS (Bottom) ---
    // Bounds: Rect(0, 1000, 700, 500)
    _addRoomWalls(Vector2(0, 1000), Vector2(700, 500), doors: [DoorPos.top, DoorPos.bottom]);
    _addFloor(Vector2(0, 1000), Vector2(700, 500), const Color(0xFF3A3A4A));
    _addLabel(Vector2(350, 1250), "DORMITORIOS");
    
    // --- VESTIBULE (Bottom of Dorms) ---
    // Bounds: Rect(0, 1500, 700, 500)
    _addRoomWalls(Vector2(0, 1500), Vector2(700, 500), doors: [DoorPos.top]);
    _addFloor(Vector2(0, 1500), Vector2(700, 500), const Color(0xFF3A3A4A));
    _addLabel(Vector2(350, 1750), "VESTÍBULO (SALIDA)");
  }
  
  void _addRoomWalls(Vector2 pos, Vector2 size, {required List<DoorPos> doors}) {
    const double thickness = 40.0; // Thicker walls
    const double doorSize = 150.0;
    
    // Top Wall
    if (doors.contains(DoorPos.top)) {
      game.world.add(Wall(pos, Vector2((size.x - doorSize)/2, thickness))); // Left part
      game.world.add(Wall(pos + Vector2((size.x + doorSize)/2, 0), Vector2((size.x - doorSize)/2, thickness))); // Right part
    } else {
      game.world.add(Wall(pos, Vector2(size.x, thickness)));
    }
    
    // Bottom Wall
    if (doors.contains(DoorPos.bottom)) {
      game.world.add(Wall(pos + Vector2(0, size.y - thickness), Vector2((size.x - doorSize)/2, thickness)));
      game.world.add(Wall(pos + Vector2((size.x + doorSize)/2, size.y - thickness), Vector2((size.x - doorSize)/2, thickness)));
    } else {
      game.world.add(Wall(pos + Vector2(0, size.y - thickness), Vector2(size.x, thickness)));
    }
    
    // Left Wall
    if (doors.contains(DoorPos.left)) {
      game.world.add(Wall(pos, Vector2(thickness, (size.y - doorSize)/2)));
      game.world.add(Wall(pos + Vector2(0, (size.y + doorSize)/2), Vector2(thickness, (size.y - doorSize)/2)));
    } else {
      game.world.add(Wall(pos, Vector2(thickness, size.y)));
    }
    
    // Right Wall
    if (doors.contains(DoorPos.right)) {
      game.world.add(Wall(pos + Vector2(size.x - thickness, 0), Vector2(thickness, (size.y - doorSize)/2)));
      game.world.add(Wall(pos + Vector2(size.x - thickness, (size.y + doorSize)/2), Vector2(thickness, (size.y - doorSize)/2)));
    } else {
      game.world.add(Wall(pos + Vector2(size.x - thickness, 0), Vector2(thickness, size.y)));
    }
  }
  
  void _addFloor(Vector2 pos, Vector2 size, Color color) {
    game.world.add(Floor(pos, size, color));
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
}

enum DoorPos { top, bottom, left, right }



class Wall extends TiledWall { // Inherit from TiledWall for player collision
  Wall(Vector2 pos, Vector2 sz) {
    position = pos;
    size = sz;
    priority = -50;
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }
  
  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = Colors.grey);
  }
}


class Floor extends PositionComponent {
  final Color color;
  Floor(Vector2 position, Vector2 size, this.color) : super(position: position, size: size, priority: -100);
  
  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = color);
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
