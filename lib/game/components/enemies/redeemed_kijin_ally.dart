import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../expediente_game.dart';
import '../../systems/resurrection_system.dart';
import '../enemy_tomb.dart';
import 'irracional.dart';
import 'allied_enemy.dart';
import 'yurei_kohaa.dart'; // Añadido para poder atacar a Kohaa

/// Kijin Redimido - Aliado resucitado de categoría Kijin
/// NO expira por tiempo, solo por muerte
/// Más fuerte que aliados normales y con IA mejorada para evitar apilamiento
class RedeemedKijinAlly extends PositionComponent
    with HasGameReference<ExpedienteKorinGame>, CollisionCallbacks {
  
  late final double _maxHealth;
  late double _health;
  late final double _speed;
  late final double _damage;
  late final double _attackRange;
  late final double _attackCooldown;
  double _attackTimer = 0.0;
  
  // Dash attack (habilidad especial)
  final double _dashCooldown = 6.0; // Cooldown de dash
  double _dashTimer = 0.0;
  bool _isDashing = false;
  bool _isPreparingDash = false;
  double _dashPreparationTime = 0.6;
  double _dashPreparationTimer = 0.0;
  double _dashDuration = 0.3;
  double _dashTime = 0.0;
  Vector2 _dashDirection = Vector2.zero();
  final double _dashSpeed = 400.0;
  
  // Espaciamiento con otros aliados
  double _separationRadius = 80.0;
  
  bool _isDead = false;
  PositionComponent? _currentTarget; // Cambiado para aceptar cualquier enemigo
  
  // Referencia al manager de resurrecciones
  final ResurrectionManager? resurrectionManager;
  
  // Tipo de Kijin
  final String kijinType;
  
  // Spawn de enfermeros (a 50% HP)
  bool _hasSpawnedNurses = false;
  
  static const double _size = 35.0; // Más grande que aliados normales
  
  RedeemedKijinAlly({
    required Vector2 position,
    this.resurrectionManager,
    this.kijinType = 'kohaa',
  }) : super(position: position) {
    _configureStats();
  }
  
  /// Configura las estadísticas según el tipo de Kijin
  void _configureStats() {
    switch (kijinType) {
      case 'kohaa':
        _maxHealth = 120.0; // Mucho más resistente
        _health = 120.0;
        _speed = 160.0; // Más rápida
        _damage = 30.0; // Más daño
        _attackRange = 55.0;
        _attackCooldown = 0.8;
        break;
      default:
        _maxHealth = 100.0;
        _health = 100.0;
        _speed = 150.0;
        _damage = 25.0;
        _attackRange = 50.0;
        _attackCooldown = 0.9;
    }
  }
  
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
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (_isDead) return;
    
    // Actualizar timers
    if (_attackTimer > 0) _attackTimer -= dt;
    if (_dashTimer > 0) _dashTimer -= dt;
    
    // Lógica de preparación del dash (INVULNERABLE)
    if (_isPreparingDash) {
      _dashPreparationTimer += dt;
      if (_dashPreparationTimer >= _dashPreparationTime) {
        _isPreparingDash = false;
        _isDashing = true;
        _dashPreparationTimer = 0.0;
        print('⚡ ¡Kijin Redimido EMBISTE!');
      }
      return; // No moverse durante preparación
    }
    
    // Lógica de dash
    if (_isDashing) {
      _dashTime += dt;
      if (_dashTime >= _dashDuration) {
        _isDashing = false;
        _dashTime = 0.0;
      } else {
        position += _dashDirection * _dashSpeed * dt;
        _damageEnemiesInPath();
        return;
      }
    }
    
    // IA mejorada: Buscar y atacar enemigos CON separación
    _findAndAttackEnemies(dt);
  }
  
  void _findAndAttackEnemies(double dt) {
    // Si no tiene objetivo, buscar nuevo
    if (_currentTarget == null || !_isTargetValid()) {
      _findNearestEnemy();
    }
    
    // Si tiene objetivo, perseguirlo y atacar
    if (_currentTarget != null && _isTargetValid()) {
      final distanceToTarget = position.distanceTo(_currentTarget!.position);
      
      // Intentar dash si está listo
      if (_dashTimer <= 0 && distanceToTarget > 100 && distanceToTarget < 300) {
        _executeDash();
        return;
      }
      
      // Acercarse si está lejos
      if (distanceToTarget > _attackRange) {
        Vector2 direction = (_currentTarget!.position - position).normalized();
        
        // NUEVA IA: Aplicar separación con otros aliados
        direction = _applySeparation(direction);
        
        position += direction * _speed * dt;
      } else {
        // Atacar si está en rango
        _tryAttack();
      }
    }
  }
  
  void _executeDash() {
    if (_currentTarget == null) return;
    
    _isPreparingDash = true;
    _dashPreparationTimer = 0.0;
    _dashTime = 0.0;
    _dashTimer = _dashCooldown;
    _dashDirection = (_currentTarget!.position - position).normalized();
    
    print('🛡️ Kijin Redimido prepara dash (invulnerable)');
  }
  
  void _damageEnemiesInPath() {
    final dashDamage = _damage * 2.0; // Doble daño en dash
    const dashRadius = 40.0;
    
    // Dañar irracionales
    final irrationals = game.world.children.query<IrrationalEnemy>();
    for (final enemy in irrationals) {
      if (enemy.isDead) continue;
      final distance = position.distanceTo(enemy.position);
      if (distance <= dashRadius) {
        enemy.takeDamage(dashDamage);
        print('⚡ Dash golpeó irracional: $dashDamage daño');
      }
    }
    
    // Dañar bosses
    final bosses = game.world.children.query<YureiKohaa>();
    for (final boss in bosses) {
      if (boss.isDead) continue;
      final distance = position.distanceTo(boss.position);
      if (distance <= dashRadius) {
        boss.takeDamage(dashDamage);
        print('⚡ Dash golpeó a KOHAA: $dashDamage daño');
      }
    }
  }
  
  bool _isTargetValid() {
    if (_currentTarget == null) return false;
    
    // Verificar si el objetivo sigue vivo según su tipo
    if (_currentTarget is IrrationalEnemy) {
      return !(_currentTarget as IrrationalEnemy).isDead;
    } else if (_currentTarget is YureiKohaa) {
      return !(_currentTarget as YureiKohaa).isDead;
    }
    
    return false;
  }
  
  /// Nueva función para evitar apilamiento con otros aliados
  Vector2 _applySeparation(Vector2 desiredDirection) {
    Vector2 separationForce = Vector2.zero();
    int neighborCount = 0;
    
    // Buscar todos los aliados cercanos
    final allAllies = <PositionComponent>[
      ...game.world.children.query<RedeemedKijinAlly>(),
      ...game.world.children.query<AlliedEnemy>(),
    ];
    
    for (final ally in allAllies) {
      if (ally == this || ally is! PositionComponent) continue;
      
      final distance = position.distanceTo((ally as PositionComponent).position);
      
      if (distance < _separationRadius && distance > 0) {
        // Fuerza de separación inversamente proporcional a la distancia
        final awayDirection = (position - ally.position).normalized();
        final strength = (1.0 - distance / _separationRadius);
        separationForce += awayDirection * strength;
        neighborCount++;
      }
    }
    
    if (neighborCount > 0) {
      separationForce = separationForce / neighborCount.toDouble();
      
      // Mezclar dirección deseada con fuerza de separación (70% objetivo, 30% separación)
      return (desiredDirection * 0.7 + separationForce * 0.3).normalized();
    }
    
    return desiredDirection;
  }
  
  void _findNearestEnemy() {
    // Buscar todos los tipos de enemigos
    final irrationals = game.world.children.query<IrrationalEnemy>();
    final bosses = game.world.children.query<YureiKohaa>();
    
    PositionComponent? nearest;
    double nearestDistance = double.infinity;
    
    // Buscar entre irracionales
    for (final enemy in irrationals) {
      if (enemy.isDead) continue;
      
      final distance = position.distanceTo(enemy.position);
      if (distance < nearestDistance) {
        nearest = enemy;
        nearestDistance = distance;
      }
    }
    
    // Buscar entre bosses
    for (final boss in bosses) {
      if (boss.isDead) continue;
      
      final distance = position.distanceTo(boss.position);
      if (distance < nearestDistance) {
        nearest = boss;
        nearestDistance = distance;
      }
    }
    
    _currentTarget = nearest;
  }
  
  void _tryAttack() {
    if (_attackTimer > 0 || _currentTarget == null) return;
    
    // Atacar según el tipo de enemigo
    if (_currentTarget is IrrationalEnemy) {
      (_currentTarget as IrrationalEnemy).takeDamage(_damage);
      print('⚔️ Kijin Redimido atacó Irracional: $_damage daño');
    } else if (_currentTarget is YureiKohaa) {
      (_currentTarget as YureiKohaa).takeDamage(_damage);
      print('⚔️ Kijin Redimido atacó Kohaa: $_damage daño');
    }
    
    _attackTimer = _attackCooldown;
  }
  
  /// Recibe daño (puede ser atacado por otros enemigos)
  void takeDamage(double damage) {
    if (_isDead) return;
    
    // INVULNERABLE durante preparación del dash
    if (_isPreparingDash) {
      print('🛡️ ¡Kijin Redimido es INVULNERABLE! (Preparando dash)');
      return;
    }
    
    _health -= damage;
    
    // Spawn de enfermeros al 50% HP
    if (!_hasSpawnedNurses && _health <= _maxHealth * 0.5) {
      _spawnNurses();
      _hasSpawnedNurses = true;
      print('🩸 ¡KIJIN REDIMIDO INVOCA ENFERMEROS AL 50% HP!');
    }
    
    if (_health <= 0) {
      _health = 0;
      _die();
    }
  }
  
  void _spawnNurses() {
    print('🩸 ¡Kijin redimido invoca enfermeros para ayudar!');
    
    // Spawn 2 enfermeros ALIADOS
    for (int i = 0; i < 2; i++) {
      final offset = Vector2(
        (i == 0 ? -80 : 80),
        Random().nextDouble() * 60 - 30,
      );
      
      // Crear enfermero como aliado (SIN registrar slots - son parte del Kijin)
      final nurse = AlliedEnemy(
        position: position + offset,
        lifetime: 600.0, // 10 MINUTOS de duración (solo mueren por daño)
        resurrectionManager: null, // NO registrar en manager (son parte del Kijin)
        enemyType: 'irracional', // Usa stats predefinidas
      );
      
      game.world.add(nurse);
      // NO llamar a registerAlly() - los enfermeros son parte del Kijin, no slots separados
      print('👥 Enfermero spawneado (10 min de duración, parte del Kijin)');
    }
  }
  
  /// Muerte del aliado
  void _die() {
    _isDead = true;
    _createTombOnDeath();
    // Liberar 2 slots en el manager (Kijin cuesta 2)
    resurrectionManager?.unregisterKijinAlly();
    removeFromParent();
  }
  
  /// Crea una tumba cuando el aliado muere
  void _createTombOnDeath() {
    final tomb = EnemyTomb(
      position: position.clone(),
      enemyType: 'redeemed_kijin',
      lifetime: 300.0, // 5 MINUTOS - Permite revivir múltiples veces
    );
    game.world.add(tomb);
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Aura púrpura/rosa para indicar que es Kijin redimido
    final auraPaint = Paint()
      ..color = const Color(0xFFFF1493).withOpacity(0.3) // Deep pink
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _size / 2 + 7,
      auraPaint,
    );
    
    // Indicador de preparación de dash (AMARILLO brillante)
    if (_isPreparingDash) {
      final preparePaint = Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      
      canvas.drawCircle(
        (size / 2).toOffset(),
        _size / 2 + 12,
        preparePaint,
      );
      
      // Segundo anillo pulsante
      final pulse = (sin(_dashPreparationTimer * 10) * 0.5 + 0.5);
      final pulsePaint = Paint()
        ..color = Colors.white.withOpacity(pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawCircle(
        (size / 2).toOffset(),
        _size / 2 + 18,
        pulsePaint,
      );
    }
    
    // Indicador de dash activo
    if (_isDashing) {
      final dashPaint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawCircle(
        (size / 2).toOffset(),
        _size / 2 + 10,
        dashPaint,
      );
    }
    
    // Cuerpo del aliado (blanco puro)
    final bodyPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _size / 2,
      bodyPaint,
    );
    
    // Borde rosa brillante
    final borderPaint = Paint()
      ..color = const Color(0xFFFF69B4) // Hot pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _size / 2,
      borderPaint,
    );
    
    // Barra de vida
    _drawHealthBar(canvas);
    
    // Etiqueta "REDIMIDO"
    _drawRedeemedLabel(canvas);
  }
  
  void _drawHealthBar(Canvas canvas) {
    const barWidth = 50.0;
    const barHeight = 5.0;
    final barX = (size.x - barWidth) / 2;
    final barY = -15.0;
    
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
      ..color = const Color(0xFFFF69B4) // Hot pink
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth * healthPercent, barHeight),
      healthPaint,
    );
  }
  
  void _drawRedeemedLabel(Canvas canvas) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'REDIMIDA',
        style: TextStyle(
          color: Color(0xFFFF69B4),
          fontSize: 10,
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
        -28,
      ),
    );
  }
  
  /// Getters
  bool get isDead => _isDead;
  double get health => _health;
}
