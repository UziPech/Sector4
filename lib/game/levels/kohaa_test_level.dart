import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../expediente_game.dart';
import '../components/enemies/yurei_kohaa.dart';
import '../components/enemies/irracional.dart';
import '../components/player.dart';
import '../components/tiled_wall.dart';
import '../../narrative/components/dialogue_system.dart';
import '../../narrative/models/dialogue_data.dart';

/// Nivel de test para el jefe Yurei Kohaa
/// Una arena simple para testear las mecánicas del boss Kijin
class KohaaTestLevel extends Component with HasGameReference<ExpedienteKorinGame> {
  YureiKohaa? _kohaa;
  bool _bossDefeated = false;
  bool _hasShownIntro = false;
  bool _allIrrationalsDead = false;
  int _aliveIrrationals = 3;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Crear arena simple
    _createArena();
    
    // Spawnear al jugador
    game.player.position = Vector2(400, 300);
    
    // Spawnear algunos irracionales para testing
    _spawnIrrationals();
    
    // Kohaa aparecerá después de derrotar a todos los irracionales
  }
  
  void _createArena() {
    const double arenaSize = 800.0;
    const double wallThickness = 40.0;
    final center = Vector2(400, 400);
    final arenaTopLeft = center - Vector2(arenaSize / 2, arenaSize / 2);
    
    // Pared superior
    game.world.add(_Wall(
      arenaTopLeft,
      Vector2(arenaSize, wallThickness),
    ));
    
    // Pared inferior
    game.world.add(_Wall(
      arenaTopLeft + Vector2(0, arenaSize - wallThickness),
      Vector2(arenaSize, wallThickness),
    ));
    
    // Pared izquierda
    game.world.add(_Wall(
      arenaTopLeft,
      Vector2(wallThickness, arenaSize),
    ));
    
    // Pared derecha
    game.world.add(_Wall(
      arenaTopLeft + Vector2(arenaSize - wallThickness, 0),
      Vector2(wallThickness, arenaSize),
    ));
    
    // Piso
    game.world.add(_Floor(
      arenaTopLeft,
      Vector2(arenaSize, arenaSize),
      const Color(0xFF2A2A3A),
    ));
    
    // Etiqueta
    game.world.add(TextComponent(
      text: 'ARENA DE KOHAA',
      position: center,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.red.withOpacity(0.3),
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    ));
  }
  
  void _spawnIrrationals() {
    // Spawn 3 irracionales
    final positions = [
      Vector2(250, 400),
      Vector2(550, 400),
      Vector2(400, 550),
    ];
    
    for (final pos in positions) {
      final irrational = IrrationalEnemy(
        position: pos,
        health: 50.0,
        speed: 80.0,
        damage: 10.0,
      );
      game.world.add(irrational);
    }
  }
  
  void _spawnKohaa() {
    _kohaa = YureiKohaa(position: Vector2(400, 200));
    game.world.add(_kohaa!);
    debugPrint('Yurei Kohaa spawned!');
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Verificar si todos los irracionales murieron
    if (!_allIrrationalsDead) {
      final enemies = game.world.children.query<IrrationalEnemy>();
      int aliveCount = 0;
      for (final enemy in enemies) {
        if (!enemy.isDead) aliveCount++;
      }
      
      if (aliveCount == 0 && _aliveIrrationals > 0) {
        _aliveIrrationals = 0;
        _allIrrationalsDead = true;
        // Mostrar diálogo de intro de Kohaa
        Future.delayed(const Duration(milliseconds: 1000), () {
          _showIntroDialogue();
        });
      }
    }
    
    // Verificar si Kohaa fue derrotada
    if (!_bossDefeated && _kohaa != null && _kohaa!.isDead) {
      _bossDefeated = true;
      _onKohaaDefeated();
    }
  }
  
  void _showIntroDialogue() {
    if (game.buildContext == null || _hasShownIntro) return;
    _hasShownIntro = true;
    
    game.pauseEngine();
    
    // Determinar diálogos según el rol actual
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
              ? 'Dan... esta presencia es diferente. No es un elemental ni un irracional.'
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
          text: 'Una novia que no puede morir. Un amor que se pudrió en mis venas. ¿Vienes a liberarme... o a unirte a mi procesión fúnebre?',
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
  
  void _onKohaaDefeated() {
    if (game.buildContext == null) return;
    
    game.pauseEngine();
    
    final defeatSequence = DialogueSequence(
      id: 'kohaa_defeat',
      dialogues: const [
        DialogueData(
          speakerName: 'Kohaa',
          text: 'Finalmente... silencio. ¿Es esto... paz?',
          avatarPath: 'assets/avatars/dialogue_icons/kohaa_avatar.png',
        ),
        DialogueData(
          speakerName: 'Mel',
          text: 'Dan, su firma está desapareciendo, pero... aún queda algo. Una esencia.',
          avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
        ),
        DialogueData(
          speakerName: 'Dan',
          text: '¿Qué quieres decir?',
          avatarPath: 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
        ),
        DialogueData(
          speakerName: 'Mel',
          text: 'Podría... intentar algo. Traerla de vuelta, pero diferente. Purificada.',
          avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
        ),
        DialogueData(
          speakerName: 'Mel',
          text: 'Pero te advierto: resucitar un Kijin es peligroso. Consumiría DOS de mis cargas de resurrección.',
          avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
        ),
        DialogueData(
          speakerName: 'Mel',
          text: 'Si funciona, ella nos protegería con toda su fuerza. Pero si algo sale mal...',
          avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
        ),
        DialogueData(
          speakerName: 'Dan',
          text: 'Entiendo el riesgo. Veré qué hacer cuando encuentre su tumba.',
          type: DialogueType.internal,
        ),
        DialogueData(
          speakerName: 'Sistema',
          text: 'NOTA: La tumba ROJA indica un Kijin. Requiere 2 slots de resurrección. Presiona E para revivir.',
          type: DialogueType.system,
        ),
      ],
      onComplete: () {
        game.resumeEngine();
      },
    );
    
    DialogueOverlay.show(game.buildContext!, defeatSequence);
  }
}

/// Pared simple para el test
class _Wall extends TiledWall {
  _Wall(Vector2 pos, Vector2 sz) {
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

/// Piso simple para el test
class _Floor extends PositionComponent {
  final Color color;
  _Floor(Vector2 position, Vector2 size, this.color) 
      : super(position: position, size: size, priority: -100);
  
  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = color);
  }
}
