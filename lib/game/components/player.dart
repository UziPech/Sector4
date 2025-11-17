import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/palette.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../expediente_game.dart';

/// Dan - El jugador principal
/// Representa la culpa, vulnerabilidad y determinación del protagonista
class PlayerCharacter extends PositionComponent
    with KeyboardHandler, HasGameReference<ExpedienteKorinGame>, CollisionCallbacks {
  
  static final _paint = BasicPalette.green.paint()..style = PaintingStyle.fill;
  static const double _size = 32.0;
  static const double _speed = 200.0;
  
  // Estado del personaje
  double _health = 100.0;
  double _maxHealth = 100.0;
  bool _isDead = false;
  
  // Movimiento
  final Vector2 _velocity = Vector2.zero();
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  Vector2 _previousPosition = Vector2.zero();
  
  // Sistema de disparo
  bool _canShoot = true;
  static const double _shootCooldown = 0.25;
  double _timeSinceLastShot = 0.0;
  
  // Invencibilidad temporal (al recibir daño)
  bool _isInvulnerable = false;
  double _invulnerabilityTimer = 0.0;
  static const double _invulnerabilityDuration = 1.0;
  
  // Getters
  double get health => _health;
  double get maxHealth => _maxHealth;
  bool get isDead => _isDead;
  bool get isInvulnerable => _isInvulnerable;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(_size);
    anchor = Anchor.center;
    
    // Agregar hitbox para colisiones
    add(RectangleHitbox()..collisionType = CollisionType.active);
    
    _previousPosition = position.clone();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (_isDead) return;
    
    // Actualizar invencibilidad
    if (_isInvulnerable) {
      _invulnerabilityTimer -= dt;
      if (_invulnerabilityTimer <= 0) {
        _isInvulnerable = false;
      }
    }
    
    // Actualizar cooldown de disparo
    if (!_canShoot) {
      _timeSinceLastShot += dt;
      if (_timeSinceLastShot >= _shootCooldown) {
        _canShoot = true;
        _timeSinceLastShot = 0.0;
      }
    }
    
    // Movimiento
    _updateMovement(dt);
  }
  
  void _updateMovement(double dt) {
    _velocity.setZero();
    
    // Procesar teclas presionadas
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      _velocity.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      _velocity.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      _velocity.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      _velocity.x += 1;
    }
    
    // Normalizar y aplicar velocidad
    if (_velocity.length > 0) {
      _velocity.normalize();
      _previousPosition = position.clone();
      position += _velocity * _speed * dt;
    }
  }
  
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
      
      // Disparar con Espacio
      if (event.logicalKey == LogicalKeyboardKey.space && _canShoot) {
        _shoot();
      }
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }
    
    return true;
  }
  
  void _shoot() {
    // TODO: Implementar sistema de disparo
    _canShoot = false;
    _timeSinceLastShot = 0.0;
  }
  
  /// Recibe daño
  void takeDamage(double damage) {
    if (_isDead || _isInvulnerable) return;
    
    _health -= damage;
    _isInvulnerable = true;
    _invulnerabilityTimer = _invulnerabilityDuration;
    
    if (_health <= 0) {
      _health = 0;
      _die();
    }
  }
  
  /// Cura al jugador
  void heal(double amount) {
    if (_isDead) return;
    
    _health = (_health + amount).clamp(0, _maxHealth);
  }
  
  /// Muerte del jugador
  void _die() {
    _isDead = true;
    game.gameOver();
  }
  
  /// Reinicia el estado del jugador
  void resetHealth() {
    _health = _maxHealth;
    _isDead = false;
    _isInvulnerable = false;
    _invulnerabilityTimer = 0.0;
  }
  
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    
    // Colisión con paredes - retroceder
    if (other is TiledWall) {
      position = _previousPosition.clone();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Efecto de parpadeo cuando es invulnerable
    if (_isInvulnerable && (_invulnerabilityTimer * 10).toInt() % 2 == 0) {
      return; // No renderizar (parpadeo)
    }
    
    // Dibujar círculo del jugador
    canvas.drawCircle(
      (size / 2).toOffset(),
      _size / 2,
      _paint,
    );
  }
}

// Importar TiledWall para las colisiones
class TiledWall extends PositionComponent {}
