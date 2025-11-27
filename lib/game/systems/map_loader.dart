import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:tiled/tiled.dart' as tiled;
import 'package:flame/collisions.dart';

/// Sistema de carga de mapas por capítulo
class MapLoader {
  // Registro de mapas por capítulo
  static const Map<int, String> _chapterMaps = {
    1: 'tiles/capitulo_1/casa_dan.tmx',
    2: 'tiles/capitulo_2/bunker.tmx',
    // Agregar más capítulos aquí
  };
  
  // Posiciones de spawn del jugador por capítulo
  static final Map<int, Vector2> _playerSpawns = {
    1: Vector2(200, 300), // Casa de Dan
    2: Vector2(400, 300), // Búnker
  };
  
  /// Carga el mapa del capítulo especificado
  Future<TiledComponent> loadMap(int chapter) async {
    final mapPath = _chapterMaps[chapter];
    if (mapPath == null) {
      throw Exception('No existe mapa para el capítulo $chapter');
    }
    
    return await TiledComponent.load(
      mapPath,
      Vector2.all(16), // Tile size
    );
  }
  
  /// Obtiene la posición de spawn del jugador para el capítulo
  Vector2 getPlayerSpawnPosition(int chapter) {
    return _playerSpawns[chapter] ?? Vector2(200, 300);
  }
  
  // Muros manuales para corregir errores de colisión en los mapas (Chapter -> List<Rect>)
  static final Map<int, List<Rect>> _manualWalls = {
    1: [
      // === SALA DE ESTAR - Parches de colisión ===
      
      // Pared vertical IZQUIERDA superior (verde izquierda)
      const Rect.fromLTWH(268, 190, 16, 120),
      
      // Esquina izquierda sobre sofá (verde pequeño izquierda)
      const Rect.fromLTWH(268, 285, 35, 25),
      
      // Pared HORIZONTAL sobre el sofá - COMPLETA (verde horizontal)
      const Rect.fromLTWH(303, 285, 408, 25),
      
      // Pared vertical DERECHA superior (verde derecha)  
      const Rect.fromLTWH(711, 190, 16, 120),
    ],
  };

  /// Carga las colisiones del mapa
  Future<void> loadCollisions(
    TiledComponent map,
    World world,
    int chapter, // Nuevo parámetro
  ) async {
    final collisionLayer = map.tileMap.getLayer<tiled.ObjectGroup>('collisions');
    
    if (collisionLayer != null) {
      for (final obj in collisionLayer.objects) {
        final wall = TiledWall.fromTiledObject(obj);
        await world.add(wall);
      }
    }
    
    // Cargar muros manuales
    final manualWalls = _manualWalls[chapter];
    if (manualWalls != null) {
      print('🧱 Cargando ${manualWalls.length} muros manuales para capítulo $chapter');
      for (final rect in manualWalls) {
        final wall = TiledWall(
          position: Vector2(rect.left, rect.top),
          size: Vector2(rect.width, rect.height),
          hitboxShape: RectangleHitbox(
            size: Vector2(rect.width, rect.height),
          )..collisionType = CollisionType.passive,
        );
        await world.add(wall);
        print('  ✅ Muro agregado: Pos(${rect.left}, ${rect.top}) Size(${rect.width}x${rect.height})');
      }
    } else {
      print('⚠️ No hay muros manuales definidos para capítulo $chapter');
    }
  }
  
  /// Carga las entidades del mapa (enemigos, triggers, NPCs)
  Future<void> loadEntities(
    TiledComponent map,
    World world,
    dynamic game,
  ) async {
    final entitiesLayer = map.tileMap.getLayer<tiled.ObjectGroup>('entities');
    
    if (entitiesLayer != null) {
      for (final obj in entitiesLayer.objects) {
        final type = obj.type;
        
        switch (type) {
          case 'enemy':
            // TODO: Crear enemigo según propiedades
            break;
          case 'trigger':
            // TODO: Crear trigger de diálogo/evento
            break;
          case 'interactable':
            // TODO: Crear objeto interactuable
            break;
        }
      }
    }
  }
}

/// Muro del mapa de Tiled (para colisiones)
class TiledWall extends PositionComponent with CollisionCallbacks {
  TiledWall({
    required Vector2 position,
    required Vector2 size,
    ShapeHitbox? hitboxShape,
  }) : super(position: position, size: size) {
    if (hitboxShape != null) {
      add(hitboxShape);
    }
  }

  factory TiledWall.fromTiledObject(tiled.TiledObject obj) {
    final position = Vector2(obj.x, obj.y);
    ShapeHitbox? hitbox;

    if (obj.isPolygon) {
      final points = obj.polygon.map((p) => Vector2(p.x, p.y)).toList();
      if (points.length >= 3) {
        hitbox = PolygonHitbox(points)..collisionType = CollisionType.passive;
      }
    } else if (obj.isPolyline) {
      final points = obj.polyline.map((p) => Vector2(p.x, p.y)).toList();
      if (points.length >= 3) {
        hitbox = PolygonHitbox(points)..collisionType = CollisionType.passive;
      }
    } else {
      hitbox = RectangleHitbox(
        size: Vector2(obj.width, obj.height),
      )..collisionType = CollisionType.passive;
    }

    return TiledWall(
      position: position,
      size: Vector2(obj.width, obj.height),
      hitboxShape: hitbox,
    );
  }
}
