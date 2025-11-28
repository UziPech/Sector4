import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../expediente_game.dart';
import '../player.dart';
import '../enemy_tomb.dart';
import 'allied_enemy.dart';
import 'redeemed_kijin_ally.dart';
import 'irracional.dart';
import '../bosses/on_oyabun_boss.dart';

/// Yurei Kohaa - Jefe Kijin (Categoría 2)
/// La Novia Escarlata - Un enemigo táctico y peligroso
class YureiKohaa extends PositionComponent
    with HasGameReference<ExpedienteKorinGame>, CollisionCallbacks {
  
  double _health;
  final double _maxHealth = 3000.0; // ¡10x más resistente!
  final double _speed = 150.0;
  final double _damage = 25.0;
  final double _attackRange = 50.0;
  final double _attackCooldown = 1.2;
  double _attackTimer = 0.0;
  
  // Dash attack (MÁS FRECUENTE)
  final double _dashCooldown = 4.0; // Reducido de 5s a 4s
  double _dashTimer = 0.0;
  bool _isDashing = false;
  bool _isPreparingDash = false; // Nueva: preparación antes del dash
  double _dashPreparationTime = 0.8; // Tiempo de preparación (INVULNERABLE)
  double _dashPreparationTimer = 0.0;
  double _dashDuration = 0.4; // Duración más larga
  double _dashTime = 0.0;
  Vector2 _dashDirection = Vector2.zero();
  final double _dashSpeed = 500.0; // Más rápido
  
  // Explosión defensiva (NUEVA HABILIDAD)
  final double _defensiveExplosionCooldown = 12.0; // Cooldown de 12 segundos
  double _defensiveExplosionTimer = 0.0;
  bool _canUseDefensiveExplosion = true;
  final double _defensiveExplosionThreshold = 0.3; // 30% HP
  
  // Regeneración de vida
  bool _canRegenerate = true;
  double _regenerationCooldown = 15.0;
  double _regenerationTimer = 0.0;
  
  // Sistema de huida cuando tiene poca vida
  bool _isFleeing = false;
  final double _fleeHealthThreshold = 0.15; // 15% HP (solo huye en emergencia)
  final double _fleeDistance = 300.0; // Distancia de huida
  double _fleeTimer = 0.0; // Timer para evitar huir indefinidamente
  final double _maxFleeTime = 4.0; // Máximo 4s huyendo antes de volver
  Vector2? _fleeTargetPosition; // Posición objetivo al huir
  int _fleeCount = 0; // Contador de veces que ha huido
  final int _maxFleeCount = 2; // Máximo 2 huidas por combate
  
  // Sistema de curación cuando está segura
  double _healingTimer = 0.0;
  final double _healingInterval = 3.0; // Curar cada 3s (más lento)
  final double _healingAmount = 30.0; // 30 HP por tick (reducido)
  final double _safeDistance = 250.0; // Distancia segura del peligro
  double _totalHealingReceived = 0.0; // Total curado
  final double _maxTotalHealing = 300.0; // Máximo 300 HP de curación total
  
  // Spawn de enfermeros (a 50% HP)
  bool _hasSpawnedNurses = false;
  
  bool _isDead = false;
  PositionComponent? _currentTarget;
  
  static const double _size = 40.0;
  
  // Sistema de sprites
  SpriteAnimationComponent? _spriteComponent;
  late SpriteAnimation _idleAnimation;
  late SpriteAnimation _walkAnimation;
  
  YureiKohaa({
    required Vector2 position,
  })  : _health = 3000.0, // HP inicial MUY ALTO
        super(position: position);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(_size);
    anchor = Anchor.center;
    
    // Cargar spritesheet de Yurei Kohaa
    await _loadSprites();
    
    // Agregar hitbox
    add(CircleHitbox(
      radius: _size / 2,
      collisionType: CollisionType.passive,
    ));
  }
  
  /// Carga el spritesheet y configura las animaciones
  Future<void> _loadSprites() async {
    try {
      print('🔍 [Kohaa] Intentando cargar sprites...');
      final spriteSheet = await game.images.load('sprites/Yurei_kohaaSpritesComplete.png');
      print('🔍 [Kohaa] SpriteSheet cargado: ${spriteSheet.width}x${spriteSheet.height}');
      
      // Configuración del spritesheet
      // Dimensiones confirmadas: 672x420px = 8x5 frames de 84x84px
      const frameWidth = 84.0;
      const frameHeight = 84.0;
      const framesPerRow = 8;
      
      // Animación idle (primera fila)
      _idleAnimation = SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: framesPerRow,
          stepTime: 0.15,
          textureSize: Vector2(frameWidth, frameHeight),
          texturePosition: Vector2.zero(),
        ),
      );
      
      // Animación walk (segunda fila)
      _walkAnimation = SpriteAnimation.fromFrameData(
        spriteSheet,
        SpriteAnimationData.sequenced(
          amount: framesPerRow,
          stepTime: 0.1,
          textureSize: Vector2(frameWidth, frameHeight),
          texturePosition: Vector2(0, frameHeight),
        ),
      );
      
      // Crear componente de sprite con escala alta (mantener visual grande)
      _spriteComponent = SpriteAnimationComponent(
        animation: _idleAnimation,
        size: Vector2.all(_size * 1.3), // Escalar el component, no el texture
        anchor: Anchor.center,
      );
      
      add(_spriteComponent!);
      print('🎉 [Kohaa] Sprite component agregado exitosamente');
      
      debugPrint('✅ Sprites de Yurei Kohaa cargados exitosamente');
    } catch (e, stackTrace) {
      debugPrint('⚠️ Error cargando sprites de Yurei Kohaa: $e');
      debugPrint('   Stack trace: $stackTrace');
      debugPrint('   Usando fallback a renderizado circular');
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (_isDead) return;
    
    // Actualizar animación de sprites según estado
    if (_spriteComponent != null) {
      // Determinar animación según velocidad
      final velocity = _isDashing ? _dashDirection * _dashSpeed : 
                      (_currentTarget != null && position.distanceTo(_currentTarget!.position) > _attackRange)
                      ? (_currentTarget!.position - position).normalized() * _speed
                      : Vector2.zero();
      
      if (velocity.length > 10) {
        _spriteComponent!.animation = _walkAnimation;
      } else {
        _spriteComponent!.animation = _idleAnimation;
      }
    }
    
    // Actualizar timers
    if (_attackTimer > 0) _attackTimer -= dt;
    if (_dashTimer > 0) _dashTimer -= dt;
    if (_defensiveExplosionTimer > 0) {
      _defensiveExplosionTimer -= dt;
      if (_defensiveExplosionTimer <= 0) {
        _canUseDefensiveExplosion = true;
      }
    }
    
    // Lógica de preparación del dash (INVULNERABLE)
    if (_isPreparingDash) {
      _dashPreparationTimer += dt;
      if (_dashPreparationTimer >= _dashPreparationTime) {
        // Terminar preparación, ejecutar dash
        _isPreparingDash = false;
        _isDashing = true;
        _dashPreparationTimer = 0.0;
        print('⚡ ¡Kohaa EMBISTE con furia!');
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
        // Moverse en la dirección del dash
        final newPos = position + (_dashDirection * _dashSpeed * dt);
        
        // Aplicar límites estrictos durante dash
        const double worldMinX = 150.0;
        const double worldMaxX = 2850.0;
        const double worldMinY = 150.0;
        const double worldMaxY = 2850.0;
        
        position.x = newPos.x.clamp(worldMinX, worldMaxX);
        position.y = newPos.y.clamp(worldMinY, worldMaxY);
        return; // No hacer IA normal durante el dash
      }
    }
    
    // Regeneración gradual
    if (_regenerationTimer > 0) {
      _regenerationTimer -= dt;
    }
    
    // Sistema de curación cuando está segura
    _updateHealing(dt);
    
    // IA: Decidir objetivo y atacar (o huir)
    _updateAI(dt);
  }
  
  void _updateAI(double dt) {
    // Actualizar objetivo (70% Dan, 30% Mel o aliados)
    if (_currentTarget == null || _targetIsDead()) {
      _findTarget();
    }
    
    if (_currentTarget == null) return;
    
    final distanceToTarget = position.distanceTo(_currentTarget!.position);
    final healthPercent = _health / _maxHealth;
    
    // COMPORTAMIENTO DE HUIDA cuando tiene poca vida
    // EXCEPTO si está luchando contra el boss final O si ya huyó muchas veces
    if (healthPercent <= _fleeHealthThreshold && !_isFleeing) {
      // NO huir si el objetivo es el boss final
      if (_currentTarget is OnOyabunBoss) {
        print('⚔️ Kohaa está baja de vida pero NO huye del boss (${(healthPercent * 100).toInt()}% HP)');
      }
      // NO huir si ya alcanzó el límite de huidas
      else if (_fleeCount >= _maxFleeCount) {
        print('🚫 Kohaa NO puede huir más ($_fleeCount/$_maxFleeCount huidas usadas) - ${(healthPercent * 100).toInt()}% HP');
      }
      // Huir solo si aún tiene huidas disponibles
      else {
        _isFleeing = true;
        _fleeTimer = 0.0;
        _fleeCount++;
        _fleeTargetPosition = null; // Resetear posición objetivo
        print('🏃 ¡Kohaa está huyendo! ($_fleeCount/$_maxFleeCount huidas) (${(healthPercent * 100).toInt()}% HP)');
      }
    }
    
    // Dejar de huir cuando se recupera O cuando pasa mucho tiempo
    if (_isFleeing) {
      _fleeTimer += dt;
      
      // Condiciones para dejar de huir:
      // 1. Se recuperó suficiente HP
      // 2. Pasó el tiempo máximo de huida
      if (healthPercent > _fleeHealthThreshold + 0.15 || _fleeTimer >= _maxFleeTime) {
        _isFleeing = false;
        _fleeTargetPosition = null;
        _fleeTimer = 0.0;
        print('⚔️ Kohaa vuelve al combate (${(healthPercent * 100).toInt()}% HP) - Huidas restantes: ${_maxFleeCount - _fleeCount}');
      }
    }
    
    // Si está huyendo, usar lógica inteligente
    if (_isFleeing) {
      _updateFleeingBehavior(dt, distanceToTarget);
      return;
    }
    
    // COMPORTAMIENTO NORMAL: Atacar
    // Intentar dash si está listo (RANGO MÁS AMPLIO)
    if (_dashTimer <= 0 && distanceToTarget > 80 && distanceToTarget < 400) {
      _executeDash();
      return;
    }
    
    // Moverse hacia el objetivo
    if (distanceToTarget > _attackRange) {
      final direction = (_currentTarget!.position - position).normalized();
      final newPos = position + (direction * _speed * dt);
      
      // Aplicar límites estrictos
      const double worldMinX = 150.0;
      const double worldMaxX = 2850.0;
      const double worldMinY = 150.0;
      const double worldMaxY = 2850.0;
      
      position.x = newPos.x.clamp(worldMinX, worldMaxX);
      position.y = newPos.y.clamp(worldMinY, worldMaxY);
    } else {
      // Atacar si está en rango
      _tryAttack();
    }
  }
  
  /// Comportamiento inteligente de huida (evita esquinas, busca posiciones seguras)
  void _updateFleeingBehavior(double dt, double distanceToTarget) {
    if (_currentTarget == null) return;
    
    // DESHABILITAR HUIDA si está luchando contra el boss final
    // Esto la hace mortal y evita que sea invencible
    if (_currentTarget is OnOyabunBoss) {
      _isFleeing = false;
      _fleeTimer = 0.0;
      print('⚠️ Kohaa NO puede huir del boss final - ¡Lucha hasta la muerte!');
      return;
    }
    
    // Si no tenemos posición objetivo o estamos cerca de ella, calcular nueva
    if (_fleeTargetPosition == null || position.distanceTo(_fleeTargetPosition!) < 50) {
      _fleeTargetPosition = _calculateSafeFleePosition();
    }
    
    // Si estamos lo suficientemente lejos, quedarnos quietos y curar
    if (distanceToTarget >= _fleeDistance) {
      // Quieta, curándose
      _constrainToWorldBounds(); // Asegurar que está dentro de límites
      return;
    }
    
    // Moverse hacia la posición segura
    if (_fleeTargetPosition != null) {
      final direction = (_fleeTargetPosition! - position).normalized();
      final newPos = position + (direction * _speed * dt * 1.3); // 30% más rápido al huir
      
      // Aplicar límites ANTES de mover
      const double worldMinX = 150.0;
      const double worldMaxX = 2850.0;
      const double worldMinY = 150.0;
      const double worldMaxY = 2850.0;
      
      position.x = newPos.x.clamp(worldMinX, worldMaxX);
      position.y = newPos.y.clamp(worldMinY, worldMaxY);
    }
  }
  
  /// Calcula una posición segura para huir (evita esquinas y bordes)
  Vector2 _calculateSafeFleePosition() {
    if (_currentTarget == null) return position.clone();
    
    // Centro del mapa (posición más segura)
    const double centerX = 1500.0;
    const double centerY = 1500.0;
    final mapCenter = Vector2(centerX, centerY);
    
    // Vector desde el peligro hacia nosotros
    final awayFromThreat = (position - _currentTarget!.position).normalized();
    
    // Posición ideal: lejos del peligro pero cerca del centro
    final idealPosition = _currentTarget!.position + (awayFromThreat * _fleeDistance);
    
    // Interpolar entre posición ideal y centro del mapa
    // Esto evita que se vaya a las esquinas
    final safePosition = idealPosition * 0.6 + mapCenter * 0.4;
    
    // Asegurar que está dentro de límites
    return Vector2(
      safePosition.x.clamp(200.0, 2800.0),
      safePosition.y.clamp(200.0, 2800.0),
    );
  }
  
  /// Sistema de curación cuando está segura (con límite total)
  void _updateHealing(double dt) {
    if (_isDead) return;
    
    // Solo curar si está huyendo o lejos del peligro
    bool isSafe = false;
    
    if (_isFleeing && _currentTarget != null) {
      final distanceToThreat = position.distanceTo(_currentTarget!.position);
      isSafe = distanceToThreat >= _safeDistance;
    }
    
    if (isSafe) {
      _healingTimer += dt;
      
      if (_healingTimer >= _healingInterval) {
        // Verificar si aún puede curarse (límite total)
        if (_totalHealingReceived >= _maxTotalHealing) {
          print('🚫 Kohaa alcanzó el límite de curación (${_totalHealingReceived.toInt()}/${_maxTotalHealing.toInt()} HP)');
          _healingTimer = 0.0;
          return;
        }
        
        final oldHealth = _health;
        final healAmount = _healingAmount.clamp(0.0, _maxTotalHealing - _totalHealingReceived);
        _health = (_health + healAmount).clamp(0.0, _maxHealth);
        final healed = _health - oldHealth;
        
        if (healed > 0) {
          _totalHealingReceived += healed;
          final remaining = _maxTotalHealing - _totalHealingReceived;
          print('💚 Kohaa se cura ${healed.toStringAsFixed(0)} HP (${_health.toStringAsFixed(0)}/${_maxHealth}) - Curación restante: ${remaining.toInt()} HP');
        }
        
        _healingTimer = 0.0;
      }
    } else {
      _healingTimer = 0.0; // Resetear timer si no está segura
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
  
  void _findTarget() {
    final player = game.player;
    final random = Random();
    
    // Buscar al boss final
    OnOyabunBoss? boss;
    game.world.children.query<OnOyabunBoss>().forEach((b) {
      if (!b.isDead) boss = b;
    });
    
    // Si existe el boss final, PRIORIDAD MÁXIMA (90% chance - más agresiva)
    if (boss != null && !boss!.isDead && random.nextDouble() < 0.9) {
      _currentTarget = boss;
      if (_currentTarget != boss) { // Solo imprimir cuando cambia de objetivo
        print('🔥 Kohaa ha detectado al boss final - OBJETIVO PRIORITARIO');
      }
      return;
    }
    
    // 60% perseguir a Dan, 40% a aliados
    if (random.nextDouble() < 0.6) {
      // Perseguir a Dan
      _currentTarget = player;
    } else {
      // Buscar aliados (normales o Kijin)
      final normalAllies = game.world.children.query<AlliedEnemy>();
      final kijinAllies = game.world.children.query<RedeemedKijinAlly>();
      
      final allAllies = <PositionComponent>[...normalAllies, ...kijinAllies];
      
      if (allAllies.isNotEmpty) {
        _currentTarget = allAllies[random.nextInt(allAllies.length)];
      } else {
        _currentTarget = player; // Fallback a Dan
      }
    }
  }
  
  bool _targetIsDead() {
    if (_currentTarget is PlayerCharacter) {
      return (_currentTarget as PlayerCharacter).isDead;
    } else if (_currentTarget is AlliedEnemy) {
      return (_currentTarget as AlliedEnemy).isDead;
    } else if (_currentTarget is RedeemedKijinAlly) {
      return (_currentTarget as RedeemedKijinAlly).isDead;
    } else if (_currentTarget is OnOyabunBoss) {
      return (_currentTarget as OnOyabunBoss).isDead;
    }
    return true;
  }
  
  void _executeDash() {
    if (_currentTarget == null) return;
    
    // Iniciar PREPARACIÓN (fase invulnerable)
    _isPreparingDash = true;
    _dashPreparationTimer = 0.0;
    _dashTime = 0.0;
    _dashTimer = _dashCooldown;
    _dashDirection = (_currentTarget!.position - position).normalized();
    
    print('🛡️ ¡Kohaa se vuelve INVULNERABLE y prepara su embestida!');
  }
  
  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    
    // Solo hacer daño durante el dash
    if (!_isDashing) return;
    
    const double dashDamage = 50.0; // Daño del dash
    
    // Colisión con jugador
    if (other is PlayerCharacter) {
      other.takeDamage(dashDamage);
      print('💥 ¡Dash de Kohaa impactó al jugador! $dashDamage daño');
    }
    // Colisión con aliados normales
    else if (other is AlliedEnemy) {
      other.takeDamage(dashDamage);
      print('💥 ¡Dash de Kohaa impactó a aliado! $dashDamage daño');
    }
    // Colisión con aliados Kijin
    else if (other is RedeemedKijinAlly) {
      other.takeDamage(dashDamage);
      print('💥 ¡Dash de Kohaa impactó a Kijin aliado! $dashDamage daño');
    }
    // Colisión con el boss final
    else if (other is OnOyabunBoss) {
      other.takeDamage(dashDamage);
      print('🔥💥 ¡DASH DE KOHAA IMPACTÓ AL BOSS FINAL! $dashDamage daño');
    }
  }
  
  void _tryAttack() {
    if (_attackTimer > 0 || _currentTarget == null) return;
    
    final distanceToTarget = position.distanceTo(_currentTarget!.position);
    if (distanceToTarget <= _attackRange) {
      _attack(_currentTarget!);
      _attackTimer = _attackCooldown;
    }
  }
  
  void _attack(PositionComponent target) {
    if (target is PlayerCharacter) {
      target.takeDamage(_damage);
      print('⚔️ Kohaa atacó al jugador: $_damage daño');
    } else if (target is AlliedEnemy) {
      target.takeDamage(_damage);
      print('⚔️ Kohaa atacó a aliado normal: $_damage daño');
    } else if (target is RedeemedKijinAlly) {
      target.takeDamage(_damage);
      print('⚔️ Kohaa atacó a Kijin aliado: $_damage daño');
    } else if (target is OnOyabunBoss) {
      target.takeDamage(_damage);
      print('🔥⚔️🔥 ¡KOHAA ATACÓ AL BOSS FINAL! ($_damage daño)');
    }
  }
  
  /// Recibe daño
  void takeDamage(double damage) {
    if (_isDead) return;
    
    // INVULNERABLE durante preparación del dash
    if (_isPreparingDash) {
      print('🛡️ ¡Kohaa es INVULNERABLE! (Preparando dash)');
      return;
    }
    
    _health -= damage;
    print('💥 Kohaa recibió $damage de daño! (${_health.toStringAsFixed(0)}/${_maxHealth} HP)');
    
    // NUEVA: Explosión defensiva cuando está baja de vida
    final healthPercent = _health / _maxHealth;
    if (healthPercent <= _defensiveExplosionThreshold && _canUseDefensiveExplosion) {
      _executeDefensiveExplosion();
      _canUseDefensiveExplosion = false;
      _defensiveExplosionTimer = _defensiveExplosionCooldown;
    }
    
    // Spawn de enfermeros a 60% HP (MÁS TEMPRANO)
    if (!_hasSpawnedNurses && _health <= _maxHealth * 0.6) {
      _spawnNurses();
      _hasSpawnedNurses = true;
      print('🩸 ¡KOHAA SPAWNEÓ ENFERMEROS AL 60% HP!');
    }
    
    if (_health <= 0) {
      _health = 0;
      _die();
    }
  }
  
  /// NUEVA HABILIDAD: Explosión Defensiva
  /// Se activa cuando Kohaa está baja de vida (< 30%)
  void _executeDefensiveExplosion() {
    const double explosionRadius = 250.0;
    const double explosionDamage = 40.0;
    const double pushForce = 450.0;
    const double healAmount = 100.0;
    
    print('💥🔴 ¡KOHAA USA EXPLOSIÓN DEFENSIVA! Se cura $healAmount HP');
    
    // CURARSE
    _health = (_health + healAmount).clamp(0.0, _maxHealth);
    print('💚 Kohaa se curó a ${_health.toStringAsFixed(0)}/${_maxHealth} HP');
    
    // Dañar y empujar al jugador
    final player = game.player;
    final distToPlayer = position.distanceTo(player.position);
    if (distToPlayer <= explosionRadius) {
      player.takeDamage(explosionDamage);
      // EMPUJAR FUERTEMENTE
      final pushDirection = (player.position - position).normalized();
      player.position += pushDirection * pushForce * 0.15;
      print('💥 ¡Jugador recibió $explosionDamage daño y fue EMPUJADO!');
    }
    
    // Dañar y empujar aliados normales
    final normalAllies = game.world.children.query<AlliedEnemy>();
    for (final ally in normalAllies) {
      if (ally.isDead) continue;
      final distToAlly = position.distanceTo(ally.position);
      if (distToAlly <= explosionRadius) {
        ally.takeDamage(explosionDamage);
        final pushDirection = (ally.position - position).normalized();
        ally.position += pushDirection * pushForce * 0.2;
      }
    }
    
    // Dañar y empujar aliados Kijin
    final kijinAllies = game.world.children.query<RedeemedKijinAlly>();
    for (final ally in kijinAllies) {
      if (ally.isDead) continue;
      final distToAlly = position.distanceTo(ally.position);
      if (distToAlly <= explosionRadius) {
        ally.takeDamage(explosionDamage);
        final pushDirection = (ally.position - position).normalized();
        ally.position += pushDirection * pushForce * 0.2;
      }
    }
  }
  
  void _spawnNurses() {
    print('🩸 ¡CAMBIO DE FASE! Kohaa invoca enfermeros!');
    
    // ===== ATAQUE AOE DE FASE =====
    _executePhaseTransitionAOE();
    
    // REGENERAR VIDA al spawn de enfermeros (25% de HP max)
    final healAmount = _maxHealth * 0.25;
    _health = (_health + healAmount).clamp(0.0, _maxHealth);
    print('💚 ¡Kohaa se curó ${healAmount.toStringAsFixed(0)} HP! (${_health.toStringAsFixed(0)}/${_maxHealth})');
    
    // Spawn 2 enfermeros
    for (int i = 0; i < 2; i++) {
      final offset = Vector2(
        (i == 0 ? -80 : 80),
        Random().nextDouble() * 60 - 30,
      );
      
      final nurse = IrrationalEnemy(
        position: position + offset,
        health: 30.0,
        speed: 110.0,
        damage: 8.0,
      );
      
      game.world.add(nurse);
    }
  }
  
  /// Ataque AOE al cambiar de fase - Daña y empuja
  void _executePhaseTransitionAOE() {
    const double aoeRadius = 200.0;
    const double aoeDamage = 30.0;
    const double pushForce = 300.0;
    
    print('💥💥 ¡EXPLOSIÓN DE FASE! Radio: $aoeRadius');
    
    // Dañar jugador si está cerca
    final player = game.player;
    final distToPlayer = position.distanceTo(player.position);
    if (distToPlayer <= aoeRadius) {
      player.takeDamage(aoeDamage);
      // Empujar jugador
      final pushDirection = (player.position - position).normalized();
      player.position += pushDirection * pushForce * 0.1; // Pequeño empuje
      print('💥 Jugador recibió $aoeDamage daño y fue empujado!');
    }
    
    // Dañar TODOS los aliados cercanos
    final normalAllies = game.world.children.query<AlliedEnemy>();
    for (final ally in normalAllies) {
      if (ally.isDead) continue;
      final distToAlly = position.distanceTo(ally.position);
      if (distToAlly <= aoeRadius) {
        ally.takeDamage(aoeDamage);
        // Empujar aliado
        final pushDirection = (ally.position - position).normalized();
        ally.position += pushDirection * pushForce * 0.15;
        print('💥 Aliado normal recibió $aoeDamage daño y fue empujado!');
      }
    }
    
    // Dañar aliados Kijin cercanos
    final kijinAllies = game.world.children.query<RedeemedKijinAlly>();
    for (final ally in kijinAllies) {
      if (ally.isDead) continue;
      final distToAlly = position.distanceTo(ally.position);
      if (distToAlly <= aoeRadius) {
        ally.takeDamage(aoeDamage);
        // Empujar aliado Kijin
        final pushDirection = (ally.position - position).normalized();
        ally.position += pushDirection * pushForce * 0.15;
        print('💥 Kijin aliado recibió $aoeDamage daño y fue empujado!');
      }
    }
  }
  
  /// Recuperar vida al reintentar (recarga entre muertes del jugador)
  void recoverHealthOnRetry(double amount) {
    if (_isDead) return; // No recuperar si ya murió
    
    _health = (_health + amount).clamp(0.0, _maxHealth);
    print('💚 Kohaa recuperó $amount HP! Ahora tiene ${_health.toStringAsFixed(0)}/$_maxHealth HP');
  }
  
  /// Muerte de Kohaa
  void _die() {
    _isDead = true;
    
    print('GAME MESSAGE: Kohaa ha sido derrotada...');
    
    // Crear tumba especial ROJA para Kijin
    final tomb = EnemyTomb(
      position: position.clone(),
      enemyType: 'kijin_kohaa',
      lifetime: 10.0, // Mas tiempo que irracionales
    );
    game.world.add(tomb);
    
    // Remover este enemigo
    removeFromParent();
  }
  
  
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Aura roja para Kijin (MANTENER)
    final auraPaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      _size / 2 + 8,
      auraPaint,
    );
    
    // FALLBACK: Si sprites no cargaron, dibujar círculo
    if (_spriteComponent == null) {
      // Cuerpo de Kohaa (rojo oscuro) - FALLBACK
      final bodyPaint = Paint()
        ..color = const Color(0xFF8B0000).withOpacity(0.9)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        (size / 2).toOffset(),
        _size / 2,
        bodyPaint,
      );
      
      // Borde blanco brillante
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      
      canvas.drawCircle(
        (size / 2).toOffset(),
        _size / 2,
        borderPaint,
      );
    }
    // NOTA: Si sprites cargaron, el sprite se renderiza automáticamente por el SpriteAnimationComponent
    
    // Indicador de HUIDA (verde pulsante)
    if (_isFleeing) {
      final fleePaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      
      canvas.drawCircle(
        (size / 2).toOffset(),
        _size / 2 + 10,
        fleePaint,
      );
      
      // Determinar texto según estado
      final healthPercent = _health / _maxHealth;
      String statusText;
      Color statusColor;
      
      if (healthPercent > _fleeHealthThreshold + 0.05) {
        statusText = '💚 CURÁNDOSE';
        statusColor = Colors.lightGreen;
      } else {
        statusText = '🏃 HUYENDO';
        statusColor = Colors.green;
      }
      
      // Texto de estado
      final fleeText = TextPainter(
        text: TextSpan(
          text: statusText,
          style: TextStyle(
            color: statusColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      fleeText.layout();
      fleeText.paint(
        canvas,
        Offset(
          (size.x - fleeText.width) / 2,
          -50,
        ),
      );
    }
    
    // Indicador de preparación (INVULNERABLE - dorado brillante)
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
    
    // Barra de vida
    _drawHealthBar(canvas);
    
    // Nombre del jefe
    _drawBossName(canvas);
  }
  
  void _drawHealthBar(Canvas canvas) {
    const barWidth = 80.0;
    const barHeight = 6.0;
    final barX = (size.x - barWidth) / 2;
    final barY = -20.0;
    
    // Fondo
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
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
    
    // Borde
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      borderPaint,
    );
  }
  
  void _drawBossName(Canvas canvas) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'YUREI KOHAA',
        style: TextStyle(
          color: Colors.red,
          fontSize: 12,
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
        -35,
      ),
    );
  }
  
  /// Getters
  bool get isDead => _isDead;
  double get health => _health;
  double get healthPercent => _health / _maxHealth;
}
