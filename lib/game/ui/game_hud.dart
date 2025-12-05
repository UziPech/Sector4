import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../components/player.dart';
import '../components/mel.dart';
import '../models/player_role.dart';
import '../systems/resurrection_system.dart';
import '../../combat/weapon_system.dart';

import 'package:flame/events.dart';
import 'package:flutter/foundation.dart'; // For defaultTargetPlatform

import '../expediente_game.dart';

/// HUD del juego - Muestra información vital
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
    // Añadir botón de ataque si es móvil
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      add(AttackButtonComponent(player: player, gameRef: game));
    }
  }

  @override
  void render(Canvas canvas) {
    // No llamar a super.render(canvas) si no es necesario o si dibuja debug
    // super.render(canvas);

    // Fondo del HUD (Stats)
    final hudRect = Rect.fromLTWH(10, 10, 300, 120);
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawRect(hudRect, bgPaint);

    // Borde Stats
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(hudRect, borderPaint);

    // Texto del jugador (Dan o Mel)
    final playerName = player.playerRole == PlayerRole.dan ? 'DAN' : 'MEL';
    final playerColor = player.playerRole == PlayerRole.dan
        ? Colors.green
        : Colors.cyan;
    _drawText(canvas, playerName, 20, 25, Colors.white, bold: true);

    // Barra de vida del jugador
    _drawHealthBar(
      canvas,
      20,
      45,
      250,
      player.health,
      player.maxHealth,
      playerColor,
    );

    // Si el jugador es Mel, mostrar contador de resurrecciones
    if (player.playerRole == PlayerRole.mel && resurrectionManager != null) {
      _drawResurrectionCounter(canvas, 20, 75);
    } else {
      // Si el jugador es Dan, mostrar info de Mel companion
      _drawText(canvas, 'MEL - SOPORTE VITAL', 20, 75, Colors.cyan, bold: true);

      // Indicador de cooldown de Mel
      if (mel.canHeal) {
        _drawText(canvas, 'DISPONIBLE (E)', 20, 95, Colors.yellow);
      } else {
        final progress = (mel.healCooldownProgress * 100).toInt();
        _drawText(canvas, 'RECARGANDO: $progress%', 20, 95, Colors.orange);
        _drawCooldownBar(canvas, 20, 110, 250, mel.healCooldownProgress);
      }
    }

    // --- VIDAS RESTANTES ---
    _drawLivesCounter(canvas);

    // --- WEAPON HOTBAR ---
    _drawWeaponHotbar(canvas);
  }

  void _drawWeaponHotbar(Canvas canvas) {
    final inventory = player.weaponInventory;
    if (inventory.weapons.isEmpty) return;

    const double slotSize = 60.0;
    const double spacing = 10.0;
    final double totalWidth =
        (inventory.weapons.length * slotSize) +
        ((inventory.weapons.length - 1) * spacing);
    final double startX = (game.size.x - totalWidth) / 2;
    final double startY = game.size.y - slotSize - 20.0;

    for (int i = 0; i < inventory.weapons.length; i++) {
      final weapon = inventory.weapons[i];
      final isSelected = inventory.currentWeapon == weapon;
      final x = startX + (i * (slotSize + spacing));

      // Slot Background
      final slotRect = Rect.fromLTWH(x, startY, slotSize, slotSize);
      final slotPaint = Paint()
        ..color = isSelected
            ? Colors.white.withOpacity(0.3)
            : Colors.black.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      canvas.drawRect(slotRect, slotPaint);

      // Slot Border
      final slotBorderPaint = Paint()
        ..color = isSelected ? Colors.yellow : Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : 1;
      canvas.drawRect(slotRect, slotBorderPaint);

      // Weapon Name (Short)
      String shortName = weapon.name.split(' ').first;
      if (shortName.length > 4) shortName = shortName.substring(0, 4);

      _drawText(
        canvas,
        shortName,
        x + 5,
        startY + 5,
        isSelected ? Colors.yellow : Colors.white,
        bold: isSelected,
      );

      // Ammo Count (if Ranged)
      if (weapon is RangedWeapon) {
        Color ammoColor = Colors.white;
        if (weapon.currentAmmo == 0) {
          ammoColor = Colors.red;
          _drawText(
            canvas,
            'RELOAD (R)',
            x + 5,
            startY + slotSize + 5,
            Colors.red,
            bold: true,
          );
        } else if (weapon.currentAmmo < weapon.maxAmmo * 0.3) {
          ammoColor = Colors.yellow;
          _drawText(
            canvas,
            'RELOAD (R)',
            x + 5,
            startY + slotSize + 5,
            Colors.yellow,
            bold: true,
          );
        }

        _drawText(
          canvas,
          '${weapon.currentAmmo}/${weapon.maxAmmo}',
          x + 5,
          startY + slotSize - 20,
          ammoColor,
        );
      } else {
        _drawText(canvas, '∞', x + 5, startY + slotSize - 20, Colors.white);
      }

      // Key Hint (1, 2, etc - though we use Q to switch, let's show index+1)
      _drawText(canvas, '${i + 1}', x + slotSize - 15, startY + 5, Colors.grey);
    }
  }

  void _drawLivesCounter(Canvas canvas) {
    final lives = game.remainingLives;
    final maxLives = ExpedienteKorinGame.maxLives;

    // Posición en la esquina superior derecha
    const double startX = 320.0; // Junto al HUD de stats
    const double startY = 10.0;
    const double heartSize = 30.0;
    const double spacing = 35.0;

    // Fondo
    final bgRect = Rect.fromLTWH(
      startX,
      startY,
      (heartSize * maxLives) + (spacing * (maxLives - 1)) + 20,
      50,
    );
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawRect(bgRect, bgPaint);

    // Borde
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(bgRect, borderPaint);

    // Título
    _drawText(
      canvas,
      'VIDAS',
      startX + 10,
      startY + 5,
      Colors.white,
      bold: true,
    );

    // Dibujar corazones
    for (int i = 0; i < maxLives; i++) {
      final x = startX + 10 + (i * spacing);
      final y = startY + 25;
      final isAlive = i < lives;

      // Corazón (símbolo)
      final heartPaint = Paint()
        ..color = isAlive ? Colors.red : Colors.grey
        ..style = PaintingStyle.fill;

      // Dibujar un corazón simple como dos círculos y un triángulo
      final heartPath = Path();
      final cx = x + heartSize / 2;
      final cy = y + heartSize / 2;

      // Forma aproximada de corazón
      heartPath.moveTo(cx, cy - heartSize / 4);
      heartPath.quadraticBezierTo(
        cx - heartSize / 2,
        cy - heartSize / 2,
        cx - heartSize / 2,
        cy,
      );
      heartPath.quadraticBezierTo(
        cx - heartSize / 2,
        cy + heartSize / 4,
        cx,
        cy + heartSize / 2,
      );
      heartPath.quadraticBezierTo(
        cx + heartSize / 2,
        cy + heartSize / 4,
        cx + heartSize / 2,
        cy,
      );
      heartPath.quadraticBezierTo(
        cx + heartSize / 2,
        cy - heartSize / 2,
        cx,
        cy - heartSize / 4,
      );
      heartPath.close();

      canvas.drawPath(heartPath, heartPaint);

      // Brillo si está vivo
      if (isAlive) {
        final glowPaint = Paint()
          ..color = Colors.red.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawPath(heartPath, glowPaint);
      }
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    double x,
    double y,
    Color color, {
    bool bold = false,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: bold ? 14 : 12,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }

  void _drawHealthBar(
    Canvas canvas,
    double x,
    double y,
    double width,
    double current,
    double max,
    Color color,
  ) {
    // Fondo de la barra
    final bgPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(x, y, width, 20), bgPaint);

    // Barra de vida
    final healthPercent = (current / max).clamp(0.0, 1.0);
    final healthPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(x, y, width * healthPercent, 20),
      healthPaint,
    );

    // Borde
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(x, y, width, 20), borderPaint);

    // Texto de vida
    _drawText(
      canvas,
      '${current.toInt()} / ${max.toInt()}',
      x + width / 2 - 30,
      y + 4,
      Colors.white,
    );
  }

  void _drawCooldownBar(
    Canvas canvas,
    double x,
    double y,
    double width,
    double progress,
  ) {
    // Fondo
    final bgPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(x, y, width, 10), bgPaint);

    // Progreso
    final progressPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(x, y, width * progress, 10), progressPaint);

    // Borde
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(x, y, width, 10), borderPaint);
  }

  void _drawResurrectionCounter(Canvas canvas, double x, double y) {
    _drawText(canvas, 'SLOTS ALIADOS', x, y, Colors.purple, bold: true);

    if (resurrectionManager == null) return;

    final remaining = resurrectionManager!.resurrectionsRemaining;
    final max = resurrectionManager!.maxActiveAllies;

    // Dibujar orbes de resurrección
    const double orbSize = 15.0;
    const double orbSpacing = 25.0;
    final double orbY = y + 25;

    for (int i = 0; i < max; i++) {
      final orbX = x + (i * orbSpacing);
      final isAvailable = i < remaining;

      // Orbe
      final orbPaint = Paint()
        ..color = isAvailable
            ? Colors.purple.withOpacity(0.8)
            : Colors.grey.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(orbX + orbSize / 2, orbY + orbSize / 2),
        orbSize / 2,
        orbPaint,
      );

      // Borde del orbe
      final orbBorderPaint = Paint()
        ..color = isAvailable ? Colors.white : Colors.grey
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(
        Offset(orbX + orbSize / 2, orbY + orbSize / 2),
        orbSize / 2,
        orbBorderPaint,
      );

      // Efecto de brillo si está disponible
      if (isAvailable) {
        final glowPaint = Paint()
          ..color = Colors.purple.withOpacity(0.3)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(orbX + orbSize / 2, orbY + orbSize / 2),
          orbSize / 2 + 3,
          glowPaint,
        );
      }
    }

    // Texto de contador
    _drawText(
      canvas,
      '$remaining/$max',
      x + (max * orbSpacing) + 10,
      orbY,
      Colors.white,
    );
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
    size = Vector2(80, 80); // Tamaño del botón
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
      ..color = Colors.red.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Dibujar círculo relativo a 0,0 del componente
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
