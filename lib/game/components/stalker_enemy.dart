import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../expediente_game.dart';
import 'player.dart';

class StalkerEnemy extends PositionComponent with HasGameReference<ExpedienteKorinGame>, CollisionCallbacks {
  // Configuración de sprite
  static const int FRAMES_PER_ROW = 8;
  static const int ROWS = 4;
  static const double STEP_TIME = 0.1;
  
  late SpriteAnimationGroupComponent<StalkerState> _spriteComponent;
  PlayerCharacter? playerToTrack;
  String? obsessionObjectId;
  
  // Stats
  double health = 500.0;
  final double maxHealth = 500.0;
  final double speed = 90.0; // Velocidad amenazante pero evitable
  bool _isInvincible = true;
  
  // Getters
  bool get isInvincible => _isInvincible;
  
  StalkerEnemy() : super(size: Vector2(64, 64), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Hitbox
    add(RectangleHitbox()..collisionType = CollisionType.active);
    
    await _loadAnimations();
  }
  
  Future<void> _loadAnimations() async {
    try {
      print('🔄 Loading Stalker sprite sheet...');
      
      // Cargar sprite sheet
      final data = await rootBundle.load('assets/sprites/Stalker.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      print('📊 Stalker image size: ${image.width}x${image.height}');
      
      final frameWidth = image.width / FRAMES_PER_ROW;
      final frameHeight = image.height / ROWS;
      
      print('📐 Frame size: ${frameWidth}x${frameHeight}');
      
      // Crear sprites manualmente para cada fila
      final List<Sprite> upSprites = [];
      final List<Sprite> downSprites = [];
      final List<Sprite> rightSprites = [];
      final List<Sprite> leftSprites = [];
      
      // Fila 0 (NORTE)
      for (int i = 0; i < FRAMES_PER_ROW; i++) {
        upSprites.add(Sprite(
          image,
          srcPosition: Vector2(i * frameWidth, 0),
          srcSize: Vector2(frameWidth, frameHeight),
        ));
      }
      
      // Fila 1 (SUR)
      for (int i = 0; i < FRAMES_PER_ROW; i++) {
        downSprites.add(Sprite(
          image,
          srcPosition: Vector2(i * frameWidth, frameHeight),
          srcSize: Vector2(frameWidth, frameHeight),
        ));
      }
      
      // Fila 2 (DERECHA)
      for (int i = 0; i < FRAMES_PER_ROW; i++) {
        rightSprites.add(Sprite(
          image,
          srcPosition: Vector2(i * frameWidth, frameHeight * 2),
          srcSize: Vector2(frameWidth, frameHeight),
        ));
      }
      
      // Fila 3 (IZQUIERDA)
      for (int i = 0; i < FRAMES_PER_ROW; i++) {
        leftSprites.add(Sprite(
          image,
          srcPosition: Vector2(i * frameWidth, frameHeight * 3),
          srcSize: Vector2(frameWidth, frameHeight),
        ));
      }
      
      // Crear animaciones
      final walkUp = SpriteAnimation.spriteList(upSprites, stepTime: STEP_TIME);
      final walkDown = SpriteAnimation.spriteList(downSprites, stepTime: STEP_TIME);
      final walkRight = SpriteAnimation.spriteList(rightSprites, stepTime: STEP_TIME);
      final walkLeft = SpriteAnimation.spriteList(leftSprites, stepTime: STEP_TIME);
      
      // Idles (Frame 0 de cada dirección)
      final idleUp = SpriteAnimation.spriteList([upSprites[0]], stepTime: 1, loop: false);
      final idleDown = SpriteAnimation.spriteList([downSprites[0]], stepTime: 1, loop: false);
      final idleRight = SpriteAnimation.spriteList([rightSprites[0]], stepTime: 1, loop: false);
      final idleLeft = SpriteAnimation.spriteList([leftSprites[0]], stepTime: 1, loop: false);
      
      _spriteComponent = SpriteAnimationGroupComponent<StalkerState>(
        animations: {
          StalkerState.idleUp: idleUp,
          StalkerState.idleDown: idleDown,
          StalkerState.idleRight: idleRight,
          StalkerState.idleLeft: idleLeft,
          StalkerState.walkUp: walkUp,
          StalkerState.walkDown: walkDown,
          StalkerState.walkRight: walkRight,
          StalkerState.walkLeft: walkLeft,
        },
        current: StalkerState.idleDown,
        anchor: Anchor.center,
        size: Vector2.all(120), // Tamaño visual grande e imponente
        position: Vector2.zero(), // Posición relativa al padre (centro por el anchor)
      );
      
      add(_spriteComponent);
      print('✅ Stalker sprite loaded successfully!');
      
    } catch (e) {
      print('Error loading Stalker sprites: $e');
    }
  }
  
  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    
    // Debug: Dibujar círculo si no se ha cargado el sprite
    if (!children.contains(_spriteComponent)) {
      canvas.drawCircle(
        (size / 2).toOffset(),
        20,
        ui.Paint()..color = const ui.Color(0xFF550000), // Rojo oscuro si falla sprite
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    _checkInvulnerability();
    _updateMovement(dt);
  }
  
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    
    if (other is PlayerCharacter) {
      // Dañar al jugador al contacto
      other.takeDamage(10.0); // Daño considerable
      
      // Empuje simple (knockback) para evitar daño continuo instantáneo
      final pushDir = (other.position - position).normalized();
      other.position += pushDir * 10.0; 
    }
  }
  
  void _checkInvulnerability() {
    // Si el objeto obsesivo aún existe en el mundo, es invencible
    if (obsessionObjectId != null) {
      // Buscar el objeto por ID (asumiendo que podemos consultar el mundo)
      // Esta es una simplificación, idealmente el ObsessionObject notifica al Stalker
      // Para MVP: Asumimos que ObsessionObject maneja la lógica de notificar o el nivel lo maneja
      // Pero aquí podemos actualizar el estado visual si es necesario
    }
  }
  
  void _updateMovement(double dt) {
    if (playerToTrack == null) return;
    
    final direction = (playerToTrack!.position - position).normalized();
    final velocity = direction * speed;
    
    position += velocity * dt;
    
    // Actualizar animación
    if (velocity.length > 0) {
      if (velocity.y.abs() > velocity.x.abs()) {
        // Movimiento vertical predominante
        if (velocity.y < 0) {
          _spriteComponent.current = StalkerState.walkUp;
        } else {
          _spriteComponent.current = StalkerState.walkDown;
        }
      } else {
        // Movimiento horizontal predominante
        if (velocity.x > 0) {
          _spriteComponent.current = StalkerState.walkRight;
        } else {
          _spriteComponent.current = StalkerState.walkLeft;
        }
      }
    } else {
      // Idle basado en estado anterior (simplificado a idleDown por ahora o mantener último)
      // Para mantener último necesitaríamos guardar estado
    }
  }
  
  void takeDamage(double amount) {
    if (_isInvincible) {
      // Feedback visual de invulnerabilidad (e.g. sonido metálico o escudo)
      return;
    }
    
    health -= amount;
    if (health <= 0) {
      health = 0;
      removeFromParent();
    }
  }
  
  // Llamado por ObsessionObject cuando es destruido
  void onObsessionObjectDestroyed() {
    _isInvincible = false;
    // Cambiar color o efecto para mostrar vulnerabilidad
    _spriteComponent.paint.color = const ui.Color(0xFFFFCCCC); // Tinte rojizo de furia/vulnerabilidad
  }
}

enum StalkerState {
  idleUp, idleDown, idleLeft, idleRight,
  walkUp, walkDown, walkLeft, walkRight
}
