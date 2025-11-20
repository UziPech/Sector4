import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/palette.dart';
import 'package:flame/collisions.dart';

import 'bullet.dart' show Bullet;
import 'character_component.dart';
import '../game/expediente_game.dart';
import '../game/components/tiled_wall.dart';
import '../game/components/tiled_wall.dart'; // Import shared TiledWall

// ... (rest of imports)



/// IA simple para el "Resonante" (Shūnen-tai).
/// Propósito: patrulla (WALKING) hasta que detecta al jugador (Dan) y pasa a CHASING.

enum EnemyMovementType {
  walking, // Patrullando
  chasing, // Persiguiendo al jugador
  stunned, // Aturdido
  retreating, // Retirándose
  charging, // Preparando embestida
  circling, // Girando alrededor del jugador
  defending, // Postura defensiva
}

/// Tipos de ataque disponibles
enum AttackType {
  single, // Disparo único
  burst, // Ráfaga de 3 disparos
  spread, // Disparo en abanico
  charged, // Disparo cargado potente
}

/// Tipo de combate del enemigo
enum CombatType {
  ranged, // Ataque a distancia (dispara)
  melee,  // Ataque cuerpo a cuerpo (zombie)
}

/// Configuración por defecto para el enemigo
class EnemyConfig {
  final double detectionRadius;
  final double walkingSpeed;
  final double chasingSpeed;
  final double shootCooldown;
  final double changeDirInterval;
  final double patrolRadius;
  final double stunnedDuration;
  final double healthThresholdToRetreat;
  final double flankingOffset;
  final double predictionTime;
  final double memoryDuration;

  // Nuevos parámetros
  final double dashSpeed; // Velocidad de embestida
  final double dashDuration; // Duración de la embestida
  final double dashCooldown; // Tiempo entre embestidas
  final double circlingRadius; // Radio al girar alrededor del jugador
  final double circlingSpeed; // Velocidad angular al girar
  final double chargeTime; // Tiempo de carga para ataques especiales
  final int burstCount; // Número de disparos en ráfaga
  final double spreadAngle; // Ángulo de dispersión para disparos
  final double defendThreshold; // % de daño recibido para entrar en defensa
  final double rageThreshold; // % de vida para entrar en modo furia
  final double aimAccuracy; // Precisión del aim (0.0-1.0, 1.0 = perfecto)
  final CombatType combatType; // Tipo de combate (ranged o melee)
  final double meleeDamage; // Daño por contacto (solo melee)
  final double meleeAttackCooldown; // Cooldown entre ataques melee

  const EnemyConfig({
    this.detectionRadius = 150.0,
    this.walkingSpeed = 30.0,
    this.chasingSpeed = 120.0,
    this.shootCooldown = 1.0,
    this.changeDirInterval = 2.0,
    this.patrolRadius = 200.0,
    this.stunnedDuration = 0.5,
    this.healthThresholdToRetreat = 0.3,
    this.flankingOffset = 50.0,
    this.predictionTime = 0.5,
    this.memoryDuration = 3.0,
    // Valores por defecto para los nuevos parámetros
    this.dashSpeed = 300.0,
    this.dashDuration = 0.3,
    this.dashCooldown = 3.0,
    this.circlingRadius = 100.0,
    this.circlingSpeed = 2.0,
    this.chargeTime = 1.0,
    this.burstCount = 3,
    this.spreadAngle = 0.3,
    this.aimAccuracy = 0.85, // 85% de precisión por defecto
    this.defendThreshold = 20.0,
    this.rageThreshold = 0.3,
    this.combatType = CombatType.ranged, // Por defecto dispara
    this.meleeDamage = 15.0, // Daño por contacto
    this.meleeAttackCooldown = 0.5, // Ataca cada 0.5s
  });
}

class EnemyCharacter extends PositionComponent
    with CharacterComponent, CollisionCallbacks, HasGameReference<ExpedienteKorinGame>, HasPaint {
  /// Referencia al objetivo (Dan). Se espera al menos un PositionComponent con `position`.
  PositionComponent? playerToTrack;

  /// Estado actual (lore: walking = patrón de obsesión; chasing = asalto).
  EnemyMovementType movementType = EnemyMovementType.walking;

  /// Configuración del enemigo
  final EnemyConfig config;
  
  // -- Sistema de Escudo Regenerativo --
  double shield = 0;
  double maxShield = 0;
  final double shieldRegenRate = 5.0; // Puntos por segundo
  final double shieldCooldownDuration = 3.0; // Tiempo sin daño para empezar a regenerar
  double _shieldCooldownTimer = 0.0;
  
  // -- Efectos Visuales de Daño --
  final double _flashDuration = 0.1;
  double _flashTimer = 0.0;
  bool _isFlashing = false;
  final Paint _originalTint = BasicPalette.white.paint(); // Placeholder, se usa colorFilter en render


  /// Última posición conocida del jugador
  Vector2? lastKnownPlayerPosition;

  /// Tiempo que el jugador ha estado fuera de vista
  double _timeWithoutVisibility = 0.0;

  /// Última velocidad conocida del jugador para predicción
  Vector2? _lastPlayerVelocity;
  Vector2? _lastPlayerPosition;
  double _lastPlayerUpdateTime = 0.0;

  /// Factor de flanqueo (-1 izquierda, 1 derecha)
  double _flankingDirection = 1.0;

  /// Método para calcular la dirección de movimiento circular
  Vector2 _getCirclingDirection() {
    if (playerToTrack == null) return Vector2.zero();

    // Actualizar ángulo de giro
    _circlingAngle +=
        config.circlingSpeed * _circlingDirection * 0.016; // dt aproximado

    // Calcular posición objetivo en el círculo alrededor del jugador
    final angleRad = _circlingAngle * math.pi / 180.0;
    final offset = Vector2(
      math.cos(angleRad) * config.circlingRadius,
      math.sin(angleRad) * config.circlingRadius,
    );

    final targetPos = playerToTrack!.position + offset;
    return (targetPos - position).normalized();
  }

  /// Tiempo restante en estado stunned
  double _stunnedTimeRemaining = 0.0;

  // Sistema de ataque
  AttackType _currentAttackType = AttackType.single;
  double _chargeProgress = 0.0;
  int _burstShotsRemaining = 0;
  bool _isCharging = false;

  // Control de dash/embestida
  double _dashCooldown = 0.0;
  double _dashDuration = 0.0;
  Vector2? _dashDirection;

  // Control de movimiento circular
  double _circlingAngle = 0.0;
  int _circlingDirection = 1;

  // Sistema defensivo
  double _recentDamage = 0.0;
  double _damageResetTimer = 0.0;

  // Colores para estados visuales
  // Paints para los estados, se inicializan en onMount para eficiencia.
  late final Paint _walkingPaint;
  late final Paint _chasingPaint;
  late final Paint _detectionPaint;
  late final Paint _chargingPaint;
  late final Paint _defendingPaint;

  // Tamaño de renderizado
  static const double _size = 32.0;

  // Radio de detección visual (círculo semi-transparente)

  // Control de disparo
  bool _canShoot = true;
  double _timeSinceLastShot = 0.0;
  
  // Control de ataque melee
  bool _canMeleeAttack = true;
  double _timeSinceLastMeleeAttack = 0.0;

  // Control de efectos visuales
  double _effectTimer = 0.0;

  // Lógica de movimiento
  double _elapsedSinceDirChange = 0.0;
  Vector2 _walkDirection = Vector2.zero();
  final math.Random _random = math.Random();

  // Opcional: área de patrulla (centro y radio)
  Vector2? patrolCenter;

  EnemyCharacter({this.playerToTrack, this.patrolCenter, EnemyConfig? config})
    : config = config ?? const EnemyConfig(), super(priority: 5);

  /// Llamar para asignar objetivo dinámicamente.
  void setPlayerToTrack(PositionComponent player) {
    playerToTrack = player;
  }

  /// Método heurístico simple para decidir si el jugador está cerca y visible.
  /// - Comprueba distancia
  /// - Aquí la visibilidad es simple (sin obstáculos): puede reemplazarse por un
  ///   raycast contra el TiledMap o comprobación de tiles colisionables.
  bool isPlayerNearAndVisible() {
    if (playerToTrack == null) return false;
    final double dist = (playerToTrack!.position - position).length;
    if (dist > config.detectionRadius) return false;

    // VISIBILITY: placeholder — por ahora asume visible si está dentro de distancia.
    // Reemplazar con raycast/line-of-sight contra el TiledMap para obstáculos.
    return true;
  }

  /// Actualiza el tracking del jugador para predicción de movimiento
  void _updatePlayerTracking(double dt) {
    if (playerToTrack == null) return;

    if (_lastPlayerPosition != null) {
      final timeDelta = dt;
      if (timeDelta > 0) {
        _lastPlayerVelocity =
            (playerToTrack!.position - _lastPlayerPosition!) / timeDelta;
      }
    }

    _lastPlayerPosition = playerToTrack!.position.clone();
    _lastPlayerUpdateTime += dt;
  }

  /// Predice la posición futura del jugador basado en su velocidad actual
  /// Usa cálculo balístico para aim perfecto
  Vector2? _getPredictedPlayerPosition() {
    if (playerToTrack == null) return null;
    
    // Posición y velocidad actual del jugador
    final playerPos = playerToTrack!.position;
    final playerVel = _lastPlayerVelocity ?? Vector2.zero();
    
    // Distancia al jugador
    final toPlayer = playerPos - position;
    final distance = toPlayer.length;
    
    // Velocidad de la bala (debe coincidir con Bullet.speed)
    const bulletSpeed = 300.0;
    
    // Tiempo que tardará la bala en llegar
    final timeToHit = distance / bulletSpeed;
    
    // Posición predicha: donde estará el jugador cuando llegue la bala
    final predictedPos = playerPos + playerVel * timeToHit;
    
    return predictedPos;
  }

  /// Calcula una posición de flanqueo respecto al jugador
  Vector2 _getFlankingPosition() {
    if (playerToTrack == null) return position;

    final toPlayer = playerToTrack!.position - position;
    final perp = Vector2(-toPlayer.y, toPlayer.x).normalized();
    return playerToTrack!.position +
        perp * _flankingDirection * config.flankingOffset;
  }

  /// Cambia la dirección de patrulla a una dirección aleatoria dentro del plano X/Y.
  void changeDirection() {
    // Genera una dirección aleatoria uniforme en el círculo
    final double angle = _random.nextDouble() * 2 * math.pi;
    _walkDirection = Vector2(math.cos(angle), math.sin(angle))..normalize();
    // Alterna la dirección de flanqueo
    _flankingDirection *= -1;
  }

  // Track last valid position for collision resolution
  Vector2 _lastPosition = Vector2.zero();



  @override
  void update(double dt) {
    _lastPosition = position.clone();
    super.update(dt);

    // Actualizar sistema de invencibilidad
    updateInvincibility(dt);

    // Actualizar timer de efectos
    _effectTimer += dt;

    // Actualizar timers y estados
    _updateTimers(dt);
    
    // Actualizar timer de flash
    if (_isFlashing) {
      _flashTimer -= dt;
      if (_flashTimer <= 0) {
        _isFlashing = false;
      }
    }
    
    // Regeneración de escudo
    if (maxShield > 0 && shield < maxShield) {
      if (_shieldCooldownTimer > 0) {
        _shieldCooldownTimer -= dt;
      } else {
        shield += shieldRegenRate * dt;
        if (shield > maxShield) shield = maxShield;
      }
    }

    // Actualizar cooldown de disparo (solo para enemigos ranged)
    if (config.combatType == CombatType.ranged) {
      if (!_canShoot) {
        _timeSinceLastShot += dt;
        if (_timeSinceLastShot >= config.shootCooldown) {
          _canShoot = true;
          _timeSinceLastShot = 0.0;
        }
      }

      // Procesar disparos pendientes de ráfaga
      if (_burstShotsRemaining > 0 && _canShoot) {
        tryShoot();
      }
    }
    
    // Actualizar cooldown de ataque melee (solo para enemigos melee)
    if (config.combatType == CombatType.melee) {
      if (!_canMeleeAttack) {
        _timeSinceLastMeleeAttack += dt;
        if (_timeSinceLastMeleeAttack >= config.meleeAttackCooldown) {
          _canMeleeAttack = true;
          _timeSinceLastMeleeAttack = 0.0;
        }
      }
    }

    // Actualizar estado stunned si está activo
    if (movementType == EnemyMovementType.stunned) {
      _stunnedTimeRemaining -= dt;
      if (_stunnedTimeRemaining <= 0) {
        _stunnedTimeRemaining = 0;
        movementType = EnemyMovementType.walking;
      }
      return; // No hacer nada más mientras esté stunned
    }

    // Actualizar daño reciente para sistema defensivo
    if (_damageResetTimer <= 0) {
      _recentDamage = 0;
    }

    // Actualizar tracking del jugador
    _updatePlayerTracking(dt);

    // --- Paso A: Evaluación de amenaza y memoria ---
    final bool canSeePlayer = isPlayerNearAndVisible();

    if (canSeePlayer) {
      _timeWithoutVisibility = 0.0;
      lastKnownPlayerPosition = playerToTrack!.position.clone();
    } else {
      _timeWithoutVisibility += dt;
      if (_timeWithoutVisibility >= config.memoryDuration) {
        lastKnownPlayerPosition = null;
      }
    }

    if (health <= maxHealth * config.healthThresholdToRetreat && canSeePlayer) {
      movementType = EnemyMovementType.retreating;
    } else if (canSeePlayer) {
      movementType = EnemyMovementType.chasing;
      // Intentar disparar considerando la predicción
      if (playerToTrack != null) {
        final predictedPos = _getPredictedPlayerPosition();
        if (predictedPos != null) {
          final toPredict = predictedPos - position;
          if (toPredict.length <= config.detectionRadius * 1.2) {
            tryShoot();
          }
        } else {
          tryShoot(); // Fallback al comportamiento normal
        }
      }
    } else {
      if (lastKnownPlayerPosition != null &&
          movementType == EnemyMovementType.chasing) {
        // Si llegamos cerca de la última posición conocida, volver a patrulla
        if ((position - lastKnownPlayerPosition!).length < 10) {
          lastKnownPlayerPosition = null;
          movementType = EnemyMovementType.walking;
        }
      } else {
        movementType = EnemyMovementType.walking;
      }
    }

    // --- Paso B: Ejecución del comportamiento por estado ---
    switch (movementType) {
      case EnemyMovementType.walking:
        _elapsedSinceDirChange += dt;
        if (_elapsedSinceDirChange >= config.changeDirInterval) {
          _elapsedSinceDirChange = 0.0;
          changeDirection();
        }

        // Moverse según dirección de patrulla
        final movement = _walkDirection * config.walkingSpeed * dt;
        position.add(movement);

        // En caso de tener un área de patrulla, mantener dentro del radio
        if (patrolCenter != null) {
          final offset = position - patrolCenter!;
          if (offset.length > config.patrolRadius) {
            // Empuja de vuelta hacia el centro
            final Vector2 toCenter = (patrolCenter! - position).normalized();
            position.add(toCenter * config.walkingSpeed * dt);
          }
        }
      case EnemyMovementType.chasing:
        final target = lastKnownPlayerPosition ?? playerToTrack?.position;
        if (target != null) {
          final toTarget = target - position;
          if (toTarget.length > 10) {
             position.add(toTarget.normalized() * config.chasingSpeed * dt);
          }
        }
      case EnemyMovementType.retreating:
        if (playerToTrack != null) {
          final toPlayer = playerToTrack!.position - position;
          // Moverse en dirección opuesta al jugador
          position.add(-toPlayer.normalized() * config.chasingSpeed * dt);
        }
      case EnemyMovementType.stunned:
        // No movement
        break;
      case EnemyMovementType.charging:
        if (_dashDirection != null) {
           position.add(_dashDirection! * config.dashSpeed * dt);
        }
      case EnemyMovementType.circling:
         final moveDir = _getCirclingDirection();
         position.add(moveDir * config.walkingSpeed * dt);
      case EnemyMovementType.defending:
         // No movement or slow movement
         break;
    }
  }

  /// Se llama cuando la entidad recibe daño
  @override
  bool receiveDamage(double amount) {
    // Reducir daño si estamos en modo defensivo
    if (movementType == EnemyMovementType.defending) {
      amount *= 0.5; // 50% de reducción de daño
    }

    // -- Lógica de Escudo --
    if (shield > 0) {
      if (shield >= amount) {
        shield -= amount;
        amount = 0;
      } else {
        amount -= shield;
        shield = 0;
      }
      // Resetear cooldown de regeneración
      _shieldCooldownTimer = shieldCooldownDuration;
    } else {
      // Si no hay escudo, el daño va a la vida y reseteamos el timer también
      _shieldCooldownTimer = shieldCooldownDuration;
    }
    
    // Si el daño fue absorbido completamente por el escudo, no "recibimos daño" en el sentido de CharacterComponent
    // pero sí queremos efectos visuales.
    
    // Efecto visual de flash
    _isFlashing = true;
    _flashTimer = _flashDuration;
    // TODO: Emitir partículas aquí

    if (amount <= 0) return true; // Daño absorbido

    final bool damaged = super.receiveDamage(amount);
    if (damaged) {
      // Actualizar sistema defensivo
      _recentDamage += amount;
      _damageResetTimer = 1.0; // 1 segundo para resetear el daño acumulado

      // Entrar en modo stunned si no estamos defendiendo
      if (movementType != EnemyMovementType.defending &&
          movementType != EnemyMovementType.stunned) {
        movementType = EnemyMovementType.stunned;
        _stunnedTimeRemaining = config.stunnedDuration;
      }

      // Guardar última posición conocida del jugador
      if (playerToTrack != null) {
        lastKnownPlayerPosition = playerToTrack!.position.clone();
      }

      // Cancelar carga si estábamos cargando
      if (_isCharging) {
        _isCharging = false;
        _chargeProgress = 0.0;
      }
    }
    return damaged;
  }

  @override
  void onMount() {
    super.onMount();
    // Inicializar dirección de patrulla
    changeDirection();

    // Configurar tamaño para colisiones/render
    size = Vector2.all(_size);
    
    // Inicializar vida
    initHealth(100);

    // Configurar paint para el círculo de detección usando Color.fromARGB
    _detectionPaint = Paint()
      ..color =
          const Color.fromARGB(51, 128, 128, 128) // 20% opaco gris
      ..style = PaintingStyle.fill;

    // Agregar hitbox para colisiones (solo una vez)
    add(RectangleHitbox()..collisionType = CollisionType.active);

    // Configurar paints para el enemigo
    _walkingPaint = BasicPalette.blue.paint()..style = PaintingStyle.fill;
    _chasingPaint = BasicPalette.red.paint()..style = PaintingStyle.fill;
    _chargingPaint = Paint()
      ..color =
          const Color.fromARGB(255, 255, 165, 0) // Naranja
      ..style = PaintingStyle.fill;
    _defendingPaint = Paint()
      ..color =
          const Color.fromARGB(255, 75, 75, 255) // Azul defensivo
      ..style = PaintingStyle.fill;
  }
  
  @override
  void onDeath() {
    // Dar puntos al jugador
    // game.addScore(100); // TODO: Implement addScore in ExpedienteKorinGame
    super.onDeath();
  }
  
  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    
    // Si es enemigo melee y colisiona con el jugador
    if (config.combatType == CombatType.melee &&
        other.runtimeType.toString().contains('PlayerCharacter')) {
      _tryMeleeAttack(other);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    
    // Simple collision resolution for walls
    if (other is TiledWall) {
      position = _lastPosition.clone();
    }
  }
  
  void _tryMeleeAttack(PositionComponent target) {
    if (!_canMeleeAttack) return;
    
    try {
      (target as dynamic).receiveDamage(config.meleeDamage);
      _canMeleeAttack = false;
      _timeSinceLastMeleeAttack = 0.0;
    } catch (e) {
      // Error al aplicar daño
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Dibuja el círculo de detección (solo si está en modo debug - comentado por defecto)
    // canvas.drawCircle(Offset.zero, config.detectionRadius, _detectionPaint);
    
    // Renderizar barra de vida
    renderHealthBar(canvas);
    
    // Renderizar barra de escudo (Azul cian)
    if (maxShield > 0) {
      const double barWidth = 32.0;
      const double barHeight = 4.0;
      const double offsetY = -15.0; // Arriba de la vida
      
      // Fondo (gris oscuro)
      canvas.drawRect(
        const Rect.fromLTWH(-barWidth / 2, offsetY, barWidth, barHeight),
        Paint()..color = const Color(0xFF404040),
      );
      
      // Barra actual
      final double shieldPercent = (shield / maxShield).clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromLTWH(-barWidth / 2, offsetY, barWidth * shieldPercent, barHeight),
        Paint()..color = const Color(0xFF00FFFF),
      );
    }

    // Seleccionar el color según el estado y tipo de combate
    Paint currentPaint;
    
    // Efecto de Flash (Blanco)
    if (_isFlashing) {
      currentPaint = Paint()..color = Colors.white;
    } else 
    // Enemigos melee son de color púrpura/morado
    if (config.combatType == CombatType.melee) {
      currentPaint = Paint()
        ..color = const Color.fromARGB(255, 150, 50, 200) // Púrpura
        ..style = PaintingStyle.fill;
    } else {
      // Enemigos ranged usan colores normales
      switch (movementType) {
        case EnemyMovementType.walking:
          currentPaint = _walkingPaint;
        case EnemyMovementType.chasing:
          currentPaint = _chasingPaint;
      case EnemyMovementType.stunned:
        // Parpadeo cuando está stunned
        final flashRate = 8.0; // parpadeos por segundo
        final flash = (_effectTimer * flashRate) % 1.0 > 0.5;
        currentPaint = flash ? _chasingPaint : _walkingPaint;
      case EnemyMovementType.retreating:
        // Mezcla de rojo y azul para mostrar estado de retirada
        currentPaint = Paint()
          ..color = Color.fromARGB(
            255,
            200, // rojo
            100, // verde
            200, // azul
          )
          ..style = PaintingStyle.fill;
        case EnemyMovementType.charging:
          currentPaint = _chargingPaint;
        case EnemyMovementType.circling:
          currentPaint = _chasingPaint; // Mismo color que persecución
        case EnemyMovementType.defending:
          currentPaint = _defendingPaint;
      }
    }

    // Dibuja el enemigo
    canvas.drawCircle(Offset.zero, _size / 2, currentPaint);

    // Dibujar dirección de movimiento (pequeña línea)
    if (movementType != EnemyMovementType.stunned) {
      final Vector2 moveDir = switch (movementType) {
        EnemyMovementType.walking => _walkDirection,
        EnemyMovementType.chasing =>
          playerToTrack?.position != null
              ? (playerToTrack!.position - position).normalized()
              : Vector2.zero(),
        EnemyMovementType.retreating =>
          playerToTrack?.position != null
              ? (position - playerToTrack!.position).normalized()
              : Vector2.zero(),
        EnemyMovementType.stunned => Vector2.zero(),
        EnemyMovementType.charging => _dashDirection ?? Vector2.zero(),
        EnemyMovementType.circling => _getCirclingDirection(),
        EnemyMovementType.defending => Vector2.zero(),
      };

      if (moveDir != Vector2.zero()) {
        canvas.drawLine(
          Offset.zero,
          Offset(moveDir.x * _size * 0.7, moveDir.y * _size * 0.7),
          Paint()
            ..color = const Color.fromARGB(255, 255, 255, 255)
            ..strokeWidth = 2,
        );
      }
    }
  }

  void _updateTimers(double dt) {
    // Actualizar timers de sistema
    if (_dashCooldown > 0) _dashCooldown -= dt;
    if (_damageResetTimer > 0) {
      _damageResetTimer -= dt;
      if (_damageResetTimer <= 0) {
        _recentDamage = 0;
      }
    }

    // Actualizar dash si está activo
    if (_dashDuration > 0) {
      _dashDuration -= dt;
      if (_dashDuration <= 0) {
        _dashDirection = null;
        movementType = EnemyMovementType.chasing;
      }
    }

    // Actualizar carga si está activa
    if (_isCharging) {
      _chargeProgress += dt;
      if (_chargeProgress >= config.chargeTime) {
        _releaseChargedShot();
      }
    }
  }

  void _startDash() {
    if (_dashCooldown > 0 || playerToTrack == null) return;

    // Lógica defensiva para el jugador null
    Vector2 targetPos = playerToTrack!.position;
    final predictedPos = _getPredictedPlayerPosition();
    if (predictedPos != null) {
      targetPos = predictedPos; // Usar posición predicha si está disponible
    }

    movementType = EnemyMovementType.charging;
    _dashDuration = config.dashDuration;
    _dashDirection = (targetPos - position).normalized();
    _dashCooldown = config.dashCooldown;
  }

  void _releaseChargedShot() {
    if (!_isCharging) return;

    _isCharging = false;
    _chargeProgress = 0.0;
    _currentAttackType = AttackType.charged;
    tryShoot();
    _currentAttackType = AttackType.single;
  }

  void tryShoot() {
    if (!_canShoot || playerToTrack == null) return;

    // Calcular dirección de disparo con predicción balística
    Vector2 targetPos = playerToTrack!.position;
    final predictedPos = _getPredictedPlayerPosition();
    if (predictedPos != null) {
      targetPos = predictedPos;
    }

    final toTarget = targetPos - position;
    var baseDirection = toTarget.normalized();
    
    // Aplicar imprecisión basada en aimAccuracy
    // aimAccuracy = 1.0 → sin error (aim perfecto)
    // aimAccuracy = 0.0 → error máximo
    final inaccuracy = 1.0 - config.aimAccuracy;
    final maxError = 0.3; // Máximo error en radianes (~17 grados)
    final errorAngle = (_random.nextDouble() - 0.5) * 2 * maxError * inaccuracy;
    
    // Rotar la dirección por el ángulo de error
    final cos = math.cos(errorAngle);
    final sin = math.sin(errorAngle);
    final rotatedX = baseDirection.x * cos - baseDirection.y * sin;
    final rotatedY = baseDirection.x * sin + baseDirection.y * cos;
    baseDirection = Vector2(rotatedX, rotatedY).normalized();

    switch (_currentAttackType) {
      case AttackType.single:
        _fireBullet(baseDirection);
        break;

      case AttackType.burst:
        _burstShotsRemaining = config.burstCount;
        _fireBullet(baseDirection);
        _burstShotsRemaining--;
        break;

      case AttackType.spread:
        for (int i = -1; i <= 1; i++) {
          final angle = i * config.spreadAngle;
          final direction = Vector2(
            baseDirection.x * math.cos(angle) - baseDirection.y * math.sin(angle),
            baseDirection.x * math.sin(angle) + baseDirection.y * math.cos(angle),
          );
          _fireBullet(direction);
        }
        break;

      case AttackType.charged:
        // Disparo cargado más potente
        _fireBullet(baseDirection, damage: 2.0, speed: 1.5);
        break;
    }

    // Activar cooldown
    _canShoot = false;
    _timeSinceLastShot = 0.0;
  }

  void _fireBullet(
    Vector2 direction, {
    double damage = 20.0,
    double speed = 300.0,
  }) {
    final bullet = Bullet(
      position: position.clone() + direction * _size,
      direction: direction,
      isPlayerBullet: false,
      damage: damage,
      speed: speed,
    );

    game.world.add(bullet);
  }
}
