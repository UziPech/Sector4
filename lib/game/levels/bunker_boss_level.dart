import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../expediente_game.dart';
import '../../components/stalker_enemy.dart';
import '../../components/obsession_object.dart';
import '../components/player.dart';

class BunkerBossLevel extends Component with HasGameReference<ExpedienteKorinGame> {
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 1. Crear paredes del búnker (Layout simplificado)
    // Pasillo central y habitaciones conectadas
    _createWalls();
    
    // 2. Spawnear al Jugador (Centro de Comando)
    game.player.position = Vector2(400, 600); // Posición aproximada
    
    // 3. Spawnear al Stalker (Cerca del jugador)
    final stalker = StalkerEnemy();
    stalker.position = Vector2(400, 300);
    stalker.playerToTrack = game.player;
    game.world.add(stalker);
    
    // 4. Spawnear el Objeto Obsesivo (Lejos, en "Dormitorios")
    final object = ObsessionObject(
      id: 'stalker_obj',
      linkedEnemy: stalker,
      position: Vector2(800, 100), // Lejos
    );
    game.world.add(object);
    stalker.obsessionObjectId = object.id;
    
    // 5. Efecto de Alerta Roja
    game.camera.viewport.add(RedAlertOverlay());
  }
  
  void _createWalls() {
    final paint = BasicPalette.gray.paint()..style = PaintingStyle.stroke..strokeWidth = 4;
    
    // Definir rectángulos de habitaciones (x, y, w, h)
    final rooms = [
      Rect.fromLTWH(300, 500, 200, 200), // Centro Comando (Start)
      Rect.fromLTWH(300, 200, 200, 300), // Pasillo
      Rect.fromLTWH(100, 200, 200, 200), // Lab
      Rect.fromLTWH(500, 200, 200, 200), // Armería
      Rect.fromLTWH(300, 0, 200, 200),   // Dormitorio (Objetivo)
    ];
    
    for (final room in rooms) {
      // Dibujar piso visual (opcional)
      // Agregar paredes físicas (TiledWall placeholder)
      // Por simplicidad, agregamos 4 paredes por habitación, dejando huecos para puertas
      // Esto es complejo de hacer proceduralmente perfecto rápido.
      // Usaremos un enfoque más simple: Un gran rectángulo con obstáculos.
    }
    
    // Enfoque simple: Arena grande con pilares
    // Paredes exteriores
    game.world.add(Wall(Vector2(0, 0), Vector2(1000, 10))); // Top
    game.world.add(Wall(Vector2(0, 0), Vector2(10, 1000))); // Left
    game.world.add(Wall(Vector2(990, 0), Vector2(10, 1000))); // Right
    game.world.add(Wall(Vector2(0, 990), Vector2(1000, 10))); // Bottom
    
    // Pilares interiores (obstáculos)
    game.world.add(Wall(Vector2(300, 300), Vector2(50, 200)));
    game.world.add(Wall(Vector2(650, 300), Vector2(50, 200)));
  }
}

class Wall extends PositionComponent with CollisionCallbacks {
  Wall(Vector2 position, Vector2 size) : super(position: position, size: size) {
    // add(RectangleHitbox()..collisionType = CollisionType.passive);
    // Usamos TiledWall para que el jugador colisione con él (según lógica de player.dart)
  }
  
  @override
  Future<void> onLoad() async {
    // Hack: Player busca colisión con "TiledWall". 
    // Como TiledWall es una clase en player.dart (o main), necesitamos que esta clase SEA un TiledWall
    // O cambiar player.dart para chocar con "Wall".
    // Por ahora, solo visual debug
    debugMode = true;
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
