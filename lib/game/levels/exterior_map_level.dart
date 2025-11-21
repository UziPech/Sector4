import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../expediente_game.dart';
import '../components/player.dart';
import '../components/enemies/yurei_kohaa.dart';
import '../components/enemies/irracional.dart';
import '../systems/resurrection_system.dart';
import '../systems/enemy_spawner.dart';
import '../models/player_role.dart';
import '../../narrative/components/dialogue_system.dart';
import '../../narrative/models/dialogue_data.dart';

/// Nivel del mapa exterior post-resonante
/// Mapa simple sin Tiled, generado proceduralmente
class ExteriorMapLevel extends Component with HasGameReference<ExpedienteKorinGame> {
  late ResurrectionManager resurrectionManager;
  
  // Control de Kohaa
  bool _kohaaSpawned = false;
  bool _initialEnemiesCleared = false;
  int _initialEnemyCount = 5;
  YureiKohaa? _kohaa;
  
  // Dimensiones del mapa
  static const double mapWidth = 1600.0;
  static const double mapHeight = 1200.0;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Crear sistema de resurrecciones
    resurrectionManager = ResurrectionManager();
    resurrectionManager.configure(game.player.playerRole);
    await game.world.add(resurrectionManager);
    
    // Actualizar HUD con el resurrection manager
    game.hud.resurrectionManager = resurrectionManager;
    
    // Crear fondo del mapa
    await _createBackground();
    
    // Crear paredes/obstáculos
    await _createWalls();
    
    // Posicionar jugador en el centro
    game.player.position = Vector2(mapWidth / 2, mapHeight / 2);
    game.mel.position = game.player.position + Vector2(50, 0);
    
    // Spawn enemigos iniciales (sin spawner continuo)
    await _spawnInitialEnemies();
  }
  
  Future<void> _spawnInitialEnemies() async {
    final random = Random();
    
    for (int i = 0; i < _initialEnemyCount; i++) {
      final x = random.nextDouble() * (mapWidth - 200) + 100;
      final y = random.nextDouble() * (mapHeight - 200) + 100;
      
      final enemy = IrrationalEnemy(
        position: Vector2(x, y),
        health: 50.0,
        speed: 80.0,
        damage: 10.0,
      );
      
      await game.world.add(enemy);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Verificar si se limpiaron los enemigos iniciales
    if (!_initialEnemiesCleared && !_kohaaSpawned) {
      final enemies = game.world.children.query<IrrationalEnemy>();
      int aliveCount = 0;
      for (final enemy in enemies) {
        if (!enemy.isDead) aliveCount++;
      }
      
      if (aliveCount == 0) {
        _initialEnemiesCleared = true;
        // Esperar 1 segundo y mostrar diálogo de Kohaa
        Future.delayed(const Duration(milliseconds: 1000), () {
          _showKohaaIntro();
        });
      }
    }
  }
  
  void _showKohaaIntro() {
    if (game.buildContext == null || _kohaaSpawned) return;
    _kohaaSpawned = true;
    
    game.pauseEngine();
    
    final isDan = game.player.role == PlayerRole.dan;
    
    final introSequence = DialogueSequence(
      id: 'kohaa_intro',
      dialogues: [
        const DialogueData(
          speakerName: 'Sistema',
          text: 'ALERTA: Firma de energía anómala detectada. Categoría: KIJIN.',
          type: DialogueType.system,
        ),
        DialogueData(
          speakerName: isDan ? 'Mel' : 'Dan',
          text: isDan 
              ? 'Dan... esta presencia es diferente. No es un irracional.'
              : 'Mel, ¿sientes eso? Es diferente a los otros.',
          avatarPath: isDan
              ? 'assets/avatars/dialogue_icons/Mel_Dialogue.png'
              : 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
        ),
        DialogueData(
          speakerName: isDan ? 'Dan' : 'Mel',
          text: isDan
              ? '¿Qué es? Se siente... triste. Como si el aire mismo estuviera llorando.'
              : 'Es un Kijin. Nacido de muerte violenta y emoción intensa. Ten cuidado.',
          avatarPath: isDan
              ? 'assets/avatars/dialogue_icons/Dan_Dialogue.png'
              : 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
        ),
        if (isDan) const DialogueData(
          speakerName: 'Mel',
          text: 'Los Kijin son nacidos de muertes violentas cargadas de emoción. Odio, amor traicionado, venganza...',
          avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
        ),
        const DialogueData(
          speakerName: '???',
          text: 'Él... me prometió eternidad. Pero me dio... esto.',
          avatarPath: 'assets/avatars/dialogue_icons/kohaa_avatar.png',
        ),
        const DialogueData(
          speakerName: 'Yurei Kohaa',
          text: 'Una novia que no puede morir. Un amor que se pudrió en mis venas. ¿Vienes a liberarme?',
          avatarPath: 'assets/avatars/dialogue_icons/kohaa_avatar.png',
        ),
        DialogueData(
          speakerName: isDan ? 'Dan' : 'Mel',
          text: isDan
              ? 'No quiero pelear contigo. Pero si no me dejas opción...'
              : 'No busco pelea. Pero no puedo permitir que lastimes a otros.',
          avatarPath: isDan
              ? 'assets/avatars/dialogue_icons/Dan_Dialogue.png'
              : 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
        ),
        const DialogueData(
          speakerName: 'Kohaa',
          text: '*Una risa amarga resuena* Todos dicen eso. Y todos mienten.',
          avatarPath: 'assets/avatars/dialogue_icons/kohaa_avatar.png',
        ),
      ],
      onComplete: () {
        game.resumeEngine();
        _spawnKohaa();
      },
    );
    
    DialogueOverlay.show(game.buildContext!, introSequence);
  }
  
  void _spawnKohaa() {
    // Spawn Kohaa en la parte superior del mapa
    _kohaa = YureiKohaa(position: Vector2(mapWidth / 2, 200));
    game.world.add(_kohaa!);
    debugPrint('✨ Yurei Kohaa ha aparecido!');
  }
  
  Future<void> _setupEnemySpawner() async {
    final spawner = EnemySpawner(
      spawnInterval: 5.0, // Spawn cada 5 segundos
      maxEnemies: 15, // Máximo 15 enemigos
      mapWidth: mapWidth,
      mapHeight: mapHeight,
    );
    
    await game.world.add(spawner);
  }
  
  Future<void> _createBackground() async {
    // Crear componente de fondo visual
    final background = _MapBackground();
    await game.world.add(background);
  }
  
  Future<void> _createWalls() async {
    // Paredes del perímetro
    final wallThickness = 32.0;
    
    // Pared superior
    await game.world.add(_SimpleWall(
      position: Vector2(mapWidth / 2, wallThickness / 2),
      size: Vector2(mapWidth, wallThickness),
    ));
    
    // Pared inferior
    await game.world.add(_SimpleWall(
      position: Vector2(mapWidth / 2, mapHeight - wallThickness / 2),
      size: Vector2(mapWidth, wallThickness),
    ));
    
    // Pared izquierda
    await game.world.add(_SimpleWall(
      position: Vector2(wallThickness / 2, mapHeight / 2),
      size: Vector2(wallThickness, mapHeight),
    ));
    
    // Pared derecha
    await game.world.add(_SimpleWall(
      position: Vector2(mapWidth - wallThickness / 2, mapHeight / 2),
      size: Vector2(wallThickness, mapHeight),
    ));
    
    // Obstáculos interiores (escombros, drones caídos)
    await _createObstacles();
  }
  
  Future<void> _createObstacles() async {
    final random = Random();
    
    // Crear algunos obstáculos aleatorios
    for (int i = 0; i < 10; i++) {
      final x = random.nextDouble() * (mapWidth - 200) + 100;
      final y = random.nextDouble() * (mapHeight - 200) + 100;
      final width = random.nextDouble() * 60 + 40;
      final height = random.nextDouble() * 60 + 40;
      
      await game.world.add(_SimpleWall(
        position: Vector2(x, y),
        size: Vector2(width, height),
        isObstacle: true,
      ));
    }
  }
}

/// Componente de fondo visual del mapa
class _MapBackground extends PositionComponent {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(ExteriorMapLevel.mapWidth, ExteriorMapLevel.mapHeight);
    position = Vector2.zero();
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Fondo base (suelo)
    final groundPaint = Paint()
      ..color = const Color(0xFF1a1a1a)
      ..style = PaintingStyle.fill;
    canvas.drawRect(size.toRect(), groundPaint);
    
    // Grid de líneas para dar sensación de espacio
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    const gridSize = 50.0;
    
    // Líneas verticales
    for (double x = 0; x < size.x; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.y),
        gridPaint,
      );
    }
    
    // Líneas horizontales
    for (double y = 0; y < size.y; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.x, y),
        gridPaint,
      );
    }
    
    // Manchas de humo/niebla (círculos oscuros)
    final smokePaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final random = Random(42); // Seed fijo para consistencia
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.x;
      final y = random.nextDouble() * size.y;
      final radius = random.nextDouble() * 100 + 50;
      
      canvas.drawCircle(Offset(x, y), radius, smokePaint);
    }
  }
  
  @override
  int get priority => -100; // Renderizar primero (fondo)
}

/// Componente simple de pared/obstáculo
class _SimpleWall extends PositionComponent {
  final bool isObstacle;
  
  _SimpleWall({
    required Vector2 position,
    required Vector2 size,
    this.isObstacle = false,
  }) : super(position: position, size: size, anchor: Anchor.center);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Agregar hitbox para colisiones
    add(RectangleHitbox());
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Color según tipo
    final wallColor = isObstacle 
        ? const Color(0xFF3a3a3a) // Gris oscuro para obstáculos
        : const Color(0xFF2a2a2a); // Más oscuro para paredes
    
    final wallPaint = Paint()
      ..color = wallColor
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(size.toRect(), wallPaint);
    
    // Borde
    final borderPaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawRect(size.toRect(), borderPaint);
    
    // Si es obstáculo, agregar detalles visuales
    if (isObstacle) {
      final detailPaint = Paint()
        ..color = Colors.orange.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      
      // Dibujar algunas líneas diagonales (escombros)
      canvas.drawLine(
        const Offset(0, 0),
        Offset(size.x, size.y),
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..strokeWidth = 2,
      );
    }
  }
}
