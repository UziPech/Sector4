import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../expediente_game.dart';
import '../player.dart';
import '../enemy_tomb.dart';
import 'yurei_kohaa.dart';

/// Irracional - Enemigo mutado de bajo nivel
/// Ataca cuerpo a cuerpo y puede ser resucitado por Mel
class IrrationalEnemy extends PositionComponent
    with HasGameReference<ExpedienteKorinGame>, CollisionCallbacks {
  
  double _health;
  final double _maxHealth;
  final double _speed;
  final double _damage;
  final double _attackRange = 40.0;
  final double _attackCooldown = 1.5;
  double _attackTimer = 0.0;
  
  bool _isDead = false;
  bool _isStunned = false;
  double _stunTimer = 0.0;
  static const double _stunDuration = 2.0;
  
  // Objetivo actual (puede ser jugador o Kohaa)
  PositionComponent? _currentTarget;
  
  static const double _size = 28.0;

  // Cached TextPainter
  late TextPainter _stunIndicatorPainter;
  
  IrrationalEnemy({
    required Vector2 position,
    double health = 50.0,
    double speed = 100.0,
    double damage = 10.0,
  })  : _health = health,
        _maxHealth = health,
        _speed = speed,
        _damage = damage,
        super(position: position);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(_size);
    anchor = Anchor.center;
    
    // Agregar hitbox
    add(CircleHitbox(
      radius: _size / 2,
      collisionType: CollisionType.passive,
    ));

    // Inicializar painter de stun (estático)
    _stunIndicatorPainter = TextPainter(
      text: const TextSpan(
        text: '★',
        style: TextStyle(
          color: Colors.yellow,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (_isDead) return;
    
    // Actualizar stun
    if (_isStunned) {
      _stunTimer -= dt;
      if (_stunTimer <= 0) {
        _isStunned = false;
      }
      return;
    }
    
    // Actualizar cooldown de ataque
    if (_attackTimer > 0) {
      _attackTimer -= dt;
    }
    
    // IA: Actualizar objetivo y perseguir
    _updateTarget();
    _chaseTarget(dt);
    
    // Intentar atacar si está en rango
    _tryAttack();
  }
  
  /// Actualiza el objetivo (jugador o Kohaa, el más cercano)
  void _updateTarget() {
    final player = game.player;
    
    // Buscar Kohaa
    YureiKohaa? kohaa;
    game.world.children.query<YureiKohaa>().forEach((k) {
      if (!k.isDead) kohaa = k;
    });
    
    // Si no hay Kohaa, atacar al jugador
    if (kohaa == null || kohaa!.isDead) {
      _currentTarget = player;
      return;
    }
    
    // Si hay Kohaa, atacar al más cercano
    final distToPlayer = player.isDead ? double.infinity : position.distanceTo(player.position);
    final distToKohaa = position.distanceTo(kohaa!.position);
    
    _currentTarget = distToKohaa < distToPlayer ? kohaa : player;
  }
  
  void _chaseTarget(double dt) {
    if (_currentTarget == null) return;
    
    final distanceToTarget = position.distanceTo(_currentTarget!.position);
    
    // Si está lejos, acercarse
    if (distanceToTarget > _attackRange) {
      final direction = (_currentTarget!.position - position).normalized();
      position += direction * _speed * dt;
      _constrainToWorldBounds();
    }
  }
  
  /// Restringe la posición a los límites del mundo (con deslizamiento)
  void _constrainToWorldBounds() {
    const double worldMinX = 150.0; // Ajustado para coincidir con paredes
    const double worldMaxX = 2850.0;
    const double worldMinY = 150.0; // Ajustado para coincidir con paredes
    const double worldMaxY = 2850.0;
    
    // Solo aplicar límites, sin modificar velocidad (permite deslizamiento natural)
    position.x = position.x.clamp(worldMinX, worldMaxX);
    position.y = position.y.clamp(worldMinY, worldMaxY);
  }
  
  void _tryAttack() {
    if (_attackTimer > 0 || _currentTarget == null) return;
    
    final distanceToTarget = position.distanceTo(_currentTarget!.position);
    
    // Si está en rango, atacar
    if (distanceToTarget <= _attackRange) {
      _attack(_currentTarget!);
      _attackTimer = _attackCooldown;
    }
  }
  
  void _attack(PositionComponent target) {
    if (target is PlayerCharacter) {
      target.takeDamage(_damage);
      // [PERF] print('⚜️ Irracional atacó al jugador: $_damage daño');
    } else if (target is YureiKohaa) {
      target.takeDamage(_damage);
      // [PERF] print('⚜️ Irracional atacó a Kohaa: $_damage daño');
    }
  }
  
  /// Recibe daño
  void takeDamage(double damage) {
    if (_isDead) return;
    
    _health -= damage;
    
    if (_health <= 0) {
      _health = 0;
      _die();
    } else if (_health < _maxHealth * 0.3) {
      // Si tiene poca vida, puede ser aturdido
      _stun();
    }
  }
  
  /// Aturdir al enemigo
  void _stun() {
    _isStunned = true;
    _stunTimer = _stunDuration;
  }
  
  /// Muerte del enemigo
  void _die() {
    _isDead = true;
    
    // Crear tumba en la posición del enemigo
    final tomb = EnemyTomb(
      position: position.clone(),
      enemyType: 'irracional',
    );
    game.world.add(tomb);
    
    // Remover este enemigo
    removeFromParent();
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Color según estado
    Color enemyColor;
    if (_isStunned) {
      enemyColor = Colors.yellow;
    } else if (_health < _maxHealth * 0.3) {
      enemyColor = Colors.orange;
    } else {
      enemyColor = Colors.red;
    }
    
    // Cuerpo del enemigo (círculo)
    final bodyPaint = Paint()
      ..color = enemyColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _size / 2,
      bodyPaint,
    );
    
    // Borde
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _size / 2,
      borderPaint,
    );
    
    // Barra de vida
    _drawHealthBar(canvas);
    
    // Indicador de stun
    if (_isStunned) {
      _drawStunIndicator(canvas);
    }
  }
  
  void _drawHealthBar(Canvas canvas) {
    const barWidth = 40.0;
    const barHeight = 4.0;
    final barX = (size.x - barWidth) / 2;
    final barY = -10.0;
    
    // Fondo
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      bgPaint,
    );
    
    // Vida
    final healthPercent = (_health / _maxHealth).clamp(0.0, 1.0);
    final healthPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth * healthPercent, barHeight),
      healthPaint,
    );
  }
  
  void _drawStunIndicator(Canvas canvas) {
    _stunIndicatorPainter.paint(
      canvas,
      Offset(
        (size.x - _stunIndicatorPainter.width) / 2,
        -30,
      ),
    );
  }
  
  /// Getters
  bool get isDead => _isDead;
  bool get isStunned => _isStunned;
  double get health => _health;
}
