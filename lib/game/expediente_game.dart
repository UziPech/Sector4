import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flame_tiled/flame_tiled.dart';

import 'systems/map_loader.dart';
import 'components/player.dart';
import 'components/mel.dart';
import 'models/player_role.dart';
import 'ui/game_hud.dart';
import 'ui/mission_notification.dart';
import 'levels/bunker_boss_level.dart';
import 'levels/exterior_map_level.dart';
import 'components/enemies/yurei_kohaa.dart'; // Para reset de HP
import 'components/bosses/on_oyabun_boss.dart'; // Para reset del boss
import '../narrative/models/dialogue_data.dart'; // Para sistema de diálogos
import 'audio_manager.dart'; // Importar AudioManager
import '../combat/weapon_system.dart'; // Para RangedWeapon en isRangedWeaponNotifier

/// Motor principal del juego Expediente Kōrin
/// Gestiona el mundo, carga de mapas por capítulo y sistemas de juego
class ExpedienteKorinGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  // Referencias a componentes principales
  late PlayerCharacter player;
  late MelCharacter mel;
  late GameHUD hud;
  late MissionNotification notificationSystem;

  // Sistema de mapas
  final MapLoader mapLoader = MapLoader();
  TiledComponent? currentMap;

  // Estado del juego
  int currentChapter = 1;
  bool isGameOver = false;
  final bool startInBossMode;
  final bool startInExteriorMap;
  final PlayerRole? selectedRole;

  // SISTEMA DE VIDAS
  int remainingLives = 3;
  static const int maxLives = 3;

  // SISTEMA DE DIÁLOGOS
  DialogueSequence? currentDialogue;

  // PERFORMANCE: Tracked entities to avoid expensive queries
  YureiKohaa? activeKohaa;
  OnOyabunBoss? activeBoss;
  final List<Component> allies = []; // Tracks allied enemies and kijin

  // INPUT TÁCTIL (Joystick Virtual)
  Vector2 joystickInput = Vector2.zero();

  // UI STATE NOTIFIERS
  final ValueNotifier<String> chapterNameNotifier = ValueNotifier<String>(
    'CAPÍTULO 1: EL LLAMADO',
  );
  final ValueNotifier<String> locationNotifier = ValueNotifier<String>(
    'Habitación de Emma',
  );
  final ValueNotifier<String> objectiveNotifier = ValueNotifier<String>(
    'Explorar la casa',
  );
  // HUD Notifiers
  final ValueNotifier<double> playerHealthNotifier = ValueNotifier<double>(100);
  final ValueNotifier<double> playerMaxHealthNotifier = ValueNotifier<double>(
    100,
  );
  final ValueNotifier<int> livesNotifier = ValueNotifier<int>(3);
  final ValueNotifier<double> melCooldownNotifier = ValueNotifier<double>(
    1.0,
  ); // 1.0 = listo, 0.0 = ocupado
  final ValueNotifier<bool> melReadyNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isRangedWeaponNotifier = ValueNotifier<bool>(
    false,
  ); // true cuando pistola equipada

  ExpedienteKorinGame({
    this.startInBossMode = false,
    this.startInExteriorMap = false,
    this.selectedRole,
  });

  @override
  Future<void> onLoad() async {
    // debugMode = true; // Desactivado - colisiones corregidas
    await super.onLoad();

    // Inicializar Audio
    await AudioManager().init();

    // Configurar cámara
    camera.viewfinder.anchor = Anchor.center;

    // Crear jugador (Dan o Mel según selección)
    player = PlayerCharacter(selectedRole: selectedRole);
    // La posición se ajustará según el nivel
    await world.add(player);

    // Crear companion (Mel)
    mel = MelCharacter(
      position: Vector2.zero(), // Se ajustará
      player: player,
    );
    await world.add(mel);

    // Configurar cámara para seguir al jugador
    camera.follow(player);

    // Alejar la vista para que en móvil el mapa se vea con más contexto
    // 0.65 = ~35% más área visible que el zoom por defecto (1.0)
    camera.viewfinder.zoom = 0.65;

    // Crear HUD
    hud = GameHUD(player: player, mel: mel);
    camera.viewport.add(hud);

    notificationSystem = MissionNotification();
    notificationSystem = MissionNotification();
    camera.viewport.add(notificationSystem);

    if (startInBossMode) {
      await loadBossLevel();
    } else if (startInExteriorMap) {
      await loadExteriorMap();
    } else {
      // Cargar mapa del capítulo actual
      await loadChapterMap(currentChapter);
      player.position = mapLoader.getPlayerSpawnPosition(currentChapter);
      mel.position = player.position + Vector2(50, 0);
    }
  }

  Future<void> loadBossLevel() async {
    // Actualizar UI para Boss Level
    chapterNameNotifier.value = 'MODO BOSS: THE STALKER';
    locationNotifier.value = 'Búnker Subterráneo';
    objectiveNotifier.value = 'Eliminar la amenaza';

    await world.add(BunkerBossLevel());
    // El mensaje de advertencia se muestra desde BunkerBossLevel.onLoad()
  }

  Future<void> loadExteriorMap() async {
    // Actualizar UI para Exterior Map
    chapterNameNotifier.value = 'ZONA EXTERIOR';
    locationNotifier.value = 'Perímetro del Búnker';
    objectiveNotifier.value = 'Sobrevivir a la horda';

    await world.add(ExteriorMapLevel());
    notificationSystem.show(
      'ALERTA',
      'Múltiples contactos hostiles detectados',
    );
  }

  /// Carga el mapa del capítulo especificado
  Future<void> loadChapterMap(int chapter) async {
    // Remover mapa anterior si existe
    if (currentMap != null) {
      world.remove(currentMap!);
    }

    // Cargar nuevo mapa
    currentMap = await mapLoader.loadMap(chapter);
    await world.add(currentMap!);

    // Cargar colisiones del mapa
    await mapLoader.loadCollisions(currentMap!, world, currentChapter);

    // Cargar entidades del mapa (enemigos, triggers, etc.)
    await mapLoader.loadEntities(currentMap!, world, this);
  }

  // Nombres de capítulos
  static const Map<int, String> _chapterNames = {
    1: 'CAPÍTULO 1: EL LLAMADO',
    2: 'CAPÍTULO 2: EL BÚNKER', // Nombre asumido, editable
  };

  /// Transición a otro capítulo
  Future<void> transitionToChapter(int chapter) async {
    currentChapter = chapter;

    // Actualizar UI
    chapterNameNotifier.value = _chapterNames[chapter] ?? 'CAPÍTULO $chapter';

    await loadChapterMap(chapter);

    // Reposicionar jugador
    player.position = mapLoader.getPlayerSpawnPosition(chapter);
    mel.position = player.position + Vector2(50, 0);
  }

  /// Maneja el Game Over
  void gameOver() {
    if (!isGameOver) {
      remainingLives--;

      if (remainingLives > 0) {
        // AÚN HAY VIDAS - Mostrar diálogo del compañero
        _showCompanionReviveDialogue();
      } else {
        // SIN VIDAS - Game Over real
        _showRealGameOver();
      }
    }
  }

  /// Actualiza el input del joystick virtual desde la UI
  void updateJoystickInput(Vector2 input) {
    joystickInput = input;
  }

  /// Sincroniza los ValueNotifiers del HUD con el estado actual del juego
  void updateHUDNotifiers() {
    if (!isLoaded) return;
    playerHealthNotifier.value = player.health;
    playerMaxHealthNotifier.value = player.maxHealth;
    livesNotifier.value = remainingLives;
    melReadyNotifier.value = mel.canHeal;
    melCooldownNotifier.value = mel.healCooldownProgress;
    // Actualizar si el arma actual es de rango (para mostrar botón R)
    isRangedWeaponNotifier.value =
        player.weaponInventory.currentWeapon is RangedWeapon;
  }

  void _showCompanionReviveDialogue() {
    isGameOver = true;
    pauseEngine();

    final isDan = player.role == PlayerRole.dan;
    final companionName = isDan ? 'Mel' : 'Dan';
    final livesLeft = remainingLives;

    String message;
    if (livesLeft == 2) {
      // Primera muerte - Urgente pero optimista
      final messages = isDan
          ? [
              '¡Dan! Levántate, no podemos rendirnos ahora. Aún tienes 2 oportunidades más.',
              '¡Oye oye! No eres inmortal, ten cuidado. Quedan 2 vidas.',
              'Dan, concéntrate. Esto no es entrenamiento. Aún tienes 2 intentos.',
            ]
          : [
              'Mel, no es momento de caer. Quedan 2 intentos. ¡Vamos!',
              '¡Cuidado, Mel! No puedes morir así. Tienes 2 oportunidades más.',
              'Mel, respira. Aún podemos hacerlo. 2 vidas restantes.',
            ];
      message = (messages..shuffle()).first;
    } else if (livesLeft == 1) {
      // Segunda muerte - Preocupado y serio
      final messages = isDan
          ? [
              'Dan... esta es nuestra última oportunidad. Por favor, ten cuidado.',
              'Dan, por favor... solo queda UN intento. No podemos fallar.',
              '¡Dan! Esta es la última vez. Si caes de nuevo... todo habrá terminado.',
            ]
          : [
              'Mel... solo queda un intento. No podemos fallar.',
              'Mel, escucha... esta es la última oportunidad. Ten mucho cuidado.',
              'Por favor, Mel... un intento más. Eso es todo lo que tenemos.',
            ];
      message = (messages..shuffle()).first;
    } else {
      message = '¡Levántate, aún hay esperanza!';
    }

    // Auto-restart después de 2 segundos
    // Future.delayed(const Duration(seconds: 2), () {
    //   restart();
    // });

    // Mostrar diálogo visual
    final dialogueSequence = DialogueSequence(
      id: 'revive_dialogue_$livesLeft',
      dialogues: [
        DialogueData(
          speakerName: companionName,
          text: message,
          avatarPath: isDan
              ? 'assets/avatars/dialogue_icons/Mel_Dialogue.png'
              : 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
          type: DialogueType.normal,
          canSkip: false,
          autoAdvanceDelay: const Duration(seconds: 3),
        ),
      ],
      onComplete: () {
        // Reiniciar cuando termine el diálogo
        restart();
      },
    );

    showDialogue(dialogueSequence);
  }

  void _showRealGameOver() {
    isGameOver = true;
    overlays.add('GameOver');
    pauseEngine();
  }

  /// Reinicia el juego
  void restart() async {
    // Detectar si es un REINICIO COMPLETO (sin vidas) o PARCIAL (con vidas)
    final isFullRestart = remainingLives <= 0;

    if (isFullRestart) {
      // Resetear vidas
      remainingLives = maxLives;

      // Remover TODOS los componentes del mundo excepto Jugador y Mel
      // Esto evita duplicación de bosses, enemigos, y otros elementos
      final childrenToRemove = world.children
          .where((child) => child != player && child != mel)
          .toList();
      for (final child in childrenToRemove) {
        child.removeFromParent();
      }

      // Recargar nivel completo según el modo actual
      if (startInBossMode) {
        await loadBossLevel();
      } else if (startInExteriorMap) {
        await loadExteriorMap();
      } else {
        await loadChapterMap(currentChapter);
      }

      // Reposicionar jugador al spawn inicial
      player.resetHealth();
      player.position = mapLoader.getPlayerSpawnPosition(currentChapter);

      // Reiniciar Mel
      mel.reset();
      mel.position = player.position + Vector2(50, 0);
    } else {
      // Respawn simple (con vidas restantes)
      player.resetHealth();
      player.position = mapLoader.getPlayerSpawnPosition(currentChapter);

      // Reiniciar Mel
      mel.reset();
      mel.position = player.position + Vector2(50, 0);

      // RECUPERAR HP DE KOHAA si existe (solo en respawn parcial)
      final kohaas = world.children.query<YureiKohaa>();
      for (final kohaa in kohaas) {
        if (!kohaa.isDead) {
          kohaa.recoverHealthOnRetry(100.0);
        }
      }
    }

    isGameOver = false;
    overlays.remove('GameOver');
    resumeEngine();
  }

  /// Muestra una secuencia de diálogo
  void showDialogue(DialogueSequence sequence) {
    currentDialogue = sequence;
    pauseEngine();
    overlays.add('DialogueOverlay');
  }

  /// Llamado cuando termina un diálogo
  void onDialogueComplete() {
    currentDialogue = null;
    overlays.remove('DialogueOverlay');
    resumeEngine();
  }
}
