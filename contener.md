I. Componentes Core (La Base de la Caída)
La clase base debe ser robusta, manejando animaciones y colisiones, la esencia del motor de Flame.
1. CharacterComponent (Base de Dan y Mutados)
Este componente define a cualquier entidad viva o animada en el mapa, incluyendo la gestión de velocidad y la dirección.
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

// Definición de las direcciones de movimiento (fundamental para animaciones)
enum MovementType { idle, walking, running }

// Clase base para el Jugador (Dan) y los Enemigos (Mutados)
class CharacterComponent extends SpriteAnimationComponent with CollisionCallbacks {
  
  // -- Propiedades Esenciales --
  double baseSpeed = 50.0;
  double runningSpeed = 100.0;
  
  MovementType currentMovement = MovementType.idle;
  
  // NOTA: Estas animaciones serán inicializadas en las clases hijas.
  late SpriteAnimation idleAnimation;
  late SpriteAnimation walkAnimation;

  // Propiedad para el Duelo: Dirección para el Pathfinding futuro.
  // Usar números (0, 90, 180, 270) o enums específicos si es Top-Down.
  int currentDirection = 0; // 0=Derecha, 90=Arriba, etc.

  CharacterComponent({
    Vector2? position,
    Vector2? size,
    double? speed,
  }) : super(position: position, size: size) {
    // Si no se define una velocidad, usa la base.
    if (speed != null) {
      baseSpeed = speed;
    }
  }

  @override
  Future<void> onLoad() async {
    // Se añade un Hitbox base (un Rectángulo, como en los ejemplos del Dino)
    // El tamaño y la posición deben ajustarse al sprite.
    add(RectangleHitbox(
      size: this.size, 
      // Si el anchor es centro, la posición es (0,0)
    )..collisionType = CollisionType.active); // Dan y Kijins son 'Active' [5]
    
    // Configuración inicial de la animación.
    animation = idleAnimation; 
  }

  @override
  void update(double dt) {
    // La lógica de movimiento irá aquí, usando dt para consistencia [6, 7]
    super.update(dt);
  }
}
2. GameController (FlameGame principal)
Este esqueleto es vital para activar el sistema de colisiones global y gestionar el estado del juego (la Caída).
import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/input.dart';
// Importar componentes necesarios (DanComponent, MelTimer, etc.)

class MyGame extends FlameGame with HasCollisionDetection, HasKeyboardHandlerComponents, HasTappables {
  
  // Propiedad central del Duelo: La Cordura/Vida de Dan
  int danHealth = 100;
  
  // Propiedades para Mel (La Ancla/Semilla del Ángel Caído)
  double melCooldownTime = 15.0; // 15 segundos de cooldown para Soporte Vital [8]
  double melTimeElapsed = 0.0;
  bool isMelReady = true;

  @override
  Future<void> onLoad() async {
    // Aquí se cargan assets, se inicializa la música de fondo, etc.
    // ...
    // Añadir DanComponent, TileMapComponent (cuando exista)
    // add(DanComponent(...));
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Lógica de Cooldown de Mel
    if (!isMelReady) {
      melTimeElapsed += dt;
      if (melTimeElapsed >= melCooldownTime) {
        isMelReady = true;
        melTimeElapsed = 0.0;
        // Lógica de feedback visual (ej. actualizar Overlay)
      }
    }
    
    // Lógica para generación de Mutados (ej. MeteorComponent/Gaki por Timer) [9]
  }

  // Función de Soporte Vital (Curación de Mel)
  void activateMelHeal() {
    if (isMelReady) {
      // Aplicar curación a Dan (ej. danHealth = 100)
      isMelReady = false;
      // Lógica de feedback (ej. Overlay, efecto de invencibilidad temporal)
    }
  }
}
II. Lógica del Duelo: Dan y la IA de Persecución (Gaki)
1. DanComponent (La Culpa y Vulnerabilidad)
Dan debe ser capaz de reaccionar a la entrada del usuario y, crucialmente, gestionar el daño recibido con un periodo de invulnerabilidad post-impacto, esencial para evitar que el Gaki (o futuro Kijin) lo elimine instantáneamente.
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flame/input.dart';
import 'character_component.dart';

class DanComponent extends CharacterComponent with KeyboardHandler, HasGameReference<MyGame> {
  
  // -- Lógica de Duelo (Vulnerabilidad) --
  bool isInvincible = false;
  final double invincibilityDuration = 1.5; // Cooldown de daño [10]
  double invincibilityElapsed = 0.0;
  
  DanComponent({required Vector2 position, required Vector2 size})
      : super(position: position, size: size, speed: 100.0);

  @override
  void update(double dt) {
    super.update(dt);

    // Actualización de la Invencibilidad
    if (isInvincible) {
      invincibilityElapsed += dt;
      if (invincibilityElapsed >= invincibilityDuration) {
        isInvincible = false;
        invincibilityElapsed = 0.0;
        // Cambiar el color/shader de Dan a normal (feedback visual)
      }
    }
    // Lógica de movimiento basada en 'currentMovement' y 'dt'
  }

  // Recepción de daño y activación del Duelo
  void receiveDamage(int amount) {
    if (!isInvincible) {
      game.danHealth -= amount;
      isInvincible = true;
      // Iniciar efecto visual (ej. parpadeo o shader de corrupción)
      
      if (game.danHealth <= 0) {
        // Lógica de Game Over (La Caída Final) [12]
      }
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is GakiComponent) { 
      receiveDamage(10); // Ejemplo de daño
      other.removeFromParent(); // Si el Gaki se autodestruye al contacto
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Lógica para cambiar currentMovement (idle, walking, running) 
    // y activar animaciones según las teclas presionadas [13]

    // Ejemplo: Si se presiona 'E' (interactuar/usar Mel)
    if (keysPressed.contains(LogicalKeyboardKey.keyE) && event is RawKeyDownEvent) {
      game.activateMelHeal();
      return false; 
    }
    return super.onKeyEvent(event, keysPressed);
  }
}
2. GakiComponent (Enemigo Instintivo)
El Gaki (Mutado de Sector 2) solo necesita seguir el instinto. Su IA de persecución simple es suficiente por ahora, pero la estructura debe incluir el chequeo de proximidad, sentando las bases para el filtro de visibilidad que necesitará el Kijin.
import 'package:flame/components.dart';
import 'character_component.dart';
import 'dan_component.dart';

class GakiComponent extends CharacterComponent {

  final DanComponent playerToTrack;
  final double DISTANCE_TO_TRACK = 200.0; // Rango de detección [16]

  GakiComponent({
    required this.playerToTrack,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size, speed: 50.0);

  // Determina si el Gaki debe cambiar de estado (Perseguir o Deambular)
  bool _shouldChasePlayer() {
    // 1. Chequeo de Distancia
    if (position.distanceTo(playerToTrack.position) < DISTANCE_TO_TRACK) {
      // NOTA: Para el Kijin, aquí se agregaría la lógica de Visibilidad y Obstáculos [15]
      return true;
    }
    return false;
  }

  @override
  void update(double dt) {
    if (_shouldChasePlayer()) {
      currentMovement = MovementType.running;
      double currentSpeed = runningSpeed; 

      // Vector de dirección normalizado hacia Dan
      Vector2 direction = (playerToTrack.position - position).normalized();
      
      // Mover la posición usando delta time
      position.add(direction * currentSpeed * dt);
      
    } else {
      currentMovement = MovementType.idle;
      // Lógica de movimiento de 'patrulla' (WanderState) o Idle
    }

    super.update(dt);
  }
}
III. Crítica del Abogado del Diablo y Optimización
Estos componentes sientan las bases de la narrativa en el código. Ahora, permitamos que la crítica perfeccione el Duelo.
1. Sobre la Colisión (CollidableType)
Pregunta Crítica: En el onCollisionStart de DanComponent, el código asume que el GakiComponent se elimina al impactar (other.removeFromParent()). ¿Estamos modelando un Yūrei débil que se disipa al tocar el mundo físico, o estamos desperdiciando ciclos de CPU si el Gaki solo es un peón que queremos reutilizar (optimización de recursos)?
• Optimización: Si los Gakis son desechables, removeFromParent() es eficiente. Si buscamos escalabilidad (Jefe que no desaparece), necesitaremos que DanComponent compruebe el tipo: si other is BossComponent, Dan debe reaccionar (daño y retroceso) mientras el Jefe permanece activo.
• Flame & Lore: Asegúrese de que todos los componentes que interactúen tengan un HitboxRectangle y que el FlameGame principal tenga el HasCollisionDetection mixin.
2. Preparando el Kijin (IA Táctica)
La IA del GakiComponent es un cliché necesario por ahora, pero el _shouldChasePlayer() es la puerta de entrada a la sofisticación del Kijin (Amenaza de Sector 4).
Próxima Tarea de Refactorización (Post-Tiled): Una vez implementado Tiled, se debe modificar _shouldChasePlayer() para incluir:
1. Visibilidad y Campo de Visión: Calcular el ángulo entre Dan y el Gaki. Solo persigue si Dan está dentro del ángulo de visión frontal (getAngle). Esto hace que el sigilo sea crucial, como en Katergáris' Labyrinth.
2. Pathfinding: La persecución no debe ser en línea recta, sino utilizando el algoritmo A* para evitar obstáculos del TileMapComponent (agua, ruinas). Esto justifica que el Kijin es un cazador táctico.
Con estos componentes modulares, usted tiene el esqueleto funcional para comenzar el desarrollo del Sector 2, pero con la inteligencia arquitectónica necesaria para soportar la profundidad narrativa y el desafío de la Caída completa.