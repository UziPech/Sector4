import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../expediente_game.dart';
import '../components/player.dart';
import '../components/enemies/yurei_kohaa.dart';
import '../components/enemies/irracional.dart';
import '../components/bosses/on_oyabun_boss.dart';
import '../components/effects/summoning_circle.dart';
import '../systems/resurrection_system.dart';
import '../systems/enemy_spawner.dart';
import '../models/player_role.dart';
import '../../narrative/components/dialogue_system.dart';
import '../../narrative/models/dialogue_data.dart';

/// Nivel del mapa exterior post-resonante
/// Mapa simple sin Tiled, generado proceduralmente
/// INCLUYE: Sistema de invocación de On-Oyabun post-Kohaa
class ExteriorMapLevel extends Component with HasGameReference<ExpedienteKorinGame> {
  late ResurrectionManager resurrectionManager;
  
  // Control de Kohaa
  bool _kohaaSpawned = false;
  bool _initialEnemiesCleared = false;
  int _initialEnemyCount = 5;
  YureiKohaa? _kohaa;
  
  // Control de On-Oyabun (aparece después de Kohaa)
  bool _kohaaDefeated = false;
  bool _oyabunSpawned = false;
  bool _summoningInProgress = false;
  double _postKohaaDelay = 5.0; // Segundos antes de invocar
  double _postKohaaTimer = 0.0;
  OnOyabunBoss? _oyabun;
  
  // Dimensiones del mapa
  static const double mapWidth = 2000.0;
  static const double mapHeight = 1500.0;
  
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
    
    // Verificar si Kohaa fue derrotada
    if (_kohaaSpawned && !_kohaaDefeated && _kohaa?.isDead == true) {
      _kohaaDefeated = true;
      _postKohaaTimer = 0.0;
      debugPrint('💀 Yurei Kohaa ha sido derrotada!');
      debugPrint('⏳ On-Oyabun será invocado en $_postKohaaDelay segundos...');
    }
    
    // Timer post-Kohaa para invocar a On-Oyabun
    if (_kohaaDefeated && !_summoningInProgress && !_oyabunSpawned) {
      _postKohaaTimer += dt;
      if (_postKohaaTimer >= _postKohaaDelay) {
        _startOyabunSummoning();
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
  
  // ==================== ON-OYABUN SUMMONING LOGIC ====================
  
  /// Inicia el ritual de invocación de On-Oyabun
  void _startOyabunSummoning() {
    if (_summoningInProgress || _oyabunSpawned) return;
    
    _summoningInProgress = true;
    debugPrint('🔴 INICIANDO RITUAL DE INVOCACIÓN DE ON-OYABUN...');
    
    // Posición central del mapa para el ritual
    final summoningPosition = Vector2(mapWidth / 2, mapHeight / 2);
    
    // Crear círculo de invocación
    final circle = SummoningCircle(
      position: summoningPosition,
      onSummoningComplete: () {
        _summoningInProgress = false;
        _spawnOyabun();
      },
    );
    game.world.add(circle);
    
    // Crear las 28 katanas formando un círculo
    _create28KatanaCircle(summoningPosition);
    
    // Mostrar diálogo de invocación
    Future.delayed(const Duration(milliseconds: 500), () {
      _showOyabunIntro();
    });
  }
  
  /// Crea un círculo de 28 katanas en el suelo
  void _create28KatanaCircle(Vector2 center) {
    const int katanaCount = 28;
    const double radiusCircle = 180.0;
    
    for (int i = 0; i < katanaCount; i++) {
      final angle = (i / katanaCount) * 2 * pi;
      final x = center.x + cos(angle) * radiusCircle;
      final y = center.y + sin(angle) * radiusCircle;
      
      // Crear katana clavada en el suelo
      final katana = _GroundKatana(
        position: Vector2(x, y),
        angle: angle + pi / 2, // Apuntando hacia el centro
      );
      game.world.add(katana);
    }
    
    debugPrint('⚔️ 28 katanas han emergido del suelo...');
  }
  
  /// Diálogo de introducción de On-Oyabun
  void _showOyabunIntro() {
    if (game.buildContext == null || _oyabunSpawned) return;
    
    game.pauseEngine();
    
    final isDan = game.player.role == PlayerRole.dan;
    
    final introSequence = DialogueSequence(
      id: 'oyabun_intro',
      dialogues: [
        const DialogueData(
          speakerName: 'Sistema',
          text: 'ALERTA: Las almas liberadas han despertado algo más profundo...',
          type: DialogueType.system,
        ),
        DialogueData(
          speakerName: isDan ? 'Mel' : 'Dan',
          text: isDan
              ? 'Dan... las katanas están emergiendo del suelo. Esta presencia...'
              : 'Mel, ¿lo sientes? No es solo un Kijin. Es algo peor.',
          avatarPath: isDan
              ? 'assets/avatars/dialogue_icons/Mel_Dialogue.png'
              : 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
        ),
        const DialogueData(
          speakerName: '???',
          text: '...Veintitrés almas. Cinco guerreros. Todos cayeron ante mi filo.',
        ),
        const DialogueData(
          speakerName: '???',
          text: 'Y ahora... ahora ellos viven en mí. Y yo vivo en ellos.',
        ),
        const DialogueData(
          speakerName: 'On-Oyabun',
          text: 'Kohaa ha caído. Su dolor resonó con el mío. Ahora... es mi turno.',
        ),
        DialogueData(
          speakerName: isDan ? 'Dan' : 'Mel',
          text: isDan
              ? 'Esto es diferente. Es... más antiguo. Más poderoso.'
              : 'Una Singularidad. Una fusión de víctima y verdugo. Cuidado, Dan.',
          avatarPath: isDan
              ? 'assets/avatars/dialogue_icons/Dan_Dialogue.png'
              : 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
        ),
      ],
      onComplete: () {
        game.resumeEngine();
      },
    );
    
    DialogueOverlay.show(game.buildContext!, introSequence);
  }
  
  /// Spawn del jefe On-Oyabun
  void _spawnOyabun() {
    if (_oyabunSpawned) return;
    
    _oyabunSpawned = true;
    
    // Spawn en el centro del mapa
    _oyabun = OnOyabunBoss(
      position: Vector2(mapWidth / 2, mapHeight / 2),
    );
    game.world.add(_oyabun!);
    
    debugPrint('⚔️💀 怨親分 ON-OYABUN HA SIDO INVOCADO!');
  }
  
  // ==================== ORIGINAL METHODS ====================
  
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
    // Paredes del perímetro (límites del mapa)
    final wallThickness = 40.0;
    
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
    
    // Crear colisiones de objetos visibles en el mapa
    await _createMapObjectCollisions();
  }
  
  Future<void> _createMapObjectCollisions() async {
    // Basado en la imagen del mapa (1600x1200), crear hitboxes para cada objeto visible
    // Coordenadas ajustadas según la imagen real
    
    // === LADO IZQUIERDO (ZONA ROJA) ===
    
    // Jeep izquierdo (oxidado) - parte superior izquierda
    await game.world.add(_SimpleWall(
      position: Vector2(280, 420),
      size: Vector2(200, 140),
      isObstacle: true,
    ));
    
    // Reflector izquierdo superior
    await game.world.add(_SimpleWall(
      position: Vector2(120, 280),
      size: Vector2(70, 100),
      isObstacle: true,
    ));
    
    // Cajas/contenedores izquierda superior
    await game.world.add(_SimpleWall(
      position: Vector2(180, 180),
      size: Vector2(100, 100),
      isObstacle: true,
    ));
    
    // Barriles amarillos (biohazard) izquierda inferior
    await game.world.add(_SimpleWall(
      position: Vector2(200, 850),
      size: Vector2(120, 100),
      isObstacle: true,
    ));
    
    // Valla inferior izquierda (horizontal)
    await game.world.add(_SimpleWall(
      position: Vector2(400, 1000),
      size: Vector2(600, 50),
      isObstacle: true,
    ));
    
    // === CENTRO ===
    
    // Escombros/objetos centro
    await game.world.add(_SimpleWall(
      position: Vector2(450, 700),
      size: Vector2(100, 80),
      isObstacle: true,
    ));
    
    // Valla central (vertical) - REMOVIDA para permitir paso
    
    // === LADO DERECHO (ZONA VERDE) ===
    
    // Jeep derecho (verde militar) - parte superior derecha
    await game.world.add(_SimpleWall(
      position: Vector2(1320, 420),
      size: Vector2(200, 140),
      isObstacle: true,
    ));
    
    // Reflector derecho superior
    await game.world.add(_SimpleWall(
      position: Vector2(1480, 280),
      size: Vector2(70, 100),
      isObstacle: true,
    ));
    
    // Cajas/contenedores derecha superior
    await game.world.add(_SimpleWall(
      position: Vector2(1420, 180),
      size: Vector2(100, 100),
      isObstacle: true,
    ));
    
    // Barriles amarillos (biohazard) derecha inferior
    await game.world.add(_SimpleWall(
      position: Vector2(1400, 850),
      size: Vector2(120, 100),
      isObstacle: true,
    ));
    
    // Valla inferior derecha (horizontal)
    await game.world.add(_SimpleWall(
      position: Vector2(1200, 1000),
      size: Vector2(600, 50),
      isObstacle: true,
    ));
    
    // Charco verde (tóxico) derecha - área de daño
    await game.world.add(_SimpleWall(
      position: Vector2(1300, 600),
      size: Vector2(220, 180),
      isObstacle: true,
    ));
  }
}

/// Componente de fondo visual del mapa
class _MapBackground extends SpriteComponent with HasGameReference<ExpedienteKorinGame> {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(ExteriorMapLevel.mapWidth, ExteriorMapLevel.mapHeight);
    position = Vector2.zero();
    
    // Cargar imagen de fondo (Flame busca en assets/images/ por defecto)
    try {
      sprite = await game.loadSprite('city_map_night.png');
    } catch (e) {
      debugPrint('❌ Error loading background image: $e');
      // Si falla, usar fondo de color sólido
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
    
    // Agregar hitbox para colisiones (passive para que bloquee al jugador)
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Solo renderizar paredes perimetrales (no obstáculos)
    // Los obstáculos son invisibles pero tienen colisión
    if (!isObstacle) {
      final wallPaint = Paint()
        ..color = const Color(0xFF2a2a2a)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(size.toRect(), wallPaint);
      
      final borderPaint = Paint()
        ..color = Colors.red.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawRect(size.toRect(), borderPaint);
    }
    
    // DEBUG: Ver hitboxes de objetos
    if (isObstacle) {
      final debugPaint = Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRect(size.toRect(), debugPaint);
    }
  }
}

/// Katana clavada en el suelo (para el círculo de invocación de Oyabun)
class _GroundKatana extends PositionComponent {
  final double katanaAngle;
  
  _GroundKatana({
    required Vector2 position,
    double? angle,
  })  : katanaAngle = angle ?? 0.0,
        super(position: position, anchor: Anchor.center);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(4, 30); // Katana delgada y larga
    this.angle = katanaAngle;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Hoja de la katana (plateada)
    final bladePaint = Paint()
      ..color = const Color(0xFFC0C0C0)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y * 0.8),
      bladePaint,
    );
    
    // Empuñadura (negra/roja)
    final handlePaint = Paint()
      ..color = const Color(0xFF8B0000)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, size.y * 0.8, size.x, size.y * 0.2),
      handlePaint,
    );
    
    // Borde brillante
    final edgePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawLine(
      const Offset(0, 0),
      Offset(0, size.y * 0.8),
      edgePaint,
    );
  }
  
  @override
  int get priority => -10; // Dibujadas en el suelo pero por encima del fondo
}
