import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/expediente_game.dart';
import '../game/components/enemies/irracional.dart';
import '../game/components/enemies/yurei_kohaa.dart'; // Para atacar al boss Kijin
import '../game/components/bosses/on_oyabun_boss.dart';
import '../game/components/enemies/minions/yakuza_ghost.dart';
import '../game/components/enemies/minions/floating_katana.dart'; // Para atacar a On-Oyabun
import '../game/components/player.dart';
import '../components/bullet.dart';
import '../components/character_component.dart';
import '../components/enemy_character.dart';
import '../game/audio_manager.dart';

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

/// Arma cuerpo a cuerpo (Cuchillo del Diente CaÃƒÂ³tico)
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

    // LÃƒÂ³gica de hitbox melee
    // Buscamos enemigos cercanos en la direcciÃƒÂ³n que mira el jugador
    final ownerPos = (owner as PositionComponent).position;
    
    // Obtener direcciÃƒÂ³n de ataque
    Vector2 attackDirection = Vector2(1, 0);
    if (owner is PlayerCharacter) {
      attackDirection = owner.lastMoveDirection;
    }
    
    // Crear efecto visual de slash
    final slashEffect = MeleeSlashEffect(
      position: ownerPos + attackDirection * 30,
      direction: attackDirection,
      range: range,
    );
    game.world.add(slashEffect);
    
    bool hitSomething = false;
    
    // DaÃƒÂ±ar enemigos (EnemyCharacter)
    game.world.children.query<EnemyCharacter>().forEach((enemy) {
      final distance = enemy.position.distanceTo(ownerPos);
      if (distance <= range) {
        // Aplicar daÃƒÂ±o completo a enemigos
        enemy.receiveDamage(damage);
        hitSomething = true;
      }
    });

    game.world.children.query<IrrationalEnemy>().forEach((enemy) {
      final distance = enemy.position.distanceTo(ownerPos);
      if (distance <= range) {
        enemy.takeDamage(damage);
        hitSomething = true;
      }
    });
    
    // DaÃƒÂ±ar bosses (YureiKohaa y OnOyabunBoss)
    game.world.children.query<YureiKohaa>().forEach((boss) {
      final distance = boss.position.distanceTo(ownerPos);
      if (distance <= range) {
        boss.takeDamage(damage);
        hitSomething = true;
        // print('Ã¢Å¡â€Ã¯Â¸Â Cuchillo golpeÃƒÂ³ a KOHAA: $damage daÃƒÂ±o');
      }
    });

    game.world.children.query<OnOyabunBoss>().forEach((boss) {
      final distance = boss.position.distanceTo(ownerPos);
      if (distance <= range) {
        boss.takeDamage(damage);
        hitSomething = true;
        // print('Ã¢Å¡â€Ã¯Â¸Â Cuchillo golpeÃƒÂ³ a ON-OYABUN: $damage daÃƒÂ±o');
      }
    });
    
    // DaÃƒÂ±ar minions del jefe
    game.world.children.query<YakuzaGhost>().forEach((minion) {
      final distance = minion.position.distanceTo(ownerPos);
      if (distance <= range) {
        minion.takeDamage(damage);
        hitSomething = true;
      }
    });

    game.world.children.query<FloatingKatana>().forEach((minion) {
      final distance = minion.position.distanceTo(ownerPos);
      if (distance <= range) {
        minion.takeDamage(damage);
        hitSomething = true;
      }
    });
    
    // DaÃƒÂ±ar objetos destructibles (ObsessionObject y DestructibleObject)
    // El cuchillo hace 50% del daÃƒÂ±o a objetos (tarda el doble)
    final objectDamage = damage * 0.5;
    
    for (final child in game.world.children) {
      if (child is PositionComponent) {
        final distance = child.position.distanceTo(ownerPos);
        
        if (distance <= range) {
          // Intentar daÃƒÂ±ar ObsessionObject
          if (child.runtimeType.toString().contains('ObsessionObject')) {
            try {
              (child as dynamic).takeDamage(objectDamage);
              hitSomething = true;
            } catch (e) {
              // Error al daÃƒÂ±ar objeto
            }
          }
          // Intentar daÃƒÂ±ar DestructibleObject
          else if (child.runtimeType.toString().contains('DestructibleObject')) {
            try {
              (child as dynamic).takeDamage(objectDamage);
              hitSomething = true;
            } catch (e) {
              // Error al  daÃƒÂ±ar objeto
            }
          }
        }
      }
    }

    if (hitSomething) {
      AudioManager().playAttackSfx();
    }

    return hitSomething;
  }
}

/// Arma a distancia (Pistola EstÃƒÂ¡ndar)
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

    // Calcular direcciÃƒÂ³n (hacia el mouse o joystick)
    // Por ahora, usaremos una direcciÃƒÂ³n por defecto o la ÃƒÂºltima direcciÃƒÂ³n de movimiento
    // Necesitamos acceso a la direcciÃƒÂ³n de apuntado del jugador.
    Vector2 direction = Vector2(1, 0); // Placeholder
    if (owner is PlayerCharacter) {
       // Intentar obtener direcciÃƒÂ³n del joystick o movimiento
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

/// Efecto visual de slash para ataques cuerpo a cuerpo
class MeleeSlashEffect extends PositionComponent {
  final Vector2 direction;
  final double range;
  double _lifetime = 0.0;
  static const double _duration = 0.15; // DuraciÃƒÂ³n del efecto
  
  MeleeSlashEffect({
    required Vector2 position,
    required this.direction,
    required this.range,
  }) : super(position: position, size: Vector2.all(range * 1.5)) {
    anchor = Anchor.center;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    _lifetime += dt;
    
    if (_lifetime >= _duration) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Calcular opacidad basada en el tiempo de vida
    final opacity = (1.0 - (_lifetime / _duration)).clamp(0.0, 1.0);
    
    // Calcular ÃƒÂ¡ngulo de la direcciÃƒÂ³n
    final angle = direction.angleToSigned(Vector2(1, 0));
    
    canvas.save();
    canvas.rotate(-angle);
    
    // Dibujar arco de slash
    final paint = Paint()
      ..color = Colors.cyan.withValues(alpha: opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: range * 2,
      height: range * 2,
    );
    
    // Arco de 120 grados
    canvas.drawArc(
      rect,
      -1.0, // ÃƒÂngulo inicial
      2.0,  // ÃƒÂngulo de barrido
      false,
      paint,
    );
    
    // LÃƒÂ­neas de efecto adicionales
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawLine(
      const Offset(0, 0),
      Offset(range * 0.8, -range * 0.3),
      linePaint,
    );
    canvas.drawLine(
      const Offset(0, 0),
      Offset(range * 0.8, range * 0.3),
      linePaint,
    );
    
    canvas.restore();
  }
}


