import 'dart:math';
import 'package:flame/components.dart';
import '../expediente_game.dart';
import '../components/enemies/irracional.dart';

/// Sistema de spawn de enemigos para el mapa exterior
class EnemySpawner extends Component with HasGameReference<ExpedienteKorinGame> {
  final double spawnInterval;
  final int maxEnemies;
  final double mapWidth;
  final double mapHeight;
  
  double _spawnTimer = 0.0;
  int _enemiesSpawned = 0;
  final Random _random = Random();
  
  EnemySpawner({
    this.spawnInterval = 5.0,
    this.maxEnemies = 10,
    required this.mapWidth,
    required this.mapHeight,
  });
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Actualizar timer
    _spawnTimer += dt;
    
    // Spawn de enemigos
    if (_spawnTimer >= spawnInterval && _enemiesSpawned < maxEnemies) {
      _spawnEnemy();
      _spawnTimer = 0.0;
    }
  }
  
  void _spawnEnemy() {
    // Posición aleatoria en los bordes del mapa
    final spawnSide = _random.nextInt(4); // 0=arriba, 1=abajo, 2=izq, 3=der
    Vector2 spawnPosition;
    
    switch (spawnSide) {
      case 0: // Arriba
        spawnPosition = Vector2(
          _random.nextDouble() * mapWidth,
          50.0,
        );
        break;
      case 1: // Abajo
        spawnPosition = Vector2(
          _random.nextDouble() * mapWidth,
          mapHeight - 50.0,
        );
        break;
      case 2: // Izquierda
        spawnPosition = Vector2(
          50.0,
          _random.nextDouble() * mapHeight,
        );
        break;
      case 3: // Derecha
        spawnPosition = Vector2(
          mapWidth - 50.0,
          _random.nextDouble() * mapHeight,
        );
        break;
      default:
        spawnPosition = Vector2(mapWidth / 2, mapHeight / 2);
    }
    
    // Crear enemigo
    final enemy = IrrationalEnemy(
      position: spawnPosition,
      health: 50.0,
      speed: 100.0,
      damage: 10.0,
    );
    
    game.world.add(enemy);
    _enemiesSpawned++;
  }
  
  /// Reinicia el spawner
  void reset() {
    _spawnTimer = 0.0;
    _enemiesSpawned = 0;
  }
}
