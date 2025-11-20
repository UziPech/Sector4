import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'weapon_system.dart';
import '../components/character_component.dart';
import '../game/expediente_game.dart';
import '../game/components/player.dart';
import '../game/components/enemies/irracional.dart';

/// Mano Mutante - Arma especial de Mel
/// Ataque cuerpo a cuerpo con drenaje de vida
class MutantHandWeapon extends Weapon {
  final double lifeStealPercent;
  final double attackRadius;
  
  bool _canAttack = true;
  double _timeSinceLastAttack = 0;
  
  MutantHandWeapon({
    required String name,
    required double damage,
    required double cooldown,
    this.lifeStealPercent = 0.3, // 30% de drenaje de vida
    this.attackRadius = 60.0,
  }) : super(name: name, damage: damage, cooldown: cooldown);
  
  @override
  void update(double dt) {
    if (!_canAttack) {
      _timeSinceLastAttack += dt;
      if (_timeSinceLastAttack >= cooldown) {
        _canAttack = true;
        _timeSinceLastAttack = 0;
      }
    }
  }
  
  @override
  bool tryAttack(CharacterComponent owner, ExpedienteKorinGame game) {
    if (!_canAttack) return false;
    
    if (owner is PlayerCharacter) {
      attack(owner, game);
      _canAttack = false;
      _timeSinceLastAttack = 0;
      return true;
    }
    return false;
  }
  
  @override
  void attack(PlayerCharacter player, ExpedienteKorinGame game) {
    // Buscar enemigos en rango
    final enemies = game.world.children.query<IrrationalEnemy>();
    bool hitAnyEnemy = false;
    double totalDamageDealt = 0.0;
    
    for (final enemy in enemies) {
      if (enemy.isDead) continue;
      
      final distance = player.position.distanceTo(enemy.position);
      if (distance <= attackRadius) {
        // Aplicar daño al enemigo
        enemy.takeDamage(damage);
        totalDamageDealt += damage;
        hitAnyEnemy = true;
        
        // Crear efecto visual en la posición del enemigo
        _createHitEffect(game, enemy.position);
      }
    }
    
    // Drenar vida si golpeó a alguien
    if (hitAnyEnemy) {
      final lifeStolen = totalDamageDealt * lifeStealPercent;
      player.heal(lifeStolen);
      
      // Crear efecto visual de drenaje en el jugador
      _createDrainEffect(game, player.position);
    }
  }
  
  void _createHitEffect(ExpedienteKorinGame game, Vector2 position) {
    // Crear efecto visual temporal
    final effect = _MutantHandHitEffect(position: position.clone());
    game.world.add(effect);
  }
  
  void _createDrainEffect(ExpedienteKorinGame game, Vector2 position) {
    // Crear efecto visual de drenaje
    final effect = _LifeDrainEffect(position: position.clone());
    game.world.add(effect);
  }
}

/// Efecto visual del golpe de la mano mutante
class _MutantHandHitEffect extends PositionComponent {
  double _lifetime = 0.3;
  double _timer = 0.0;
  
  _MutantHandHitEffect({required Vector2 position})
      : super(position: position, size: Vector2.all(80), anchor: Anchor.center);
  
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
    final radius = 20.0 + (progress * 20.0);
    
    // Círculo de impacto púrpura
    final paint = Paint()
      ..color = Colors.purple.withOpacity(opacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      radius,
      paint,
    );
    
    // Círculo interior
    final innerPaint = Paint()
      ..color = Colors.purple.withOpacity(opacity * 0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      (size / 2).toOffset(),
      radius * 0.7,
      innerPaint,
    );
  }
  
  @override
  int get priority => 50;
}

/// Efecto visual del drenaje de vida
class _LifeDrainEffect extends PositionComponent {
  double _lifetime = 0.5;
  double _timer = 0.0;
  
  _LifeDrainEffect({required Vector2 position})
      : super(position: position, size: Vector2.all(60), anchor: Anchor.center);
  
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
    
    // Partículas verdes ascendentes (drenaje de vida)
    final paint = Paint()
      ..color = Colors.green.withOpacity(opacity * 0.9)
      ..style = PaintingStyle.fill;
    
    // Dibujar varias partículas
    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * pi * 2;
      final distance = progress * 20.0;
      final x = (size.x / 2) + (distance * cos(angle));
      final y = (size.y / 2) - (progress * 30.0) + (distance * sin(angle));
      
      canvas.drawCircle(
        Offset(x, y),
        4.0 * (1.0 - progress),
        paint,
      );
    }
    
    // Texto "+HP"
    if (progress < 0.5) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '+HP',
          style: TextStyle(
            color: Colors.green.withOpacity(opacity),
            fontSize: 14,
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
          -20.0 - (progress * 20.0),
        ),
      );
    }
  }
  
  @override
  int get priority => 50;
}
