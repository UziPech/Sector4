import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flame_tiled/flame_tiled.dart';

import 'systems/map_loader.dart';
import 'components/player.dart';
import 'components/mel.dart';
import 'ui/game_hud.dart';

/// Motor principal del juego Expediente Kōrin
/// Gestiona el mundo, carga de mapas por capítulo y sistemas de juego
class ExpedienteKorinGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  
  // Referencias a componentes principales
  late PlayerCharacter player;
  late MelCharacter mel;
  late GameHUD hud;
  
  // Sistema de mapas
  final MapLoader mapLoader = MapLoader();
  TiledComponent? currentMap;
  
  // Estado del juego
  int currentChapter = 1;
  bool isGameOver = false;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Configurar cámara
    camera.viewfinder.anchor = Anchor.center;
    
    // Cargar mapa del capítulo actual
    await loadChapterMap(currentChapter);
    
    // Crear jugador (Dan)
    player = PlayerCharacter();
    player.position = mapLoader.getPlayerSpawnPosition(currentChapter);
    await world.add(player);
    
    // Crear companion (Mel)
    mel = MelCharacter(
      position: player.position + Vector2(50, 0),
      player: player,
    );
    await world.add(mel);
    
    // Configurar cámara para seguir al jugador
    camera.follow(player);
    
    // Crear HUD
    hud = GameHUD(player: player, mel: mel);
    await add(hud);
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
    await mapLoader.loadCollisions(currentMap!, world);
    
    // Cargar entidades del mapa (enemigos, triggers, etc.)
    await mapLoader.loadEntities(currentMap!, world, this);
  }
  
  /// Transición a otro capítulo
  Future<void> transitionToChapter(int chapter) async {
    currentChapter = chapter;
    await loadChapterMap(chapter);
    
    // Reposicionar jugador
    player.position = mapLoader.getPlayerSpawnPosition(chapter);
    mel.position = player.position + Vector2(50, 0);
  }
  
  /// Maneja el Game Over
  void gameOver() {
    if (!isGameOver) {
      isGameOver = true;
      overlays.add('GameOver');
      pauseEngine();
    }
  }
  
  /// Reinicia el juego
  void restart() {
    isGameOver = false;
    overlays.remove('GameOver');
    resumeEngine();
    
    // Reiniciar estado del jugador
    player.resetHealth();
    player.position = mapLoader.getPlayerSpawnPosition(currentChapter);
    
    // Reiniciar Mel
    mel.reset();
    mel.position = player.position + Vector2(50, 0);
  }
}
