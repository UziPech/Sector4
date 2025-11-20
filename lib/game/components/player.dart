import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/palette.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../combat/weapon_system.dart';
import '../../components/character_component.dart'; // Para compatibilidad si se requiere
import '../expediente_game.dart';
import 'tiled_wall.dart'; // Import shared TiledWall

/// Dan - El jugador principal
/// Representa la culpa, vulnerabilidad y determinación del protagonista
class PlayerCharacter extends PositionComponent
    with KeyboardHandler, HasGameReference<ExpedienteKorinGame>, CollisionCallbacks, CharacterComponent {
  
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
  Vector2 lastMoveDirection = Vector2(1, 0); // Dirección por defecto (derecha)
  
  // Sistema de combate
  late final WeaponInventory weaponInventory;
  
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
    
    // Inicializar sistema de armas
    weaponInventory = WeaponInventory();
    add(weaponInventory);
    
    // Agregar armas iniciales
    weaponInventory.addWeapon(MeleeWeapon(
      name: 'Cuchillo del Diente Caótico',
      damage: 100.0,
      cooldown: 0.5,
    ));
    
    weaponInventory.addWeapon(RangedWeapon(
      name: 'Pistola Estándar',
      damage: 20.0,
      maxAmmo: 20,
      cooldown: 0.25,
    ));
    
    // Equipar cuchillo por defecto
    weaponInventory.equipWeapon(0);
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
      lastMoveDirection = _velocity.clone(); // Actualizar dirección de mirada
      _previousPosition = position.clone();
      position += _velocity * _speed * dt;
    }
  }
  
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
      
      // Atacar con Espacio
      if (event.logicalKey == LogicalKeyboardKey.space) {
        _attack();
      }
      
      // Cambiar arma con Q
      if (event.logicalKey == LogicalKeyboardKey.keyQ) {
        weaponInventory.nextWeapon();
        // TODO: Mostrar UI de cambio de arma
        print('Arma equipada: ${weaponInventory.currentWeapon?.name}');
      }
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }
    
    return true;
  }
  
  void _attack() {
    weaponInventory.currentWeapon?.tryAttack(this, game);
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

