import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'components/enemy_character.dart';
import 'components/character_component.dart';
import 'components/bullet.dart';
import 'components/hud_component.dart';
import 'components/joystick_component.dart';
import 'components/world_bounds.dart';
import 'components/enemy_spawner.dart';
import 'components/particle_effect.dart';
import 'components/infinite_world.dart';
import 'narrative/screens/menu_screen.dart';

void main() {
  // Inicializa y corre la aplicación (ahora empieza en el menú)
  runApp(const ExpedienteKorinApp());
}

/// Aplicación principal - Inicia en el menú
class ExpedienteKorinApp extends StatelessWidget {
  const ExpedienteKorinApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MenuScreen(),
    );
  }
}

/// Widget para el juego de combate (usado después de las escenas narrativas)
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: ExpedienteKorinGame(),
        overlayBuilderMap: {
          'GameOver': (context, game) => GameOverOverlay(
            game: game as ExpedienteKorinGame,
          ),
        },
      ),
    );
  }
}

/// Dan - El jugador principal (La Culpa y Vulnerabilidad)
class PlayerCharacter extends PositionComponent
    with
        KeyboardHandler,
        HasGameReference<ExpedienteKorinGame>,
        CharacterComponent,
        CollisionCallbacks {
  static final _paint = BasicPalette.green.paint()..style = PaintingStyle.fill;
  static const double _size = 32.0;

  final double _speed = 200.0;
  final Vector2 _velocity = Vector2.zero();
  
  // Control móvil
  Vector2? _joystickDirection;

  // Control de disparo
  bool _canShoot = true;
  static const double _shootCooldown = 0.25; // REDUCIDO de 0.5 a 0.25 - dispara más rápido
  double _timeSinceLastShot = 0.0;

  @override
  void onMount() {
    super.onMount();
    size = Vector2.all(_size);
    anchor = Anchor.center;
    initHealth(100); // Inicializar con 100 de vida (Dan)
    baseSpeed = _speed; // Configurar velocidad base

    // Agregar hitbox para colisiones
    add(RectangleHitbox()..collisionType = CollisionType.active);
  }

  @override
  void onDeath() {
    // Lógica de Game Over (La Caída Final)
    game.gameOver();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Efecto visual de invencibilidad (parpadeo)
    if (!isInvincible || (invincibilityElapsed * 10).toInt() % 2 == 0) {
      canvas.drawCircle(Offset.zero, _size, _paint);
    }
    
    // La barra de vida se muestra en el HUD, no sobre el jugador
    // renderHealthBar(canvas);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Actualizar sistema de invencibilidad
    updateInvincibility(dt);

    // Actualizar cooldown de disparo
    if (!_canShoot) {
      _timeSinceLastShot += dt;
      if (_timeSinceLastShot >= _shootCooldown) {
        _canShoot = true;
        _timeSinceLastShot = 0.0;
      }
    }

    // Usar joystick si está activo, sino usar teclado
    Vector2 moveVelocity = _velocity;
    if (_joystickDirection != null && _joystickDirection!.length > 0.1) {
      moveVelocity = _joystickDirection!;
    }

    // Determinar tipo de movimiento
    if (moveVelocity.length > 0.1) {
      currentMovement = MovementType.walking;
    } else {
      currentMovement = MovementType.idle;
    }

    // Normalizamos para evitar movimiento diagonal más rápido y aplicamos velocidad.
    final displacement = moveVelocity.normalized() * _speed * dt;
    position.add(displacement);
    
    // Sin límites rígidos - mundo infinito!
  }

  void shoot() {
    if (!_canShoot) return;

    // Dirección de disparo: hacia arriba por defecto
    // En móvil, disparará hacia donde se mueve
    // En PC, disparará hacia arriba (se puede mejorar con mouse tracking)
    Vector2 shootDirection;
    
    if (_joystickDirection != null && _joystickDirection!.length > 0.1) {
      // Si hay movimiento de joystick, disparar en esa dirección
      shootDirection = _joystickDirection!.normalized();
    } else if (_velocity.length > 0.1) {
      // Si hay movimiento de teclado, disparar en esa dirección
      shootDirection = _velocity.normalized();
    } else {
      // Por defecto, disparar hacia arriba
      shootDirection = Vector2(0, -1);
    }

    // Crear y añadir la bala
    final bullet = Bullet(
      position: position.clone() + shootDirection * _size,
      direction: shootDirection,
      isPlayerBullet: true,
    );

    game.world.add(bullet);
    _canShoot = false;
    _timeSinceLastShot = 0.0;
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    Vector2 newVelocity = Vector2.zero();

    if (keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      newVelocity.y = -1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) ||
        keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      newVelocity.y = 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      newVelocity.x = -1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      newVelocity.x = 1;
    }

    // Disparar con la tecla espacio
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      shoot();
    }
    
    // Activar curación de Mel con la tecla E
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyE) {
      game.activateMelHeal();
    }
    
    // Pausa con ESC
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      game.togglePause();
    }

    _velocity.setFrom(newVelocity);

    return true; // El evento ha sido manejado.
  }
}

/// La clase principal de nuestro juego (El Duelo).
class ExpedienteKorinGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  // Referencia al jugador para poder moverlo o acceder a él.
  late final PlayerCharacter player;
  
  // Sistema de Mel (La Ancla/Semilla del Ángel Caído)
  double melCooldownTime = 15.0; // 15 segundos de cooldown para Soporte Vital
  double melTimeElapsed = 0.0;
  bool isMelReady = true;
  
  // Estado del juego
  bool isGameOver = false;
  bool isPaused = false;
  
  // Sistema de puntuación
  int score = 0;
  
  // Límites del mundo (ahora solo para referencia de tamaño, no límites rígidos)
  WorldBounds? worldBounds;
  
  // Mundo infinito
  InfiniteWorld? infiniteWorld;
  
  // Sistema de spawn
  EnemySpawner? enemySpawner;
  
  // Controles móviles
  MobileJoystick? joystick;
  ShootButtonComponent? shootButton;
  HealButtonComponent? healButton;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Configurar mundo infinito
    infiniteWorld = InfiniteWorld(seed: DateTime.now().millisecondsSinceEpoch);
    world.add(infiniteWorld!);
    
    // Configurar límites del mundo (solo para referencia, no límites rígidos)
    worldBounds = WorldBounds(
      width: 10000, // Mundo muy grande para spawn
      height: 10000,
      padding: 50,
    );

    // Crea y añade al jugador al WORLD
    player = PlayerCharacter()..position = Vector2(0, 0);
    world.add(player);
    
    // Conectar jugador al mundo infinito
    infiniteWorld!.player = player;

    // Configurar cámara para seguir al jugador
    camera.viewfinder.anchor = Anchor.center;
    camera.follow(player);
    
    // Sistema de spawn de enemigos (ahora usa mundo infinito)
    enemySpawner = EnemySpawner(worldBounds: worldBounds!);
    world.add(enemySpawner!);
    
    // Agregar HUD
    final hud = HudComponent();
    camera.viewport.add(hud);
    
    // Agregar controles móviles
    _setupMobileControls();
  }
  
  void _setupMobileControls() {
    // Joystick en la esquina inferior izquierda
    joystick = MobileJoystick(
      position: Vector2(100, size.y - 100),
    );
    camera.viewport.add(joystick!);
    
    // Botón de disparo en la esquina inferior derecha
    shootButton = ShootButtonComponent(
      position: Vector2(size.x - 100, size.y - 100),
      onPressed: () => player.shoot(),
    );
    camera.viewport.add(shootButton!);
    
    // Botón de curación arriba del botón de disparo
    healButton = HealButtonComponent(
      position: Vector2(size.x - 100, size.y - 200),
      onPressed: () => activateMelHeal(),
    );
    camera.viewport.add(healButton!);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (isGameOver || isPaused) return;
    
    // Actualizar dirección del joystick
    if (joystick != null && joystick!.isActive) {
      player._joystickDirection = joystick!.direction;
    } else {
      player._joystickDirection = null;
    }
    
    // Actualizar estado del botón de curación
    if (healButton != null) {
      healButton!.isReady = isMelReady;
    }
    
    // Lógica de Cooldown de Mel
    if (!isMelReady) {
      melTimeElapsed += dt;
      if (melTimeElapsed >= melCooldownTime) {
        isMelReady = true;
        melTimeElapsed = 0.0;
      }
    }
  }
  
  /// Función de Soporte Vital (Curación de Mel)
  void activateMelHeal() {
    if (isMelReady && !player.isDead) {
      // Aplicar curación completa a Dan
      player.heal(player.maxHealth);
      isMelReady = false;
      melTimeElapsed = 0.0;
      
      // Efecto visual de curación
      final healEffect = HealEffect(position: player.position.clone());
      world.add(healEffect);
    }
  }
  
  /// Game Over (La Caída Final)
  void gameOver() {
    isGameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }
  
  /// Reiniciar el juego
  void restart() {
    overlays.remove('GameOver');
    isGameOver = false;
    
    // Reiniciar estado del jugador
    player.position = Vector2.zero();
    player.initHealth(100); // Esto ahora también resetea _isDead
    player.isInvincible = false;
    player.invincibilityElapsed = 0.0;
    
    // Reiniciar Mel
    isMelReady = true;
    melTimeElapsed = 0.0;
    
    // Reiniciar puntuación
    score = 0;
    
    // Reiniciar spawner
    enemySpawner?.reset();
    
    // Reiniciar mundo infinito
    infiniteWorld?.reset();
    
    // Eliminar todos los enemigos y balas del world
    world.children.whereType<EnemyCharacter>().toList().forEach((e) => e.removeFromParent());
    world.children.whereType<Bullet>().toList().forEach((b) => b.removeFromParent());
    world.children.whereType<ParticleEffect>().toList().forEach((p) => p.removeFromParent());
    world.children.whereType<HealEffect>().toList().forEach((h) => h.removeFromParent());
    
    resumeEngine();
  }
  
  /// Alternar pausa
  void togglePause() {
    isPaused = !isPaused;
    if (isPaused) {
      pauseEngine();
    } else {
      resumeEngine();
    }
  }
  
  /// Agregar puntos
  void addScore(int points) {
    score += points;
  }
}

/// Overlay de Game Over
class GameOverOverlay extends StatelessWidget {
  final ExpedienteKorinGame game;
  
  const GameOverOverlay({super.key, required this.game});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(0, 0, 0, 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'LA CAÍDA FINAL',
              style: TextStyle(
                color: Colors.red,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Dan ha sucumbido a la corrupción',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Puntuación Final: ${game.score}',
              style: const TextStyle(
                color: Colors.yellowAccent,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Oleada: ${game.enemySpawner?.currentWave ?? 1}',
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => game.restart(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
              ),
              child: const Text(
                'REINTENTAR',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
