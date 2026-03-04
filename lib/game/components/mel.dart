import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/cache.dart';
import '../expediente_game.dart';
import 'player.dart';

/// Mel - Soporte Vital y Ancla del Mundo
/// Representa la redención, el sacrificio y la conexión divina
class MelCharacter extends PositionComponent
    with
        KeyboardHandler,
        HasGameReference<ExpedienteKorinGame>,
        CollisionCallbacks {
  static final _paint = BasicPalette.cyan.paint()..style = PaintingStyle.fill;
  static const double _size = 32.0;
  static const double _followDistance = 80.0;
  static const double _speed = 180.0;

  // Referencia al jugador
  final PlayerCharacter player;

  // Habilidades
  bool _canHeal = true;
  final double _healCooldown = 15.0; // 15 segundos
  double _healTimer = 0.0;
  static const double _healAmount = 100.0; // Curación completa

  // Estado
  bool _isActive = true;
  String _currentDirection = 'idle_right';

  // Animaciones de sprites
  SpriteAnimationGroupComponent<String>? _melSprite;

  MelCharacter({required Vector2 position, required this.player})
    : super(position: position);

  // Getters
  bool get canHeal => _canHeal;
  double get healCooldownProgress => _healTimer / _healCooldown;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(_size);
    anchor = Anchor.center;

    // Agregar hitbox
    add(RectangleHitbox()..collisionType = CollisionType.passive);

    await _loadMelAnimations();
  }

  Future<void> _loadMelAnimations() async {
    try {
      final customImages = Images(prefix: 'assets/');
      final melImage = await customImages.load('sprites/Mel_caminar.png');

      const cols = 4;
      const rows = 4;
      final frameWidth = melImage.width / cols;
      final frameHeight = melImage.height / rows;
      final textureSize = Vector2(frameWidth, frameHeight);

      // Fila 1 (Índice 0): Izquierda
      final leftAnim = SpriteAnimation.fromFrameData(
        melImage,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.15,
          textureSize: textureSize,
          amountPerRow: 4,
          texturePosition: Vector2(0, 0),
        ),
      );

      // Fila 2 (Índice 1): Derecha
      final rightAnim = SpriteAnimation.fromFrameData(
        melImage,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.15,
          textureSize: textureSize,
          amountPerRow: 4,
          texturePosition: Vector2(0, frameHeight * 1),
        ),
      );

      // Fila 3 e Índice 2 (Izquierda Alternativo) puede usarse como idle/caminar si es necesario,
      // Por ahora usamos la Fila 1 y 2 para el movimiento de IA.

      // Animaciones Idle (Primer frame de cada fila respectiva)
      final idleLeftAnim = SpriteAnimation.spriteList(
        [leftAnim.frames[0].sprite],
        stepTime: 1.0,
        loop: false,
      );
      final idleRightAnim = SpriteAnimation.spriteList(
        [rightAnim.frames[0].sprite],
        stepTime: 1.0,
        loop: false,
      );

      _melSprite = SpriteAnimationGroupComponent<String>(
        animations: {
          'left': leftAnim,
          'right': rightAnim,
          'idle_left': idleLeftAnim,
          'idle_right': idleRightAnim,
        },
        current: 'idle_right', // Default
        anchor: Anchor.center,
        size: Vector2(80, 80), // Tamaño visual adaptado (como Dan)
        position: Vector2(16, 16), // Centrado en hitbox 32x32
      );

      add(_melSprite!);
    } catch (e) {
      debugPrint('Error cargando sprites de Mel: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_isActive) return;

    // Actualizar cooldown de curación
    if (!_canHeal) {
      _healTimer += dt;
      game.melCooldownNotifier.value = _healTimer / _healCooldown;
      if (_healTimer >= _healCooldown) {
        _canHeal = true;
        _healTimer = 0.0;
        game.melReadyNotifier.value = true;
      }
    }

    // Seguir al jugador (IA básica)
    _followPlayer(dt);
  }

  void _followPlayer(double dt) {
    final distanceToPlayer = position.distanceTo(player.position);

    // Si está muy lejos, acercarse
    if (distanceToPlayer > _followDistance) {
      final direction = (player.position - position).normalized();
      final newPos = position + direction * _speed * dt;
      position = _constrainToWorldBounds(newPos); // Aplicar límites

      // Actualizar animación basado en dirección en X
      if (direction.x > 0) {
        _setDirection('right');
      } else if (direction.x < 0) {
        _setDirection('left');
      }
    } else {
      // Si ya está cerca, pasar a idle basado en la última dirección
      if (_currentDirection == 'right' || _currentDirection == 'idle_right') {
        _setDirection('idle_right');
      } else {
        _setDirection('idle_left');
      }
    }
  }

  void _setDirection(String newDir) {
    if (_currentDirection != newDir) {
      _currentDirection = newDir;
      if (_melSprite != null) {
        _melSprite!.current = _currentDirection;
      }
    }
  }

  /// Limita la posición a los bordes del mundo (dinámico según tamaño del mapa)
  Vector2 _constrainToWorldBounds(Vector2 pos) {
    final worldSize = game.camera.visibleWorldRect;

    // Boss level (1600x1200)
    double worldMinX = 100.0;
    double worldMaxX = 1500.0;
    double worldMinY = 100.0;
    double worldMaxY = 1100.0;

    // Mapa grande (3000x3000)
    if (worldSize.width > 2000) {
      worldMinX = 250.0;
      worldMaxX = 2750.0;
      worldMinY = 250.0;
      worldMaxY = 2750.0;
    }

    return Vector2(
      pos.x.clamp(worldMinX, worldMaxX),
      pos.y.clamp(worldMinY, worldMaxY),
    );
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Activar curación con tecla E
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyE) {
      activateHeal();
    }

    return true;
  }

  /// Activa la habilidad de curación (Soporte Vital)
  void activateHeal() {
    if (!_canHeal || player.isDead) return;

    // Curar al jugador
    player.heal(_healAmount);

    // Iniciar cooldown
    _canHeal = false;
    _healTimer = 0.0;

    // Sincronizar UI
    game.melReadyNotifier.value = false;
    game.melCooldownNotifier.value = 0.0;

    _showHealEffect();
  }

  void _showHealEffect() {
    // Por ahora solo un placeholder
  }

  /// Invoca una esencia de la caída (habilidad futura)
  void invokeEssence() {
    // Requiere haber derrotado mutados previamente
  }

  /// Mimetiza habilidad de un mutado derrotado (habilidad futura)
  void mimicAbility(String abilityType) {
    // Otorga buffs temporales a Dan
  }

  /// Reinicia el estado de Mel
  void reset() {
    _canHeal = true;
    _healTimer = 0.0;
    _isActive = true;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Dibujar círculo de Mel solo si el sprite falla al cargar
    if (_melSprite == null) {
      canvas.drawCircle((size / 2).toOffset(), _size / 2, _paint);
    }

    // Indicador visual de cooldown
    if (!_canHeal) {
      final progress = _healTimer / _healCooldown;
      final arcPaint = Paint()
        ..color = Colors.yellow.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawArc(
        Rect.fromCircle(center: (size / 2).toOffset(), radius: _size / 2 + 5),
        -1.57, // -90 grados (arriba)
        6.28 * progress, // Progreso del arco
        false,
        arcPaint,
      );
    }
  }
}
