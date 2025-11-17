import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../expediente_game.dart';
import 'player.dart';

/// Mel - Soporte Vital y Ancla del Mundo
/// Representa la redención, el sacrificio y la conexión divina
class MelCharacter extends PositionComponent
    with KeyboardHandler, HasGameReference<ExpedienteKorinGame>, CollisionCallbacks {
  
  static final _paint = BasicPalette.cyan.paint()..style = PaintingStyle.fill;
  static const double _size = 32.0;
  static const double _followDistance = 80.0;
  static const double _speed = 180.0;
  
  // Referencia al jugador
  final PlayerCharacter player;
  
  // Habilidades
  bool _canHeal = true;
  double _healCooldown = 15.0; // 15 segundos
  double _healTimer = 0.0;
  static const double _healAmount = 100.0; // Curación completa
  
  // Estado
  bool _isActive = true;
  
  MelCharacter({
    required Vector2 position,
    required this.player,
  }) : super(position: position);
  
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
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (!_isActive) return;
    
    // Actualizar cooldown de curación
    if (!_canHeal) {
      _healTimer += dt;
      if (_healTimer >= _healCooldown) {
        _canHeal = true;
        _healTimer = 0.0;
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
      position += direction * _speed * dt;
    }
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
    
    // TODO: Agregar efecto visual/sonoro
    _showHealEffect();
  }
  
  void _showHealEffect() {
    // TODO: Implementar partículas o animación
    // Por ahora solo un placeholder
  }
  
  /// Invoca una esencia de la caída (habilidad futura)
  void invokeEssence() {
    // TODO: Implementar invocación de esencias
    // Requiere haber derrotado mutados previamente
  }
  
  /// Mimetiza habilidad de un mutado derrotado (habilidad futura)
  void mimicAbility(String abilityType) {
    // TODO: Implementar mimetismo
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
    
    // Dibujar círculo de Mel
    canvas.drawCircle(
      (size / 2).toOffset(),
      _size / 2,
      _paint,
    );
    
    // Indicador visual de cooldown
    if (!_canHeal) {
      final progress = _healTimer / _healCooldown;
      final arcPaint = Paint()
        ..color = Colors.yellow.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      
      canvas.drawArc(
        Rect.fromCircle(
          center: (size / 2).toOffset(),
          radius: _size / 2 + 5,
        ),
        -1.57, // -90 grados (arriba)
        6.28 * progress, // Progreso del arco
        false,
        arcPaint,
      );
    }
  }
}
