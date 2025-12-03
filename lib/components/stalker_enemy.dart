import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';
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
  
  // Sistema de sprites animados - componentes individuales por dirección
  SpriteAnimationComponent? _spriteUp;
  SpriteAnimationComponent? _spriteDown;
  SpriteAnimationComponent? _spriteLeft;
  SpriteAnimationComponent? _spriteRight;
  SpriteAnimationComponent? _currentSprite;
  
  // Sprites de ataque (charge)
  SpriteAnimationComponent? _spriteChargeUp;
  SpriteAnimationComponent? _spriteChargeDown;
  SpriteAnimationComponent? _spriteChargeLeft;
  SpriteAnimationComponent? _spriteChargeRight;
  
  bool _spritesLoaded = false;
  
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
    
    // El hitbox debe ser active para que las balas puedan colisionar
    // Pero necesitamos manejar las colisiones con el jugador de forma especial
    final hitbox = children.whereType<RectangleHitbox>().firstOrNull;
    if (hitbox != null) {
      hitbox.collisionType = CollisionType.active;
      print('✅ Stalker hitbox configurado como ACTIVE para recibir balas');
    }
    
    // Cargar sprites
    await _loadStalkerSprites();
  }
  
  Future<void> _loadStalkerSprites() async {
    try {
      print('🔄 Loading Stalker sprites...');
      
      // Cargar la imagen de caminata norte (3 frames verticales)
      final northData = await rootBundle.load('assets/sprites/stalker/stalker_walk_north.png');
      final northCodec = await instantiateImageCodec(northData.buffer.asUint8List());
      final northFrame = await northCodec.getNextFrame();
      final northImage = northFrame.image;
      
      // Cargar la imagen de caminata sur (3 frames verticales)
      final southData = await rootBundle.load('assets/sprites/stalker/stalker_walk_south.png');
      final southCodec = await instantiateImageCodec(southData.buffer.asUint8List());
      final southFrame = await southCodec.getNextFrame();
      final southImage = southFrame.image;
      
      // Cargar la imagen de caminata este (3 frames horizontales)
      // Nota: Oeste usará este mismo sprite pero invertido horizontalmente
      final eastData = await rootBundle.load('assets/sprites/stalker/stalker_walk_east.png');
      final eastCodec = await instantiateImageCodec(eastData.buffer.asUint8List());
      final eastFrame = await eastCodec.getNextFrame();
      final eastImage = eastFrame.image;
      
      // Cargar la imagen de charge vertical (5 frames verticales)
      // Para las direcciones Norte y Sur
      final chargeVerticalData = await rootBundle.load('assets/sprites/stalker/stalker_charge_vertical.png');
      final chargeVerticalCodec = await instantiateImageCodec(chargeVerticalData.buffer.asUint8List());
      final chargeVerticalFrame = await chargeVerticalCodec.getNextFrame();
      final chargeVerticalImage = chargeVerticalFrame.image;
      
      // Cargar la imagen de charge horizontal (3 frames horizontales)
      // Para las direcciones Este y Oeste
      final chargeHorizontalData = await rootBundle.load('assets/sprites/stalker/stalker_charge_horizontal.png');
      final chargeHorizontalCodec = await instantiateImageCodec(chargeHorizontalData.buffer.asUint8List());
      final chargeHorizontalFrame = await chargeHorizontalCodec.getNextFrame();
      final chargeHorizontalImage = chargeHorizontalFrame.image;
      
      print('📊 Stalker north image: ${northImage.width}x${northImage.height}');
      print('📊 Stalker south image: ${southImage.width}x${southImage.height}');
      print('📊 Stalker east image: ${eastImage.width}x${eastImage.height} (will be flipped for west)');
      print('📊 Stalker charge vertical image: ${chargeVerticalImage.width}x${chargeVerticalImage.height} (5 frames)');
      print('📊 Stalker charge horizontal image: ${chargeHorizontalImage.width}x${chargeHorizontalImage.height} (3 frames)');
      
      // Norte y Sur: 3 frames apilados verticalmente
      final frameWidthNorth = northImage.width.toDouble();
      final frameHeightNorth = northImage.height / 3.0;
      
      final frameWidthSouth = southImage.width.toDouble();
      final frameHeightSouth = southImage.height / 3.0;
      
      // Este: 3 frames horizontales (oeste usará los mismos frames invertidos)
      final frameWidthEast = eastImage.width / 3.0;
      final frameHeightEast = eastImage.height.toDouble();
      
      // Charge vertical: 3 frames apilados verticalmente
      final frameWidthChargeVertical = chargeVerticalImage.width.toDouble();
      final frameHeightChargeVertical = chargeVerticalImage.height / 3.0;
      
      // Charge horizontal: 3 frames horizontales
      final frameWidthChargeHorizontal = chargeHorizontalImage.width / 3.0;
      final frameHeightChargeHorizontal = chargeHorizontalImage.height.toDouble();
      
      print('📊 Frame sizes - North: ${frameWidthNorth.toInt()}x${frameHeightNorth.toInt()}, South: ${frameWidthSouth.toInt()}x${frameHeightSouth.toInt()}');
      print('📊 Frame sizes - East/West: ${frameWidthEast.toInt()}x${frameHeightEast.toInt()}');
      print('📊 Frame sizes - Charge Vertical: ${frameWidthChargeVertical.toInt()}x${frameHeightChargeVertical.toInt()}');
      print('📊 Frame sizes - Charge Horizontal: ${frameWidthChargeHorizontal.toInt()}x${frameHeightChargeHorizontal.toInt()}');
      
      // Crear sprites para la dirección norte (3 frames verticales)
      final List<Sprite> upSprites = [];
      for (int i = 0; i < 3; i++) {
        upSprites.add(Sprite(
          northImage,
          srcPosition: Vector2(0, i * frameHeightNorth),
          srcSize: Vector2(frameWidthNorth, frameHeightNorth),
        ));
      }
      
      // Crear sprites para la dirección sur (3 frames verticales)
      final List<Sprite> downSprites = [];
      for (int i = 0; i < 3; i++) {
        downSprites.add(Sprite(
          southImage,
          srcPosition: Vector2(0, i * frameHeightSouth),
          srcSize: Vector2(frameWidthSouth, frameHeightSouth),
        ));
      }
      
      // Crear sprites para la dirección oeste - usar este invertido
      final List<Sprite> leftSprites = [];
      for (int i = 0; i < 3; i++) {
        leftSprites.add(Sprite(
          eastImage,
          srcPosition: Vector2(i * frameWidthEast, 0),
          srcSize: Vector2(frameWidthEast, frameHeightEast),
        ));
      }
      
      // Crear sprites para la dirección este (3 frames horizontales)
      final List<Sprite> rightSprites = [];
      for (int i = 0; i < 3; i++) {
        rightSprites.add(Sprite(
          eastImage,
          srcPosition: Vector2(i * frameWidthEast, 0),
          srcSize: Vector2(frameWidthEast, frameHeightEast),
        ));
      }
      
      // Crear sprites para charge vertical (3 frames verticales)
      // Para Norte (mirando hacia arriba)
      final List<Sprite> chargeUpSprites = [];
      for (int i = 0; i < 3; i++) {
        chargeUpSprites.add(Sprite(
          chargeVerticalImage,
          srcPosition: Vector2(0, i * frameHeightChargeVertical),
          srcSize: Vector2(frameWidthChargeVertical, frameHeightChargeVertical),
        ));
      }
      
      // Para Sur (mirando hacia abajo) - mismo sprite, sin flip
      final List<Sprite> chargeDownSprites = [];
      for (int i = 0; i < 3; i++) {
        chargeDownSprites.add(Sprite(
          chargeVerticalImage,
          srcPosition: Vector2(0, i * frameHeightChargeVertical),
          srcSize: Vector2(frameWidthChargeVertical, frameHeightChargeVertical),
        ));
      }
      
      // Crear sprites para charge horizontal (3 frames horizontales)
      // Para Este (mirando a la derecha)
      final List<Sprite> chargeRightSprites = [];
      for (int i = 0; i < 3; i++) {
        chargeRightSprites.add(Sprite(
          chargeHorizontalImage,
          srcPosition: Vector2(i * frameWidthChargeHorizontal, 0),
          srcSize: Vector2(frameWidthChargeHorizontal, frameHeightChargeHorizontal),
        ));
      }
      
      // Para Oeste (mirando a la izquierda) - mismo sprite, se invertirá con flip
      final List<Sprite> chargeLeftSprites = [];
      for (int i = 0; i < 3; i++) {
        chargeLeftSprites.add(Sprite(
          chargeHorizontalImage,
          srcPosition: Vector2(i * frameWidthChargeHorizontal, 0),
          srcSize: Vector2(frameWidthChargeHorizontal, frameHeightChargeHorizontal),
        ));
      }
      
      final walkUp = SpriteAnimation.spriteList(upSprites, stepTime: 0.15);
      final walkDown = SpriteAnimation.spriteList(downSprites, stepTime: 0.15);
      final walkRight = SpriteAnimation.spriteList(rightSprites, stepTime: 0.15);
      final walkLeft = SpriteAnimation.spriteList(leftSprites, stepTime: 0.15);
      
      // Animaciones de charge - usar solo el frame del medio para postura estática
      // Para vertical (3 frames), usar frame 1 (índice 1, el del medio)
      final chargeUp = SpriteAnimation.spriteList([chargeUpSprites[1]], stepTime: 1.0, loop: false);
      final chargeDown = SpriteAnimation.spriteList([chargeDownSprites[1]], stepTime: 1.0, loop: false);
      // Para horizontal (3 frames), usar frame 1 (índice 1, el del medio)
      final chargeRight = SpriteAnimation.spriteList([chargeRightSprites[1]], stepTime: 1.0, loop: false);
      final chargeLeft = SpriteAnimation.spriteList([chargeLeftSprites[1]], stepTime: 1.0, loop: false);
      
      // Calcular tamaños para cada dirección manteniendo proporciones
      final targetHeight = 120.0;
      
      // Norte/Sur: usar proporciones del frame norte
      final scaleNorth = targetHeight / frameHeightNorth;
      final sizeNorthSouth = Vector2(frameWidthNorth * scaleNorth, targetHeight);
      
      // Este/Oeste: usar proporciones del frame este (oeste es este invertido)
      final scaleEast = targetHeight / frameHeightEast;
      final sizeEastWest = Vector2(frameWidthEast * scaleEast, targetHeight);
      
      // Charge vertical: usar proporciones del frame charge vertical
      final scaleChargeVertical = targetHeight / frameHeightChargeVertical;
      final sizeChargeVertical = Vector2(frameWidthChargeVertical * scaleChargeVertical, targetHeight);
      
      // Charge horizontal: aumentar significativamente el tamaño (2.5x más grande que walk)
      final scaleChargeHorizontal = (targetHeight / frameHeightChargeHorizontal) * 2.5;
      final sizeChargeHorizontal = Vector2(frameWidthChargeHorizontal * scaleChargeHorizontal, targetHeight * 2.5);
      
      print('📊 Component sizes - North/South: ${sizeNorthSouth.x.toInt()}x${sizeNorthSouth.y.toInt()}');
      print('📊 Component sizes - East/West: ${sizeEastWest.x.toInt()}x${sizeEastWest.y.toInt()}');
      print('📊 Component sizes - Charge Vertical: ${sizeChargeVertical.x.toInt()}x${sizeChargeVertical.y.toInt()}');
      print('📊 Component sizes - Charge Horizontal: ${sizeChargeHorizontal.x.toInt()}x${sizeChargeHorizontal.y.toInt()}');
      
      // Crear componentes individuales para cada dirección
      _spriteUp = SpriteAnimationComponent(
        animation: walkUp,
        size: sizeNorthSouth,
        anchor: Anchor.center,
      );
      
      _spriteDown = SpriteAnimationComponent(
        animation: walkDown,
        size: sizeNorthSouth,
        anchor: Anchor.center,
      );
      
      _spriteRight = SpriteAnimationComponent(
        animation: walkRight,
        size: sizeEastWest,
        anchor: Anchor.center,
      );
      
      _spriteLeft = SpriteAnimationComponent(
        animation: walkLeft,
        size: sizeEastWest,
        anchor: Anchor.center,
      );
      // Aplicar flip permanente usando scale negativo
      _spriteLeft!.scale.x = -1;
      
      // Crear componentes de charge
      _spriteChargeUp = SpriteAnimationComponent(
        animation: chargeUp,
        size: sizeChargeVertical,
        anchor: Anchor.center,
      );
      
      _spriteChargeDown = SpriteAnimationComponent(
        animation: chargeDown,
        size: sizeChargeVertical,
        anchor: Anchor.center,
      );
      
      // Charge horizontal para Este y Oeste
      _spriteChargeRight = SpriteAnimationComponent(
        animation: chargeRight,
        size: sizeChargeHorizontal,
        anchor: Anchor.center,
      );
      
      _spriteChargeLeft = SpriteAnimationComponent(
        animation: chargeLeft,
        size: sizeChargeHorizontal,
        anchor: Anchor.center,
      );
      // Aplicar flip permanente usando scale negativo
      _spriteChargeLeft!.scale.x = -1;
      
      // Empezar con la animación hacia abajo
      _currentSprite = _spriteDown;
      add(_currentSprite!);
      _spritesLoaded = true;
      print('✅ Stalker sprites loaded (including charge animations)!');
    } catch (e) {
      print('❌ Error loading Stalker sprites: $e');
      _spritesLoaded = false;
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
      // NO cambiar dirección durante charging o dashing
      if (playerToTrack != null && 
          stalkerState != StalkerState.charging && 
          stalkerState != StalkerState.dashing) {
        final target = playerToTrack!.position;
        final toTarget = target - position;
        
        final effectiveSpeed = config.chasingSpeed * powerMultiplier;
        
        if (toTarget.length > 10) {
          position.add(toTarget.normalized() * effectiveSpeed * dt);
          
          // Actualizar dirección del sprite - cambiar componente activo
          if (_spritesLoaded) {
            SpriteAnimationComponent? newSprite;
            
            if (toTarget.y.abs() > toTarget.x.abs()) {
              newSprite = toTarget.y < 0 ? _spriteUp : _spriteDown;
            } else {
              newSprite = toTarget.x > 0 ? _spriteRight : _spriteLeft;
            }
            
            // Solo cambiar si es diferente usando el método seguro
            if (newSprite != _currentSprite) {
              _switchToSprite(newSprite);
            }
          }
        }
      }
    }
  }
  
  // Método helper para cambiar sprites de forma segura
  void _switchToSprite(SpriteAnimationComponent? newSprite) {
    if (newSprite == null || newSprite == _currentSprite) return;
    
    // Remover TODOS los sprites de animación primero para evitar duplicados
    if (_currentSprite != null && _currentSprite!.isMounted) {
      _currentSprite!.removeFromParent();
    }
    
    // Asegurarse de que el nuevo sprite no esté ya añadido
    if (newSprite.isMounted) {
      newSprite.removeFromParent();
    }
    
    // Añadir el nuevo sprite
    _currentSprite = newSprite;
    add(_currentSprite!);
  }
  
  void _startDashAttack() {
    if (playerToTrack == null || !_spritesLoaded) return;
    
    stalkerState = StalkerState.charging;
    _chargeUpTimer = 0.0;
    _shakeOffset = Vector2.zero();
    
    // DETENER MOVIMIENTO durante la carga
    movementType = EnemyMovementType.stunned;
    
    // CAMBIAR A SPRITE DE CHARGE según dirección actual
    SpriteAnimationComponent? chargeSprite;
    if (_currentSprite == _spriteUp) {
      chargeSprite = _spriteChargeUp;
    } else if (_currentSprite == _spriteDown) {
      chargeSprite = _spriteChargeDown;
    } else if (_currentSprite == _spriteRight) {
      chargeSprite = _spriteChargeRight;
    } else if (_currentSprite == _spriteLeft) {
      chargeSprite = _spriteChargeLeft;
    }
    
    // Cambiar sprite usando el método seguro
    _switchToSprite(chargeSprite);
    print('🔄 Cambiado a sprite de charge');
    
    game.addMessage("¡El Stalker se prepara para embestir!");
  }
  
  void _executeDash() {
    if (playerToTrack == null || !_spritesLoaded) {
      _endDash();
      return;
    }
    
    stalkerState = StalkerState.dashing;
    _dashTimer = 0.0;
    _dashTargetPosition = playerToTrack!.position.clone();
    _dashHitPlayer = false;
    _shakeOffset = Vector2.zero();
    
    // VOLVER A SPRITE DE WALK según la dirección del charge
    SpriteAnimationComponent? walkSprite;
    if (_currentSprite == _spriteChargeUp) {
      walkSprite = _spriteUp;
    } else if (_currentSprite == _spriteChargeDown) {
      walkSprite = _spriteDown;
    } else if (_currentSprite == _spriteChargeRight) {
      walkSprite = _spriteRight;
    } else if (_currentSprite == _spriteChargeLeft) {
      walkSprite = _spriteLeft;
    }
    
    // Cambiar sprite usando el método seguro
    if (walkSprite != null) {
      _switchToSprite(walkSprite);
      
      // Efectos visuales durante el dash - preservar flip si es sprite left
      if (_currentSprite == _spriteLeft || _currentSprite == _spriteChargeLeft) {
        _currentSprite!.scale = Vector2(-1.2, 1.2); // Más grande pero manteniendo flip
      } else {
        _currentSprite!.scale = Vector2.all(1.2); // Más grande
      }
      print('🔄 Cambiado a sprite de walk para dash');
    }
    
    // Reactivar movimiento
    movementType = EnemyMovementType.chasing;
    
    game.addMessage("¡DASH!");
  }
  
  void _endDash() {
    stalkerState = stalkerState == StalkerState.berserk 
        ? StalkerState.berserk 
        : StalkerState.active;
    _dashCooldownTimer = dashCooldown;
    _dashTargetPosition = null;
    _shakeOffset = Vector2.zero();
    
    // Restaurar tamaño normal del sprite - preservar flip si es sprite left
    if (_currentSprite != null) {
      if (_currentSprite == _spriteLeft || _currentSprite == _spriteChargeLeft) {
        _currentSprite!.scale = Vector2(-1.0, 1.0); // Tamaño normal pero manteniendo flip
      } else {
        _currentSprite!.scale = Vector2.all(1.0);
      }
    }
    
    // Reactivar movimiento normal
    movementType = EnemyMovementType.chasing;
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
    print('🎯 Stalker receiveDamage: $amount HP, realObjectDestroyed: $realObjectDestroyed, isInvincible: $isInvincible');
    
    // Si está en estado sleeping o dying, no recibe daño
    if (stalkerState == StalkerState.sleeping || stalkerState == StalkerState.dying) {
      print('❌ Stalker no recibe daño: está durmiendo o muriendo');
      return false;
    }
    
    // CRÍTICO: Si el objeto real NO ha sido destruido, el Stalker es INVENCIBLE
    // El daño solo afecta escudo y estabilidad, NUNCA la vida
    if (!realObjectDestroyed) {
      print('🛡️ Stalker INVENCIBLE: daño va a escudo/estabilidad');
      
      // 1. Daño al escudo primero
      if (shield > 0) {
        final shieldDamage = amount.clamp(0.0, shield);
        shield -= shieldDamage;
        final remainingDamage = amount - shieldDamage;
        
        print('🛡️ Escudo: ${shield.toInt()} HP (recibió $shieldDamage daño)');
        
        // Si queda daño después del escudo, afecta estabilidad
        if (remainingDamage > 0) {
          stability -= remainingDamage;
          print('😵 Estabilidad: ${stability.toInt()} (recibió $remainingDamage daño)');
          
          if (stability <= 0) {
            fallAsleep();
          }
        }
      } else {
        // 2. Si no hay escudo, daño directo a la estabilidad
        stability -= amount;
        print('😵 Estabilidad: ${stability.toInt()} (recibió $amount daño, sin escudo)');
        
        if (stability <= 0) {
          fallAsleep();
        }
      }
      
      // NO llamar a super.receiveDamage() para evitar que afecte la vida
      // Solo activar efectos visuales manualmente si es necesario
      return true;
    }
    
    // Si el objeto real HA SIDO destruido, el Stalker es VULNERABLE
    // Ahora SÍ puede recibir daño directo a la vida
    print('💀 Stalker VULNERABLE: daño va a la vida');
    return super.receiveDamage(amount);
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
      
      // Mostrar notificación grande en pantalla
      game.notificationSystem.show(
        '✅ OBJETO OBSESIVO DESTRUIDO',
        '¡EL STALKER ES AHORA VULNERABLE! ¡ELIMÍNALO!',
      );
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
    // Si los sprites están cargados, no dibujar el círculo
    if (_currentSprite != null && _spritesLoaded) {
      // Aplicar tinte de color según estado
      if (stalkerState == StalkerState.dashing) {
        _currentSprite!.paint.colorFilter = const ColorFilter.mode(
          Color.fromARGB(100, 255, 180, 0),
          BlendMode.srcATop,
        );
      } else if (stalkerState == StalkerState.charging) {
        _currentSprite!.paint.colorFilter = ColorFilter.mode(
          Color.fromARGB(100, 255, (_shakeIntensity * 128).toInt(), 0),
          BlendMode.srcATop,
        );
      } else if (stalkerState == StalkerState.berserk) {
        _currentSprite!.paint.colorFilter = const ColorFilter.mode(
          Color.fromARGB(100, 255, 0, 0),
          BlendMode.srcATop,
        );
      } else if (stalkerState == StalkerState.sleeping) {
        _currentSprite!.paint.colorFilter = const ColorFilter.mode(
          Color.fromARGB(150, 100, 100, 200),
          BlendMode.srcATop,
        );
      } else {
        _currentSprite!.paint.colorFilter = null;
      }
      
      // NO llamar a super.render() para evitar el círculo base
      // Las barras de estado se mostrarán en el HUD, no sobre el sprite
      return;
    }
    
    // FALLBACK: Dibujar círculo si no hay sprite
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
  }
}

extension GameMessage on ExpedienteKorinGame {
  void addMessage(String msg) {
    // Placeholder para sistema de mensajes en pantalla
    print("GAME MESSAGE: $msg");
    // Podríamos acceder al HUD si tuviéramos referencia
  }
}
