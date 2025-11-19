import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../game/expediente_game.dart';
import '../game/components/player.dart';
import '../components/bullet.dart';
import '../components/character_component.dart';
import '../components/enemy_character.dart';

/// Clase base para todas las armas
abstract class Weapon {
  final String name;
  final double damage;
  final double cooldown;
  double _timeSinceLastAttack = 0;
  bool _canAttack = true;

  Weapon({
    required this.name,
    required this.damage,
    required this.cooldown,
  });

  void update(double dt) {
    if (!_canAttack) {
      _timeSinceLastAttack += dt;
      if (_timeSinceLastAttack >= cooldown) {
        _canAttack = true;
        _timeSinceLastAttack = 0;
      }
    }
  }

  bool tryAttack(CharacterComponent owner, ExpedienteKorinGame game);
}

/// Arma cuerpo a cuerpo (Cuchillo del Diente Caótico)
class MeleeWeapon extends Weapon {
  final double range;
  final double arcAngle;

  MeleeWeapon({
    required super.name,
    required super.damage,
    super.cooldown = 0.5,
    this.range = 60.0,
    this.arcAngle = 1.5, // ~90 grados
  });

  @override
  bool tryAttack(CharacterComponent owner, ExpedienteKorinGame game) {
    if (!_canAttack) return false;
    _canAttack = false;

    // Lógica de hitbox melee
    // Buscamos enemigos cercanos en la dirección que mira el jugador
    final ownerPos = (owner as PositionComponent).position;
    // Asumimos que el owner tiene una dirección o usamos el joystick/mouse
    // Por simplicidad, usaremos un radio alrededor del jugador por ahora,
    // o idealmente, un cono frente a él.
    
    // TODO: Obtener dirección real del jugador. Por ahora, radio simple.
    bool hitSomething = false;
    
    game.world.children.query<EnemyCharacter>().forEach((enemy) {
      final distance = enemy.position.distanceTo(ownerPos);
      if (distance <= range) {
        // Aplicar daño
        enemy.receiveDamage(damage);
        hitSomething = true;
        // Efecto visual de golpe
        // game.add(ParticleEffect(...));
      }
    });

    return hitSomething;
  }
}

/// Arma a distancia (Pistola Estándar)
class RangedWeapon extends Weapon {
  int maxAmmo;
  int currentAmmo;
  final double projectileSpeed;

  RangedWeapon({
    required super.name,
    required super.damage,
    super.cooldown = 0.2,
    this.maxAmmo = 20,
    this.projectileSpeed = 400.0,
  }) : currentAmmo = maxAmmo;

  @override
  bool tryAttack(CharacterComponent owner, ExpedienteKorinGame game) {
    if (!_canAttack || currentAmmo <= 0) return false;
    _canAttack = false;
    currentAmmo--;

    // Calcular dirección (hacia el mouse o joystick)
    // Por ahora, usaremos una dirección por defecto o la última dirección de movimiento
    // Necesitamos acceso a la dirección de apuntado del jugador.
    Vector2 direction = Vector2(1, 0); // Placeholder
    if (owner is PlayerCharacter) {
       // Intentar obtener dirección del joystick o movimiento
       if (owner.lastMoveDirection != Vector2.zero()) {
         direction = owner.lastMoveDirection;
       }
    }

    final ownerPos = (owner as PositionComponent).position;
    
    final bullet = Bullet(
      position: ownerPos + direction * 20, // Offset para que no salga del centro
      direction: direction,
      speed: projectileSpeed,
      damage: damage,
      isPlayerBullet: true,
    );
    
    game.world.add(bullet);
    return true;
  }

  void reload() {
    currentAmmo = maxAmmo;
  }
}

/// Componente de inventario para manejar las armas
class WeaponInventory extends Component {
  final List<Weapon> weapons = [];
  int _currentIndex = 0;

  Weapon? get currentWeapon => weapons.isNotEmpty ? weapons[_currentIndex] : null;

  void addWeapon(Weapon weapon) {
    weapons.add(weapon);
  }

  void nextWeapon() {
    if (weapons.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % weapons.length;
  }

  void previousWeapon() {
    if (weapons.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + weapons.length) % weapons.length;
  }
  
  void equipWeapon(int index) {
    if (index >= 0 && index < weapons.length) {
      _currentIndex = index;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final weapon in weapons) {
      weapon.update(dt);
    }
  }
}
