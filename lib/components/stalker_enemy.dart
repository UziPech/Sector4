import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flame/collisions.dart';
import 'enemy_character.dart';
import '../game/expediente_game.dart';

enum StalkerState {
  intro, // Despertando
  active, // Persiguiendo
  sleeping, // Dormido/Vulnerable
  charging, // Preparando embestida
  dashing, // Ejecutando embestida
  berserk, // Modo desesperación (todos los objetos destruidos)
  dying, // Muriendo (cuando se rompe el objeto real)
}

class StalkerEnemy extends EnemyCharacter {
  // Stats del Boss
  double stability = 100.0;
  double maxStability = 100.0;
  double sleepDuration = 10.0; // Tiempo que duerme
  double _sleepTimer = 0.0;
  
  // Sistema de degradación
  int objectsRemaining = 7; // Total de objetos en el nivel
  double powerMultiplier = 1.0; // Multiplicador de poder
  bool realObjectDestroyed = false; // Si el objeto real fue destruido
  
  // Sistema de Dash/Embestida - MÁS AGRESIVO
  double _dashCooldownTimer = 0.0;
  final double dashCooldown = 4.0; // 6 → 4 segundos (más frecuente)
  double _chargeUpTimer = 0.0;
  final double chargeUpDuration = 0.4; // 0.5 → 0.4s (carga más rápida)
  double _dashTimer = 0.0;
  final double dashDuration = 0.3;
  Vector2? _dashTargetPosition;
  final double dashSpeed = 550.0; // 450 → 550 (más rápido)
  final double dashDamage = 60.0; // 50 → 60 HP
  bool _dashHitPlayer = false;
  
  // Efecto de temblor
  Vector2 _shakeOffset = Vector2.zero();
  double _shakeIntensity = 0.0;
  
  StalkerState stalkerState = StalkerState.active;
  
  // Referencia al objeto obsesivo (se asigna externamente)
  String? obsessionObjectId;
  
  StalkerEnemy({super.config}) {
    // Configuración específica del Stalker - AUMENTADA PARA MÁS DIFICULTAD
    initHealth(3000.0); // 1000 → 3000 (triple de vida)
    shield = 500.0; // 200 → 500 (escudo más resistente)
    maxShield = 500.0;
    isInvincible = true; // CRUCIAL: Invencible hasta destruir objeto
    stalkerState = StalkerState.intro;
    _sleepTimer = 2.0;
    
    // Stats aumentados
    stability = 150.0; // 100 → 150 (más difícil de cansar)
    maxStability = 150.0;
    sleepDuration = 7.0; // 10 → 7 (duerme menos tiempo)
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Cambiar el hitbox a passive para que el jugador pueda atravesar al Stalker
    // Esto evita que el jugador quede atrapado
    final hitbox = children.whereType<RectangleHitbox>().firstOrNull;
    if (hitbox != null) {
      hitbox.collisionType = CollisionType.passive;
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // CRÍTICO: Mantener invulnerabilidad si el objeto real no ha sido destruido
    // Esto previene que updateInvincibility() desactive la invulnerabilidad
    if (!realObjectDestroyed) {
      isInvincible = true;
      invincibilityElapsed = 0.0;
    }
    
    // Actualizar cooldown de dash
    if (_dashCooldownTimer > 0) {
      _dashCooldownTimer -= dt;
    }
    
    if (stalkerState == StalkerState.intro) {
      _sleepTimer -= dt;
      if (_sleepTimer <= 0) {
        wakeUp();
      }
      movementType = EnemyMovementType.stunned;
    } 
    else if (stalkerState == StalkerState.sleeping) {
      _sleepTimer -= dt;
      if (_sleepTimer <= 0) {
        wakeUp();
      }
      movementType = EnemyMovementType.stunned;
    }
    else if (stalkerState == StalkerState.charging) {
      // Fase de carga/anticipación
      _chargeUpTimer += dt;
      
      // Efecto de temblor
      _shakeIntensity = (_chargeUpTimer / chargeUpDuration).clamp(0.0, 1.0);
      final shakeMagnitude = 3.0 * _shakeIntensity;
      _shakeOffset = Vector2(
        math.sin(game.currentTime() * 30) * shakeMagnitude,
        math.cos(game.currentTime() * 30) * shakeMagnitude,
      );
      
      if (_chargeUpTimer >= chargeUpDuration) {
        // Iniciar dash
        _executeDash();
      }
      
      movementType = EnemyMovementType.stunned; // No moverse durante carga
    }
    else if (stalkerState == StalkerState.dashing) {
      // Ejecutando el dash
      _dashTimer += dt;
      
      if (_dashTargetPosition != null) {
        final toTarget = _dashTargetPosition! - position;
        final distance = toTarget.length;
        
        if (distance > 10 && _dashTimer < dashDuration) {
          // Moverse hacia el objetivo a velocidad de dash
          position.add(toTarget.normalized() * dashSpeed * dt);
        } else {
          // Dash completado
          _endDash();
        }
      } else {
        _endDash();
      }
    }
    else if (stalkerState == StalkerState.active || stalkerState == StalkerState.berserk) {
      // Modo activo o berserk
      movementType = EnemyMovementType.chasing;
      
      // Intentar dash attack si está disponible
      if (_dashCooldownTimer <= 0 && playerToTrack != null) {
        final distanceToPlayer = (playerToTrack!.position - position).length;
        
        // Dash a distancia media-amplia (100-400 unidades) - MÁS AGRESIVO
        if (distanceToPlayer >= 100 && distanceToPlayer <= 400) {
          _startDashAttack();
        }
      }
      
      // Aplicar powerMultiplier a la velocidad de persecución
      if (playerToTrack != null && stalkerState != StalkerState.charging) {
        final target = playerToTrack!.position;
        final toTarget = target - position;
        
        final effectiveSpeed = config.chasingSpeed * powerMultiplier;
        
        if (toTarget.length > 10) {
          position.add(toTarget.normalized() * effectiveSpeed * dt);
        }
      }
    }
  }
  
  void _startDashAttack() {
    if (playerToTrack == null) return;
    
    stalkerState = StalkerState.charging;
    _chargeUpTimer = 0.0;
    _shakeOffset = Vector2.zero();
    game.addMessage("¡El Stalker se prepara para embestir!");
  }
  
  void _executeDash() {
    if (playerToTrack == null) {
      _endDash();
      return;
    }
    
    stalkerState = StalkerState.dashing;
    _dashTimer = 0.0;
    _dashTargetPosition = playerToTrack!.position.clone();
    _dashHitPlayer = false;
    _shakeOffset = Vector2.zero();
    game.addMessage("¡DASH!");
  }
  
  void _endDash() {
    stalkerState = stalkerState == StalkerState.berserk 
        ? StalkerState.berserk 
        : StalkerState.active;
    _dashCooldownTimer = dashCooldown;
    _dashTargetPosition = null;
    _shakeOffset = Vector2.zero();
  }
  
  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    
    // Si está en dash y golpea al jugador
    if (stalkerState == StalkerState.dashing && !_dashHitPlayer) {
      if (other.runtimeType.toString().contains('PlayerCharacter')) {
        try {
          (other as dynamic).takeDamage(dashDamage);
          _dashHitPlayer = true;
          game.addMessage("¡EMBESTIDA! -60 HP"); // Actualizado a 60
          _endDash();
        } catch (e) {
          // Error
        }
      }
    }
  }
  
  @override
  bool receiveDamage(double amount) {
    // Si está en estado sleeping o dying, no recibe daño
    if (stalkerState == StalkerState.sleeping || stalkerState == StalkerState.dying) {
      return false;
    }
    
    // Si el objeto real ha sido destruido, el Stalker es VULNERABLE
    // Puede recibir daño directo a la vida
    if (realObjectDestroyed) {
      // Daño normal a la vida (usando lógica base de CharacterComponent)
      return super.receiveDamage(amount);
    }
    
    // Si el objeto real NO ha sido destruido:
    // El daño reduce el escudo y luego la ESTABILIDAD, pero NO la vida
    
    // 1. Daño al escudo primero
    if (shield > 0) {
      final shieldDamage = amount.clamp(0.0, shield);
      shield -= shieldDamage;
      final remainingDamage = amount - shieldDamage;
      
      // Si queda daño después del escudo, afecta estabilidad
      if (remainingDamage > 0) {
        stability -= remainingDamage;
        if (stability <= 0) {
          fallAsleep();
        }
      }
      
      // Efecto visual de daño
      super.receiveDamage(0); // Solo para trigger de efectos visuales
      return true;
    }
    
    // 2. Si no hay escudo, daño directo a la estabilidad
    stability -= amount;
    // Efecto visual de daño
    super.receiveDamage(0); // Solo para trigger de efectos visuales
    
    if (stability <= 0) {
      fallAsleep();
    }
    
    return true;
  }
  
  void fallAsleep() {
    stalkerState = StalkerState.sleeping;
    _sleepTimer = sleepDuration;
    movementType = EnemyMovementType.stunned;
    // TODO: Notificar al jugador "¡El Stalker duerme! ¡Busca el objeto!"
    game.addMessage("¡El Stalker duerme! ¡Busca el objeto!");
  }
  
  void wakeUp() {
    stalkerState = StalkerState.active;
    stability = maxStability; // Recupera estabilidad
    movementType = EnemyMovementType.chasing;
    game.addMessage("¡El Stalker ha despertado!");
  }
  
  
  /// Llamado cuando se destruye cualquier objeto (real o decoy)
  void onObjectDestroyed(bool isReal) {
    objectsRemaining--;
    
    if (isReal) {
      // El objeto REAL fue destruido
      realObjectDestroyed = true;
      isInvincible = false;
      game.addMessage("¡¡¡VULNERABILIDAD DETECTADA!!!");
      game.addMessage("¡El Stalker ahora puede ser derrotado!");
    } else {
      // Objeto falso
      game.addMessage("Solo era un señuelo... $objectsRemaining objetos quedan");
    }
    
    // Calcular multiplicador de velocidad según objetos restantes:
    if (objectsRemaining == 5) {
      // Perdió 2 objetos - se vuelve más lento
      powerMultiplier = 0.85;
      game.addMessage("El Stalker parece debilitarse...");
    } else if (objectsRemaining == 3) {
      // Perdió 4 objetos - desesperación, más rápido
      powerMultiplier = 1.3;
      shield = 0; // Pierde escudo completamente
      game.addMessage("¡El Stalker entra en pánico!");
    } else if (objectsRemaining == 1) {
      // Solo 1 objeto queda - muy agresivo
      powerMultiplier = 1.4;
      maxStability *= 0.6; // Se cansa más rápido
      sleepDuration = 7.0; // Duerme menos tiempo
      game.addMessage("¡El Stalker está al borde del colapso!");
    } else if (objectsRemaining == 0) {
      // Todos destruidos - modo berserk
      enterBerserkMode();
    }
  }
  
  void enterBerserkMode() {
    stalkerState = StalkerState.berserk;
    
    if (realObjectDestroyed) {
      // Si ya destruiste el real, ahora es vulnerable pero entra en modo final
      game.addMessage("¡¡¡EL STALKER HA PERDIDO LA RAZÓN!!!");
    } else {
      // Si NO destruiste el real, sigue invencible pero furioso
      isInvincible = false; // Ahora vulnerable de todos modos
      game.addMessage("¡¡¡MODO BERSERK ACTIVADO!!!");
    }
    
    powerMultiplier = 2.0; // Extremadamente rápido
    sleepDuration = 3.0; // Duerme muy poco
    maxStability *= 0.4; // Se cansa rapidísimo
    shield = 0;
  }
  
  /// Método legacy para compatibilidad
  /// Ya NO mata al Stalker, solo lo hace vulnerable
  void onObsessionDestroyed() {
    // Ya se llamó onObjectDestroyed(true) desde ObsessionObject.destroy()
    // Este método ahora solo existe para compatibilidad
    // El Stalker queda vulnerable pero VIVO - debes pelear para matarlo
  }
  
  @override
  void render(Canvas canvas) {
    // Aplicar offset de temblor si está cargando
    if (stalkerState == StalkerState.charging) {
      canvas.save();
      canvas.translate(_shakeOffset.x, _shakeOffset.y);
    }
    
    // Determinar color según estado y degradación
    Color stalkerColor;
    double opacity = 1.0;
    
    if (stalkerState == StalkerState.dashing) {
      // Durante dash - color amarillo/naranja brillante
      stalkerColor = const Color.fromARGB(255, 255, 180, 0);
    }
    else if (stalkerState == StalkerState.charging) {
      // Durante carga - rojo pulsante
      final pulseIntensity = (_shakeIntensity * 255).toInt();
      stalkerColor = Color.fromARGB(255, 255, pulseIntensity ~/  2, 0);
    }
    else if (stalkerState == StalkerState.berserk) {
      // Modo berserk - rojo puro e intenso
      stalkerColor = const Color.fromARGB(255, 255, 0, 0);
    } else if (stalkerState == StalkerState.sleeping) {
      // Dormido - azul oscuro
      stalkerColor = const Color.fromARGB(200, 100, 100, 200);
    } else {
      // Color degradado según objetos restantes
      opacity = (objectsRemaining / 7.0).clamp(0.3, 1.0); // Mínimo 30% opacidad
      final alpha = (opacity * 255).toInt();
      
      if (objectsRemaining <= 2) {
        // Casi destruido - rojo oscuro
        stalkerColor = Color.fromARGB(alpha, 200, 50, 50);
      } else if (objectsRemaining <= 4) {
        // Degradado - púrpura rojizo
        stalkerColor = Color.fromARGB(alpha, 180, 60, 120);
      } else {
        // Normal - púrpura
        stalkerColor = Color.fromARGB(alpha, 150, 50, 200);
      }
    }
    
    // Dibujar el círculo del Stalker con color degradado
    final stalkerPaint = Paint()
      ..color = stalkerColor
      ..style = PaintingStyle.fill;
    
    // Tamaño aumentado durante dash
    final renderSize = stalkerState == StalkerState.dashing 
        ? size.x / 2 * 1.2 
        : size.x / 2;
    
    canvas.drawCircle(Offset.zero, renderSize, stalkerPaint);
    
    // Restaurar canvas si había shake
    if (stalkerState == StalkerState.charging) {
      canvas.restore();
    }
    
    // Llamar a render base para barras de vida/escudo
    super.render(canvas);
    
    // Renderizar barra de estabilidad (Amarilla) debajo de la vida
    if (stalkerState == StalkerState.active || stalkerState == StalkerState.berserk) {
      const double barWidth = 32.0;
      const double barHeight = 4.0;
      const double offsetY = 5.0; // Debajo del personaje
      
      // Fondo
      canvas.drawRect(
        const Rect.fromLTWH(-barWidth / 2, offsetY, barWidth, barHeight),
        Paint()..color = const Color(0xFF404040),
      );
      
      // Barra actual
      final double stabilityPercent = (stability / maxStability).clamp(0.0, 1.0);
      final barColor = stalkerState == StalkerState.berserk 
          ? const Color(0xFFFF0000) // Rojo en berserk
          : const Color(0xFFFFD700); // Oro normal
      
      canvas.drawRect(
        Rect.fromLTWH(-barWidth / 2, offsetY, barWidth * stabilityPercent, barHeight),
        Paint()..color = barColor,
      );
    } else if (stalkerState == StalkerState.sleeping) {
      // Indicador "Zzz" cuando duerme
      // (Simplificado - podríamos añadir texto si fuera necesario)
    }
  }
}

extension GameMessage on ExpedienteKorinGame {
  void addMessage(String msg) {
    // Placeholder para sistema de mensajes en pantalla
    print("GAME MESSAGE: $msg");
    // Podríamos acceder al HUD si tuviéramos referencia
  }
}
