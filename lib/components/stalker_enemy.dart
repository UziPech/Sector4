import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'enemy_character.dart';
import '../game/expediente_game.dart';

enum StalkerState {
  active, // Persiguiendo
  sleeping, // Dormido/Vulnerable
  dying, // Muriendo (cuando se rompe el objeto)
}

class StalkerEnemy extends EnemyCharacter {
  // Stats del Boss
  double stability = 100.0;
  double maxStability = 100.0;
  double sleepDuration = 10.0; // Tiempo que duerme
  double _sleepTimer = 0.0;
  
  StalkerState stalkerState = StalkerState.active;
  
  // Referencia al objeto obsesivo (se asigna externamente)
  String? obsessionObjectId;
  
  StalkerEnemy({super.config}) {
    // Configuración específica del Stalker
    initHealth(1000.0);
    shield = 200.0;
    maxShield = 200.0;
    isInvincible = true; // Invulnerable al daño letal en fase activa
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (stalkerState == StalkerState.sleeping) {
      _sleepTimer -= dt;
      if (_sleepTimer <= 0) {
        wakeUp();
      }
      // No moverse ni atacar mientras duerme
      movementType = EnemyMovementType.stunned;
    } else if (stalkerState == StalkerState.active) {
      // Regenerar estabilidad lentamente si no recibe daño?
      // Por ahora no, para hacerlo más fácil.
      movementType = EnemyMovementType.chasing;
    }
  }
  
  @override
  bool receiveDamage(double amount) {
    if (stalkerState == StalkerState.sleeping || stalkerState == StalkerState.dying) {
      return false; // No recibe daño en estos estados (se debe romper el objeto)
    }
    
    // En fase activa, el daño reduce el escudo y luego la ESTABILIDAD, no la vida
    bool damaged = false;
    
    // 1. Daño al escudo (usando lógica base)
    if (shield > 0) {
      // Llamamos a super para manejar escudo y efectos visuales
      super.receiveDamage(amount);
      return true;
    }
    
    // 2. Daño a la estabilidad
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
  
  void onObsessionDestroyed() {
    stalkerState = StalkerState.dying;
    isInvincible = false;
    receiveDamage(10000); // Matar instantáneamente
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Renderizar barra de estabilidad (Amarilla) debajo de la vida
    if (stalkerState == StalkerState.active) {
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
      canvas.drawRect(
        Rect.fromLTWH(-barWidth / 2, offsetY, barWidth * stabilityPercent, barHeight),
        Paint()..color = const Color(0xFFFFD700), // Gold
      );
    } else if (stalkerState == StalkerState.sleeping) {
      // Indicador Zzz
      // (Simplificado visualmente con texto o icono si fuera posible, por ahora color)
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
