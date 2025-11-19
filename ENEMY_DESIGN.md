# Diseño Técnico de Enemigos: Mutados Racionales

Este documento detalla la implementación técnica de las nuevas categorías de enemigos en el motor Flame.

## Arquitectura General

Todos los enemigos heredarán de una clase base `EnemyBase` (que a su vez hereda de `PositionComponent` o `SpriteAnimationComponent` con mixins de colisión y física).

### Jerarquía de Clases Propuesta

```dart
abstract class EnemyBase extends PositionComponent with HasGameRef<Sector4Game>, CollisionCallbacks {
  // Stats comunes
  double health;
  double maxHealth;
  double speed;
  bool isInvulnerable = false;
  
  // Escudo Regenerativo
  double shield = 0;
  double maxShield = 0;
  double shieldRegenRate = 5.0; // Puntos por segundo
  double shieldCooldown = 3.0; // Tiempo sin daño para empezar a regenerar
  
  // State Machine
  late StateMachineComponent stateMachine;
  
  // Métodos comunes
  void takeDamage(double amount);
  void die();
}
```

## 1. Resonantes (The Resonants)

**Concepto Clave**: Invulnerabilidad vinculada a un objeto (`ObsessionObject`).

### Componentes
1.  **`ResonantEnemy`**: La entidad del enemigo.
    *   **Estado**: `Patrolling`, `Chasing`, `Stunned` (cuando se rompe el objeto), `Vulnerable`.
    *   **Behavior**:
        *   Inicialmente `isInvulnerable = true`.
        *   Persigue al jugador lentamente o acecha (teleport/fade).
        *   Al destruir el `ObsessionObject`, entra en estado `Stunned` brevemente y luego `Vulnerable`.
2.  **`ObsessionObject`**: Un componente destructible en el mapa.
    *   Vinculado a un `ResonantEnemy` específico por ID.
    *   Al ser destruido (`health <= 0`), llama a `resonantEnemy.onObsessionDestroyed()`.

### Variante Boss: "The Stalker" (El Acechador)
*   **Trigger**: Aparece en el "Centro de Comando" tras hablar con Marcus.
*   **Stats**: 1000 HP.
*   **Mecánica Única**:
    *   **Fase Activa**: Persigue al jugador. Es invulnerable al daño letal, pero tiene una "Barra de Estabilidad".
    *   **Ataque del Jugador**: Al reducir su estabilidad a 0, entra en **Estado de Sueño**.
    *   **Estado de Sueño**: El enemigo se duerme/desactiva por X segundos.
    *   **Objetivo**: Durante el sueño, el jugador debe buscar el `ObsessionObject` que aparece en una habitación aleatoria del búnker.
    *   **Atmósfera**: Alerta roja global en el búnker (overlay rojo transparente).
    *   **Win Condition**: Destruir el objeto mientras duerme elimina al boss (o lo hace mortal).

## 2. Kijin (The Tactical Hunters)

**Concepto Clave**: IA de combate avanzada (FSM más compleja).

### Estados (State Machine)
1.  **`Flanking`**: Se mueve lateralmente respecto al jugador, buscando cobertura o ángulo.
2.  **`Attacking`**: Carga o dispara.
3.  **`Retreating`**: Si `health < 30%`, busca alejarse del jugador temporalmente.
4.  **`Ambush`**: Espera quieto si el jugador no lo ha visto.

### Priorización de Objetivos
*   Si `Mel` está cerca y curando, el Kijin cambia su target a Mel temporalmente.
*   Requiere un sistema de `Aggro` simple.

### Lógica de Implementación
Usaremos `flame_behaviors` o una FSM custom.
```dart
class KijinEnemy extends EnemyBase {
  // Comportamiento de flanqueo
  void update(double dt) {
    // Calcular vector hacia el jugador
    // Moverse perpendicularmente si está en estado Flanking
  }
}
```

## 3. Singularidades (Bosses)

**Concepto Clave**: Múltiples fases y control del entorno.

### Fases (Ejemplo Genérico)
1.  **Fase 1**: Física. Ataques directos lentos pero fuertes.
2.  **Fase 2**: Invocación. Se vuelve invulnerable y spawnea `BasicMutants`.
3.  **Fase 3**: Caos. Ataques de área (bullet hell o zonas de daño en el suelo).

### Implementación
*   Clase `SingularityBoss` que maneja las fases.
*   Requiere integración con el sistema de eventos del mapa (para modificar el entorno).

---

## Plan de Trabajo Inmediato

1.  **Refactorizar/Crear `EnemyBase`**: Asegurar que exista una base sólida.
2.  **Implementar `ObsessionObject`**: El pilar de los Resonantes.
3.  **Implementar `ResonantEnemy`**: Primer prototipo de enemigo complejo.
4.  **Prueba de concepto**: Una habitación con un Resonante y su objeto.
