import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Sistema de mundo infinito con generación procedural de chunks
class InfiniteWorld extends Component {
  // Tamaño de cada chunk
  static const double chunkSize = 800.0;
  
  InfiniteWorld({this.seed = 12345}) {
    // Prioridad baja para que se renderice DETRÁS de los personajes
    priority = -1000;
  }
  
  // Chunks actualmente cargados (key: "x,y")
  final Map<String, WorldChunk> _loadedChunks = {};
  
  // Distancia de carga (chunks alrededor del jugador)
  final int loadDistance = 2;
  
  // Referencia al jugador para saber qué chunks cargar
  PositionComponent? player;
  
  // Seed para generación procedural consistente
  final int seed;
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (player == null) return;
    
    // Calcular chunk actual del jugador
    final playerChunkX = (player!.position.x / chunkSize).floor();
    final playerChunkY = (player!.position.y / chunkSize).floor();
    
    // Cargar chunks cercanos
    for (int x = playerChunkX - loadDistance; x <= playerChunkX + loadDistance; x++) {
      for (int y = playerChunkY - loadDistance; y <= playerChunkY + loadDistance; y++) {
        final key = '$x,$y';
        if (!_loadedChunks.containsKey(key)) {
          _loadChunk(x, y);
        }
      }
    }
    
    // Descargar chunks lejanos
    final chunksToRemove = <String>[];
    _loadedChunks.forEach((key, chunk) {
      final distance = max(
        (chunk.chunkX - playerChunkX).abs(),
        (chunk.chunkY - playerChunkY).abs(),
      );
      
      if (distance > loadDistance + 1) {
        chunksToRemove.add(key);
      }
    });
    
    for (final key in chunksToRemove) {
      _unloadChunk(key);
    }
  }
  
  void _loadChunk(int x, int y) {
    final key = '$x,$y';
    final chunk = WorldChunk(
      chunkX: x,
      chunkY: y,
      seed: seed,
    );
    
    _loadedChunks[key] = chunk;
    parent?.add(chunk);
  }
  
  void _unloadChunk(String key) {
    final chunk = _loadedChunks.remove(key);
    chunk?.removeFromParent();
  }
  
  /// Obtener un punto de spawn aleatorio en el mundo visible
  Vector2 getRandomSpawnPoint() {
    if (player == null) return Vector2.zero();
    
    final random = Random();
    final angle = random.nextDouble() * 2 * pi;
    final distance = 400.0 + random.nextDouble() * 200.0;
    
    return player!.position + Vector2(
      cos(angle) * distance,
      sin(angle) * distance,
    );
  }
  
  void reset() {
    final keys = _loadedChunks.keys.toList();
    for (final key in keys) {
      _unloadChunk(key);
    }
  }
}

/// Chunk individual del mundo con generación procedural
class WorldChunk extends PositionComponent {
  final int chunkX;
  final int chunkY;
  final int seed;
  
  late final Random _random;
  final List<_Tile> _tiles = [];
  
  WorldChunk({
    required this.chunkX,
    required this.chunkY,
    required this.seed,
  }) {
    // Prioridad baja para renderizar detrás de todo
    priority = -999;
    
    // Seed único para este chunk
    final chunkSeed = seed + chunkX * 73856093 + chunkY * 19349663;
    _random = Random(chunkSeed);
    
    position = Vector2(
      chunkX * InfiniteWorld.chunkSize,
      chunkY * InfiniteWorld.chunkSize,
    );
    
    _generateTiles();
  }
  
  void _generateTiles() {
    // Generar patrón de tiles proceduralmente
    final tileSize = 100.0;
    final tilesPerSide = (InfiniteWorld.chunkSize / tileSize).ceil();
    
    for (int x = 0; x < tilesPerSide; x++) {
      for (int y = 0; y < tilesPerSide; y++) {
        // Usar noise procedural para variación
        final noise = _getPerlinNoise(
          chunkX * tilesPerSide + x,
          chunkY * tilesPerSide + y,
        );
        
        // Determinar tipo de tile basado en noise
        final tileType = _getTileType(noise);
        
        _tiles.add(_Tile(
          position: Vector2(x * tileSize, y * tileSize),
          size: tileSize,
          type: tileType,
        ));
      }
    }
  }
  
  double _getPerlinNoise(int x, int y) {
    // Implementación simple de noise procedural
    final n = x + y * 57;
    final nn = (n << 13) ^ n;
    final noise = 1.0 - ((nn * (nn * nn * 15731 + 789221) + 1376312589) & 0x7fffffff) / 1073741824.0;
    return (noise + 1.0) / 2.0; // Normalizar a 0-1
  }
  
  TileType _getTileType(double noise) {
    if (noise < 0.3) {
      return TileType.dark;
    } else if (noise < 0.6) {
      return TileType.medium;
    } else {
      return TileType.light;
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Renderizar tiles
    for (final tile in _tiles) {
      tile.render(canvas);
    }
    
    // Renderizar grid sutil (opcional)
    final gridPaint = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, InfiniteWorld.chunkSize, InfiniteWorld.chunkSize),
      gridPaint,
    );
  }
}

enum TileType { dark, medium, light }

class _Tile {
  final Vector2 position;
  final double size;
  final TileType type;
  
  late final Paint paint;
  
  _Tile({
    required this.position,
    required this.size,
    required this.type,
  }) {
    paint = Paint()
      ..color = _getColor()
      ..style = PaintingStyle.fill;
  }
  
  Color _getColor() {
    switch (type) {
      case TileType.dark:
        return const Color.fromRGBO(20, 20, 25, 1.0);
      case TileType.medium:
        return const Color.fromRGBO(30, 30, 35, 1.0);
      case TileType.light:
        return const Color.fromRGBO(40, 40, 45, 1.0);
    }
  }
  
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(position.x, position.y, size, size),
      paint,
    );
  }
}
