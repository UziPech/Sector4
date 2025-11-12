import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Definición de los tipos de movimiento (fundamental para animaciones futuras)
enum MovementType { idle, walking, running }

/// Clase base para el Jugador (Dan) y los Enemigos (Mutados)
/// Esta es la base de la Caída - maneja animaciones, colisiones y vida
mixin CharacterComponent on PositionComponent {
  // -- Propiedades Esenciales --
  double baseSpeed = 50.0;
  double runningSpeed = 100.0;
  
  MovementType currentMovement = MovementType.idle;
  
  // Propiedad para el Duelo: Dirección para el Pathfinding futuro
  // 0=Derecha, 90=Arriba, 180=Izquierda, 270=Abajo
  int currentDirection = 0;
  
  // Sistema de vida
  double _health = 100;
  double _maxHealth = 100;
  bool _isDead = false;
  
  // Sistema de invencibilidad (para evitar daño instantáneo)
  bool isInvincible = false;
  final double invincibilityDuration = 1.5;
  double invincibilityElapsed = 0.0;
  
  // Getters
  double get health => _health;
  double get maxHealth => _maxHealth;
  bool get isDead => _isDead;
  
  // Barra de vida
  final Paint _healthBarBg = Paint()..color = Colors.red;
  final Paint _healthBarFg = Paint()..color = Colors.green;
  static const double _healthBarHeight = 4.0;
  static const double _healthBarWidth = 32.0;
  
  void initHealth(double amount) {
    _health = amount;
    _maxHealth = amount;
    _isDead = false; // Resetear estado de muerte
  }
  
  /// Recepción de daño con sistema de invencibilidad
  bool receiveDamage(double amount) {
    if (_isDead || isInvincible) return false;
    
    _health -= amount;
    if (_health <= 0) {
      _health = 0;
      _isDead = true;
      onDeath();
    } else {
      // Activar invencibilidad temporal
      isInvincible = true;
      invincibilityElapsed = 0.0;
    }
    return true;
  }
  
  void heal(double amount) {
    if (_isDead) return;
    _health = (_health + amount).clamp(0, _maxHealth);
  }
  
  /// Override este método en las subclases para manejar la muerte
  void onDeath() {
    removeFromParent();
  }
  
  /// Actualizar invencibilidad
  void updateInvincibility(double dt) {
    if (isInvincible) {
      invincibilityElapsed += dt;
      if (invincibilityElapsed >= invincibilityDuration) {
        isInvincible = false;
        invincibilityElapsed = 0.0;
      }
    }
  }
  
  /// Renderizar barra de vida
  void renderHealthBar(Canvas canvas) {
    const offsetY = -10.0;
    final healthPercent = _health / _maxHealth;
    
    // Fondo de la barra (rojo)
    canvas.drawRect(
      Rect.fromLTWH(
        -_healthBarWidth / 2,
        offsetY,
        _healthBarWidth,
        _healthBarHeight,
      ),
      _healthBarBg,
    );
    
    // Barra de vida actual (verde)
    canvas.drawRect(
      Rect.fromLTWH(
        -_healthBarWidth / 2,
        offsetY,
        _healthBarWidth * healthPercent,
        _healthBarHeight,
      ),
      _healthBarFg,
    );
  }
  
  /// Obtener velocidad actual según el tipo de movimiento
  double getCurrentSpeed() {
    switch (currentMovement) {
      case MovementType.idle:
        return 0.0;
      case MovementType.walking:
        return baseSpeed;
      case MovementType.running:
        return runningSpeed;
    }
  }
}
