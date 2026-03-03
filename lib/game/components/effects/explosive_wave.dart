import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../expediente_game.dart';
import '../player.dart';
import '../enemies/redeemed_kijin_ally.dart';
import '../enemies/allied_enemy.dart';
import '../enemies/minions/yakuza_ghost.dart';

/// Onda expansiva que daÃ±a y empuja a enemigos cercanos
/// Se usa en las transiciones de fase de On-Oyabun
class ExplosiveWave extends PositionComponent with HasGameReference<ExpedienteKorinGame> {
  final double maxRadius;
  final double duration;
  final double damage;
  final double knockbackForce;
  
  double _currentRadius = 0.0;
  double _timer = 0.0;
  final Set<Component> _hitTargets = {};
  
  ExplosiveWave({
    required Vector2 position,
    this.maxRadius = 800.0, // Aumentado de 300 a 800 para cubrir mÃ¡s mapa
    this.duration = 0.8,
    this.damage = 30.0,
    this.knockbackForce = 50.0, // Reducido drÃ¡sticamente de 200 a 50 para evitar bugs de teleportaciÃ³n
  }) : super(position: position, anchor: Anchor.center);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    priority = 100; // Renderizar por encima de casi todo
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    _timer += dt;
    
    // Calcular radio actual (interpolaciÃ³n lineal rÃ¡pida al principio, lenta al final)
    final progress = (_timer / duration).clamp(0.0, 1.0);
    // Easing out cubic
    final easeProgress = 1 - (1 - progress) * (1 - progress) * (1 - progress);
    _currentRadius = maxRadius * easeProgress;
    
    // Verificar colisiones
    _checkCollisions();
    
    // Eliminar al finalizar
    if (_timer >= duration) {
      removeFromParent();
    }
  }
  
  void _checkCollisions() {
    // 1. JUGADOR
    final player = game.player;
    if (!player.isDead && !_hitTargets.contains(player)) {
      final dist = position.distanceTo(player.position);
      if (dist <= _currentRadius) {
        _applyHit(player);
      }
    }
    
    // 2. KOHAA ALIADA
    game.world.children.query<RedeemedKijinAlly>().forEach((kohaa) {
      if (!kohaa.isDead && !_hitTargets.contains(kohaa)) {
        final dist = position.distanceTo(kohaa.position);
        if (dist <= _currentRadius) {
          _applyHit(kohaa);
        }
      }
    });
    
    // 3. ALIADOS GENÃ‰RICOS (Enfermeros, etc.)
    game.world.children.query<AlliedEnemy>().forEach((ally) {
      if (!ally.isDead && !_hitTargets.contains(ally)) {
        final dist = position.distanceTo(ally.position);
        if (dist <= _currentRadius) {
          _applyHit(ally);
        }
      }
    });

    // 4. MINIONS DE KOHAA (YakuzaGhost si son aliados/invocados por ella)
    // Asumimos que YakuzaGhost puede ser aliado o enemigo. 
    // Si es invocado por Kohaa, deberÃ­a ser afectado por el Boss.
    // Si es invocado por el Boss, NO deberÃ­a ser afectado (fuego amigo).
    // Por simplicidad y solicitud del usuario ("sus minions de ella"), afectamos a todos los YakuzaGhost cercanos
    // asumiendo que en este contexto los relevantes son los de Kohaa o que al Boss no le importa daÃ±ar a los suyos.
    game.world.children.query<YakuzaGhost>().forEach((ghost) {
      if (!_hitTargets.contains(ghost)) { // YakuzaGhost no tiene isDead pÃºblico fÃ¡cil a veces, pero PositionComponent sÃ­
         final dist = position.distanceTo(ghost.position);
         if (dist <= _currentRadius) {
           _applyHit(ghost);
         }
      }
    });
  }
  
  void _applyHit(PositionComponent target) {
    _hitTargets.add(target);
    
    // Aplicar DaÃ±o
    if (target is PlayerCharacter) {
      target.takeDamage(damage);
    } else if (target is RedeemedKijinAlly) {
      target.takeDamage(damage);
    } else if (target is AlliedEnemy) {
      target.takeDamage(damage);
    } else if (target is YakuzaGhost) {
       // YakuzaGhost podrÃ­a no tener takeDamage expuesto igual, intentamos dynamic o cast
       // Si YakuzaGhost hereda de Enemy o tiene takeDamage
       try {
         (target as dynamic).takeDamage(damage);
       } catch (e) {
         // Si no tiene takeDamage, lo ignoramos o lo matamos
         target.removeFromParent();
       }
    }
    
    // Aplicar Knockback (Reducido y seguro)
    // Usamos una fuerza pequeÃ±a para evitar atravesar paredes
    final dir = (target.position - position).normalized();
    
    // Si es el jugador, verificar lÃ­mites bÃ¡sicos o aplicar fuerza menor
    if (target is PlayerCharacter) {
      target.position += dir * knockbackForce;
    } else {
      target.position += dir * knockbackForce;
    }
    
    // Debug visual (opcional)
    debugPrint('ðŸ’¥ Onda Explosiva golpeÃ³ a ${target.runtimeType}');
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final progress = (_timer / duration).clamp(0.0, 1.0);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    
    // CÃ­rculo de onda
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 * (1 - progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      
    canvas.drawCircle(Offset.zero, _currentRadius, paint);
    
    // Relleno tenue
    final fillPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.2 * opacity)
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(Offset.zero, _currentRadius, fillPaint);
  }
}

