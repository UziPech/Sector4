import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../components/player.dart';
import '../components/mel.dart';
import '../systems/resurrection_system.dart';
import '../../combat/weapon_system.dart';

import 'package:flame/events.dart';
// For defaultTargetPlatform

import '../expediente_game.dart';

/// HUD del juego - Muestra informaciÃ³n vital
class GameHUD extends PositionComponent
    with HasGameReference<ExpedienteKorinGame> {
  final PlayerCharacter player;
  final MelCharacter mel;
  ResurrectionManager? resurrectionManager;

  GameHUD({required this.player, required this.mel, this.resurrectionManager})
    : super(priority: 100); // Alto priority para renderizar encima

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // NOTA: Los botones de acciÃ³n (Ataque, Q, R, E, Dash) ahora se renderizan
    // como Flutter widgets en GameUI para quedar ENCIMA del FlashlightLayer.
    // Este GameHUD solo mantiene el canvas de salud/vidas/hotbar de armas
    // como respaldo visual en el canvas de Flame.
  }

  @override
  void render(Canvas canvas) {
    // Todo el HUD ahora se renderiza como Flutter widget en GameUI
    // (encima del FlashlightLayer). No dibujar nada en el canvas de Flame.
  }
}

class AttackButtonComponent extends PositionComponent with TapCallbacks {
  final PlayerCharacter player;
  final ExpedienteKorinGame gameRef;

  AttackButtonComponent({required this.player, required this.gameRef})
    : super(priority: 101); // Mayor prioridad que el HUD

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(80, 80); // TamaÃ±o del botÃ³n
    // Posicionar en esquina inferior derecha
    position = Vector2(
      gameRef.size.x - size.x - 40,
      gameRef.size.y - size.y - 40,
    );
    anchor = Anchor.topLeft;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Dibujar cÃ­rculo relativo a 0,0 del componente
    final radius = size.x / 2;
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset(radius, radius), radius, borderPaint);

    // Icon (Simple lightning bolt shape)
    final iconPath = Path();
    final cx = radius;
    final cy = radius;
    final s = size.x * 0.4; // scale

    iconPath.moveTo(cx + s * 0.2, cy - s * 0.5);
    iconPath.lineTo(cx - s * 0.3, cy + s * 0.1);
    iconPath.lineTo(cx + s * 0.1, cy + s * 0.1);
    iconPath.lineTo(cx - s * 0.2, cy + s * 0.5);
    iconPath.lineTo(cx + s * 0.3, cy - s * 0.1);
    iconPath.lineTo(cx - s * 0.1, cy - s * 0.1);
    iconPath.close();

    canvas.drawPath(iconPath, Paint()..color = Colors.white);
  }

  @override
  void onTapDown(TapDownEvent event) {
    player.attack();
    super.onTapDown(event);
  }
}

class SwitchWeaponButtonComponent extends PositionComponent with TapCallbacks {
  final PlayerCharacter player;
  final ExpedienteKorinGame gameRef;

  SwitchWeaponButtonComponent({required this.player, required this.gameRef})
    : super(priority: 101);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(60, 60);
    // Posicionar arriba del botÃ³n de ataque
    position = Vector2(
      gameRef.size.x - size.x - 50,
      gameRef.size.y - size.y - 140,
    );
    anchor = Anchor.topLeft;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final radius = size.x / 2;
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(radius, radius), radius, borderPaint);

    // Icono de intercambio (flechas circulares simplificadas)
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(radius, radius), radius: radius * 0.5),
      0.5,
      5.0,
      false,
      iconPaint,
    );

    // Texto "Q"
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Q',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(radius - textPainter.width / 2, radius - textPainter.height / 2),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    player.weaponInventory.nextWeapon();
    super.onTapDown(event);
  }
}

class ReloadButtonComponent extends PositionComponent with TapCallbacks {
  final PlayerCharacter player;
  final ExpedienteKorinGame gameRef;

  ReloadButtonComponent({required this.player, required this.gameRef})
    : super(priority: 101);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(50, 50);
    // Posicionar a la izquierda del botÃ³n de ataque
    position = Vector2(
      gameRef.size.x - size.x - 140,
      gameRef.size.y - size.y - 55,
    );
    anchor = Anchor.topLeft;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Solo visible si el arma actual usa municiÃ³n
    final weapon = player.weaponInventory.currentWeapon;
    if (weapon is RangedWeapon) {
      if (weapon.currentAmmo < weapon.maxAmmo) {
        // Mostrar si necesita recarga
        // PodrÃ­amos hacerlo invisible o transparente
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Solo renderizar si es arma de rango
    final weapon = player.weaponInventory.currentWeapon;
    if (weapon is! RangedWeapon) return;

    super.render(canvas);

    final paint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final radius = size.x / 2;
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(radius, radius), radius, borderPaint);

    // Texto "R"
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'R',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(radius - textPainter.width / 2, radius - textPainter.height / 2),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    final weapon = player.weaponInventory.currentWeapon;
    if (weapon is RangedWeapon) {
      weapon.reload();
    }
    super.onTapDown(event);
  }
}

class ResurrectButtonComponent extends PositionComponent with TapCallbacks {
  final PlayerCharacter player;
  final ExpedienteKorinGame gameRef;

  ResurrectButtonComponent({required this.player, required this.gameRef})
    : super(priority: 101);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(60, 60);
    // Posicionar arriba del botÃ³n de ataque (donde irÃ­a el cambio de arma)
    position = Vector2(
      gameRef.size.x - size.x - 50,
      gameRef.size.y - size.y - 140,
    );
    anchor = Anchor.topLeft;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = Colors.purple.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final radius = size.x / 2;
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(radius, radius), radius, borderPaint);

    // Icono de calavera simplificado (E)
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Ojos
    canvas.drawCircle(Offset(radius - 8, radius - 5), 4, iconPaint);
    canvas.drawCircle(Offset(radius + 8, radius - 5), 4, iconPaint);
    // Nariz
    canvas.drawRect(
      Rect.fromCenter(center: Offset(radius, radius + 5), width: 4, height: 6),
      iconPaint,
    );

    // Texto "E"
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'E',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(radius - textPainter.width / 2, radius + 10),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    player.tryResurrect();
    super.onTapDown(event);
  }
}

class DashButtonComponent extends PositionComponent with TapCallbacks {
  final PlayerCharacter player;
  final ExpedienteKorinGame gameRef;

  DashButtonComponent({required this.player, required this.gameRef})
    : super(priority: 101);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(50, 50);
    // Posicionar a la izquierda del botÃ³n de ataque (donde irÃ­a la recarga)
    position = Vector2(
      gameRef.size.x - size.x - 140,
      gameRef.size.y - size.y - 55,
    );
    anchor = Anchor.topLeft;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final radius = size.x / 2;
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(radius, radius), radius, borderPaint);

    // Icono de velocidad (flecha doble)
    final iconPath = Path();
    iconPath.moveTo(radius - 5, radius - 10);
    iconPath.lineTo(radius + 5, radius);
    iconPath.lineTo(radius - 5, radius + 10);

    iconPath.moveTo(radius + 2, radius - 10);
    iconPath.lineTo(radius + 12, radius);
    iconPath.lineTo(radius + 2, radius + 10);

    canvas.drawPath(
      iconPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    player.tryDash();
    super.onTapDown(event);
  }
}
