import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/palette.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../combat/weapon_system.dart';
import '../../combat/mutant_hand_weapon.dart';
import '../../components/character_component.dart'; // Para compatibilidad si se requiere
import '../expediente_game.dart';
import '../models/player_role.dart';
import '../systems/resurrection_system.dart';
import 'enemy_tomb.dart';
import 'enemies/allied_enemy.dart';
import 'tiled_wall.dart'; // Import shared TiledWall

/// Dan/Mel - El jugador principal
/// Representa la culpa, vulnerabilidad y determinación del protagonista
class PlayerCharacter extends PositionComponent
    with KeyboardHandler, HasGameReference<ExpedienteKorinGame>, CollisionCallbacks, CharacterComponent {
  
  static final _paintDan = BasicPalette.green.paint()..style = PaintingStyle.fill;
  static final _paintMel = BasicPalette.cyan.paint()..style = PaintingStyle.fill;
  static const double _size = 32.0;
  
  // Rol del jugador
  final PlayerRole role;
  final RoleStats stats;
  
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
  
  // Regeneración (solo Mel)
  double _regenTimer = 0.0;
  
  // Getters
  double get health => _health;
  double get maxHealth => _maxHealth;
  bool get isDead => _isDead;
  bool get isInvulnerable => _isInvulnerable;
  PlayerRole get playerRole => role;
  
  // Constructor
  PlayerCharacter({PlayerRole? selectedRole})
      : role = selectedRole ?? RoleSelection.currentRole,
        stats = RoleSelection.getStats(selectedRole ?? RoleSelection.currentRole) {
    _maxHealth = stats.maxHealth;
    _health = stats.maxHealth;
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(_size);
    anchor = Anchor.center;
    
    // Agregar hitbox para colisiones
    add(RectangleHitbox()..collisionType = CollisionType.active);
    
    _previousPosition = position.clone();
    
    // Inicializar sistema de armas solo para Dan
    if (stats.hasWeapons) {
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
    } else {
      // Mel tiene la Mano Mutante
      weaponInventory = WeaponInventory();
      add(weaponInventory);
      
      // Agregar Mano Mutante como arma especial
      weaponInventory.addWeapon(MutantHandWeapon(
        name: 'Mano Mutante',
        damage: 40.0,
        cooldown: 0.8,
        lifeStealPercent: 0.3, // 30% de drenaje
        attackRadius: 60.0,
      ));
      
      // Equipar Mano Mutante por defecto
      weaponInventory.equipWeapon(0);
    }
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
    
    // Regeneración (solo Mel)
    if (stats.hasRegeneration && !_isDead) {
      _regenTimer += dt;
      if (_regenTimer >= stats.regenerationInterval) {
        heal(stats.regenerationAmount);
        _regenTimer = 0.0;
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
      position += _velocity * stats.speed * dt;
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
      
      // Resucitar con E (solo Mel)
      if (event.logicalKey == LogicalKeyboardKey.keyE && role == PlayerRole.mel) {
        _tryResurrect();
      }
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }
    
    return true;
  }
  
  void _attack() {
    weaponInventory.currentWeapon?.tryAttack(this, game);
  }
  
  /// Intenta resucitar un enemigo cercano (solo Mel)
  void _tryResurrect() {
    // Buscar resurrection manager
    final resurrectionManager = game.world.children.query<ResurrectionManager>().firstOrNull;
    if (resurrectionManager == null || !resurrectionManager.canResurrect()) {
      return;
    }
    
    // Buscar tumbas cercanas
    final tombs = game.world.children.query<EnemyTomb>();
    EnemyTomb? nearestTomb;
    double nearestDistance = double.infinity;
    
    for (final tomb in tombs) {
      final distance = position.distanceTo(tomb.position);
      if (distance < 60.0 && distance < nearestDistance) {
        nearestTomb = tomb;
        nearestDistance = distance;
      }
    }
    
    // Si hay una tumba cerca, resucitar
    if (nearestTomb != null) {
      _resurrectEnemy(nearestTomb, resurrectionManager);
    }
  }
  
  /// Resucita un enemigo como aliado
  void _resurrectEnemy(EnemyTomb tomb, ResurrectionManager manager) {
    // Consumir resurrección
    manager.useResurrection();
    
    // Crear enemigo aliado en la posición de la tumba
    final ally = AlliedEnemy(
      position: tomb.position.clone(),
      lifetime: 20.0, // 20 segundos de duración
    );
    game.world.add(ally);
    
    // Remover la tumba
    tomb.removeFromParent();
    
    // Crear efecto visual de resurrección
    _createResurrectionEffect(tomb.position);
    
    // Feedback
    debugPrint('Resurrección exitosa! Resurrecciones restantes: ${manager.resurrectionsRemaining}');
  }
  
  /// Crea efecto visual de resurrección
  void _createResurrectionEffect(Vector2 position) {
    final effect = _ResurrectionEffect(position: position.clone());
    game.world.add(effect);
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
    
    // Dibujar círculo del jugador (color según rol)
    final paint = role == PlayerRole.dan ? _paintDan : _paintMel;
    canvas.drawCircle(
      (size / 2).toOffset(),
      _size / 2,
      paint,
    );
    
    // Efecto visual de regeneración para Mel
    if (stats.hasRegeneration && _regenTimer > 0) {
      final regenProgress = _regenTimer / stats.regenerationInterval;
      final regenPaint = Paint()
        ..color = Colors.green.withOpacity(0.3 * regenProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawCircle(
        (size / 2).toOffset(),
        (_size / 2) + 5,
        regenPaint,
      );
    }
  }
}

/// Efecto visual de resurrección
class _ResurrectionEffect extends PositionComponent {
  double _lifetime = 1.0;
  double _timer = 0.0;
  
  _ResurrectionEffect({required Vector2 position})
      : super(position: position, size: Vector2.all(120), anchor: Anchor.center);
  
  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    
    if (_timer >= _lifetime) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final progress = _timer / _lifetime;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    
    // Círculos expansivos verdes
    for (int i = 0; i < 3; i++) {
      final delay = i * 0.2;
      final adjustedProgress = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      final radius = 20.0 + (adjustedProgress * 40.0);
      
      final paint = Paint()
        ..color = Colors.green.withOpacity(opacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      
      canvas.drawCircle(
        (size / 2).toOffset(),
        radius,
        paint,
      );
    }
    
    // Partículas ascendentes
    final particlePaint = Paint()
      ..color = Colors.green.withOpacity(opacity * 0.8)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * pi * 2;
      final distance = progress * 30.0;
      final x = (size.x / 2) + (distance * cos(angle));
      final y = (size.y / 2) - (progress * 40.0) + (distance * sin(angle));
      
      canvas.drawCircle(
        Offset(x, y),
        5.0 * (1.0 - progress),
        particlePaint,
      );
    }
    
    // Texto "RESURRECCIÓN"
    if (progress < 0.7) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'RESURRECCIÓN',
          style: TextStyle(
            color: Colors.green.withOpacity(opacity),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.x - textPainter.width) / 2,
          -40.0 - (progress * 20.0),
        ),
      );
    }
  }
  
  @override
  int get priority => 100;
}

