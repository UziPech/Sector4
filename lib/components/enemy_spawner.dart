import 'dart:math';
import 'package:flame/components.dart';
import '../main.dart';
import 'enemy_character.dart';
import 'world_bounds.dart';

/// Sistema de spawn dinámico de enemigos
class EnemySpawner extends Component with HasGameReference<ExpedienteKorinGame> {
  final WorldBounds worldBounds;
  final Random _random = Random();
  
  // Configuración de spawn
  double _spawnTimer = 0.0;
  double _spawnInterval = 3.0; // Segundos entre spawns
  int _maxEnemies = 10;
  int currentWave = 1; // Público para acceso desde UI
  
  // Dificultad progresiva
  double _difficultyTimer = 0.0;
  final double _difficultyIncreaseInterval = 30.0; // Cada 30 segundos aumenta dificultad
  
  EnemySpawner({required this.worldBounds});
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (game.isGameOver) return;
    
    // Actualizar timer de spawn
    _spawnTimer += dt;
    
    // Actualizar dificultad progresiva
    _difficultyTimer += dt;
    if (_difficultyTimer >= _difficultyIncreaseInterval) {
      _difficultyTimer = 0.0;
      _increaseDifficulty();
    }
    
    // Contar enemigos actuales
    final currentEnemies = game.children.whereType<EnemyCharacter>().length;
    
    // Spawn de nuevos enemigos
    if (_spawnTimer >= _spawnInterval && currentEnemies < _maxEnemies) {
      _spawnTimer = 0.0;
      _spawnEnemy();
    }
  }
  
  void _spawnEnemy() {
    // Generar posición aleatoria en el borde del mundo
    final spawnPosition = _getRandomSpawnPosition();
    
    // Crear configuración de enemigo con dificultad variable
    final config = _getEnemyConfig();
    
    final enemy = EnemyCharacter(
      playerToTrack: game.player,
      patrolCenter: spawnPosition,
      config: config,
    )..position = spawnPosition;
    
    game.world.add(enemy);
  }
  
  Vector2 _getRandomSpawnPosition() {
    // Spawn alrededor del jugador en un círculo
    final playerPos = game.player.position;
    final angle = _random.nextDouble() * 2 * pi;
    final distance = 400.0 + _random.nextDouble() * 200.0; // Entre 400-600 píxeles del jugador
    
    return playerPos + Vector2(
      cos(angle) * distance,
      sin(angle) * distance,
    );
  }
  
  EnemyConfig _getEnemyConfig() {
    // Configuración base que aumenta con la dificultad
    final speedMultiplier = 1.0 + (currentWave - 1) * 0.1;
    
    // 30% de probabilidad de spawn melee (zombie)
    final isMelee = _random.nextDouble() < 0.3;
    
    if (isMelee) {
      // Configuración para enemigo melee (zombie)
      return EnemyConfig(
        combatType: CombatType.melee,
        detectionRadius: 250.0 + (currentWave * 10), // Mayor detección
        walkingSpeed: 40.0 * speedMultiplier, // Más rápido
        chasingSpeed: 140.0 * speedMultiplier, // Mucho más rápido al perseguir
        meleeDamage: 15.0 + (currentWave * 2), // Daño aumenta con oleadas
        meleeAttackCooldown: 0.5,
        changeDirInterval: 2.0,
        patrolRadius: 150.0,
        stunnedDuration: 0.5,
        healthThresholdToRetreat: 0.1, // Menos propenso a retirarse
      );
    } else {
      // Configuración para enemigo ranged (normal)
      return EnemyConfig(
        combatType: CombatType.ranged,
        detectionRadius: 200.0 + (currentWave * 10),
        walkingSpeed: 30.0 * speedMultiplier,
        chasingSpeed: 100.0 * speedMultiplier,
        shootCooldown: max(0.5, 1.5 - (currentWave * 0.1)),
        changeDirInterval: 2.0,
        patrolRadius: 150.0,
        stunnedDuration: 0.5,
        healthThresholdToRetreat: 0.3,
      );
    }
  }
  
  void _increaseDifficulty() {
    currentWave++;
    
    // Reducir intervalo de spawn (mínimo 1 segundo)
    _spawnInterval = max(1.0, _spawnInterval - 0.2);
    
    // Aumentar máximo de enemigos
    _maxEnemies = min(20, _maxEnemies + 2);
    
    print('🔥 Oleada $currentWave - Intervalo: $_spawnInterval - Max: $_maxEnemies');
  }
  
  void reset() {
    _spawnTimer = 0.0;
    _spawnInterval = 3.0;
    _maxEnemies = 10;
    currentWave = 1;
    _difficultyTimer = 0.0;
  }
}
