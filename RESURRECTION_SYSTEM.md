# Sistema de Resurrección de Mel

## Descripción General

Mel puede resucitar enemigos muertos como aliados temporales que luchan a su lado. El sistema permite un ciclo infinito de resurrecciones con un límite de **2 aliados activos simultáneamente**.

## Mecánica del Sistema

### Flujo de Resurrección

1. **Enemigo muere** → Deja una `EnemyTomb` (tumba) en su posición
2. **Mel presiona E cerca de la tumba** → Resucita al enemigo como `AlliedEnemy`
3. **Aliado activo** → Ataca a enemigos durante su tiempo de vida
4. **Aliado muere/expira** → Deja una nueva tumba y libera su slot
5. **Ciclo se repite** → Mel puede resucitar la nueva tumba

### Límites y Restricciones

- **Máximo 2 aliados activos** simultáneamente
- **Sin límite de resurrecciones totales** (ciclo infinito)
- **Radio de resurrección**: 60 unidades
- **Duración de tumbas**: 
  - Enemigos normales: 5 segundos
  - Aliados: 8 segundos

## Tipos de Enemigos Resucitables

### Actualmente Implementados

#### 1. Irracional (`'irracional'`)
- **Duración**: 45 segundos
- **Vida**: 60 HP
- **Velocidad**: 130
- **Daño**: 18
- **Rango de ataque**: 45
- **Cooldown**: 0.9s

#### 2. Aliado Re-resucitado (`'allied'`)
- **Duración**: 45 segundos
- **Estadísticas**: Iguales a Irracional
- **Nota**: Cuando un aliado muere, puede ser resucitado nuevamente

### Preparados para Implementación Futura

#### 3. Mutado de Rango Medio (`'mutado_rango_medio'`)
- **Duración**: 60 segundos
- **Vida**: 100 HP
- **Velocidad**: 150
- **Daño**: 25
- **Rango de ataque**: 50
- **Cooldown**: 0.8s

#### 4. Mutado de Rango Alto (`'mutado_rango_alto'`)
- **Duración**: 90 segundos
- **Vida**: 150 HP
- **Velocidad**: 170
- **Daño**: 35
- **Rango de ataque**: 60
- **Cooldown**: 0.7s

## Cómo Añadir Nuevos Tipos de Mutados

### Paso 1: Crear la Clase del Enemigo

Crea un nuevo archivo en `lib/game/components/enemies/`:

```dart
import 'package:flame/components.dart';
import '../enemy_tomb.dart';

class MutadoRangoMedio extends PositionComponent {
  // Implementar lógica del enemigo
  
  void _die() {
    _isDead = true;
    
    // Crear tumba con el tipo correcto
    final tomb = EnemyTomb(
      position: position.clone(),
      enemyType: 'mutado_rango_medio', // ← Importante
    );
    game.world.add(tomb);
    
    removeFromParent();
  }
}
```

### Paso 2: Configurar Estadísticas en AlliedEnemy

Edita `lib/game/components/enemies/allied_enemy.dart` en el método `_configureStats()`:

```dart
case 'mutado_rango_medio':
  _maxHealth = 100.0;
  _health = 100.0;
  _speed = 150.0;
  _damage = 25.0;
  _attackRange = 50.0;
  _attackCooldown = 0.8;
  break;
```

### Paso 3: Configurar Duración en PlayerCharacter

Edita `lib/game/components/player.dart` en el método `_getLifetimeForEnemyType()`:

```dart
case 'mutado_rango_medio':
  return 60.0; // Duración en segundos
```

### Paso 4: (Opcional) Añadir Habilidades Especiales

Puedes extender `AlliedEnemy` para que ciertos tipos tengan habilidades únicas:

```dart
void _performSpecialAbility() {
  switch (enemyType) {
    case 'mutado_rango_medio':
      _aoeAttack(); // Ataque en área
      break;
    case 'mutado_rango_alto':
      _buffNearbyAllies(); // Buffear aliados cercanos
      break;
  }
}
```

## Interacción con Enemigos

Los aliados resucitados:
- ✅ Atacan a `IrrationalEnemy`
- ✅ Pueden ser atacados por enemigos
- ✅ Dejan tumbas al morir
- ✅ Liberan su slot automáticamente
- ✅ Tienen barras de vida y tiempo restante

Los enemigos (`IrrationalEnemy`):
- ✅ Priorizan atacar al objetivo más cercano (jugador o aliado)
- ✅ Pueden matar a los aliados
- ✅ Dejan tumbas al morir

## Archivos Relevantes

- `lib/game/components/enemies/allied_enemy.dart` - Lógica de aliados
- `lib/game/components/player.dart` - Sistema de resurrección
- `lib/game/systems/resurrection_system.dart` - Gestión de slots
- `lib/game/components/enemy_tomb.dart` - Tumbas
- `lib/game/components/enemies/irracional.dart` - Enemigo base

## Mejoras Futuras Sugeridas

1. **Efectos visuales mejorados** para resurrecciones
2. **Diferentes colores de aura** según el tipo de aliado
3. **Sistema de experiencia** para aliados (se vuelven más fuertes con el tiempo)
4. **Habilidades especiales** por tipo de mutado
5. **Comandos básicos** para dirigir a los aliados
6. **Límite de slots escalable** según progresión del jugador
