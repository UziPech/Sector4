import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../components/player.dart';
import '../components/mel.dart';
import '../../combat/weapon_system.dart';

import '../expediente_game.dart';

/// HUD del juego - Muestra información vital
class GameHUD extends PositionComponent with HasGameReference<ExpedienteKorinGame> {
  final PlayerCharacter player;
  final MelCharacter mel;
  
  GameHUD({
    required this.player,
    required this.mel,
  }) : super(priority: 100); // Alto priority para renderizar encima
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
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
    
    // Texto de vida de Dan
    _drawText(canvas, 'DAN', 20, 25, Colors.white, bold: true);
    
    // Barra de vida de Dan
    _drawHealthBar(canvas, 20, 45, 250, player.health, player.maxHealth, Colors.green);
    
    // Texto de Mel
    _drawText(canvas, 'MEL - SOPORTE VITAL', 20, 75, Colors.cyan, bold: true);
    
    // Indicador de cooldown de Mel
    if (mel.canHeal) {
      _drawText(canvas, 'DISPONIBLE (E)', 20, 95, Colors.yellow);
    } else {
      final progress = (mel.healCooldownProgress * 100).toInt();
      _drawText(canvas, 'RECARGANDO: $progress%', 20, 95, Colors.orange);
      _drawCooldownBar(canvas, 20, 110, 250, mel.healCooldownProgress);
    }

    // --- WEAPON HOTBAR ---
    _drawWeaponHotbar(canvas);
  }

  void _drawWeaponHotbar(Canvas canvas) {
    final inventory = player.weaponInventory;
    if (inventory.weapons.isEmpty) return;

    const double slotSize = 60.0;
    const double spacing = 10.0;
    final double totalWidth = (inventory.weapons.length * slotSize) + ((inventory.weapons.length - 1) * spacing);
    final double startX = (game.size.x - totalWidth) / 2;
    final double startY = game.size.y - slotSize - 20.0;

    for (int i = 0; i < inventory.weapons.length; i++) {
      final weapon = inventory.weapons[i];
      final isSelected = inventory.currentWeapon == weapon;
      final x = startX + (i * (slotSize + spacing));
      
      // Slot Background
      final slotRect = Rect.fromLTWH(x, startY, slotSize, slotSize);
      final slotPaint = Paint()
        ..color = isSelected ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.5)
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
        bold: isSelected
      );

      // Ammo Count (if Ranged)
      if (weapon is RangedWeapon) {
        Color ammoColor = Colors.white;
        if (weapon.currentAmmo == 0) {
          ammoColor = Colors.red;
          _drawText(canvas, 'RELOAD (R)', x + 5, startY + slotSize + 5, Colors.red, bold: true);
        } else if (weapon.currentAmmo < weapon.maxAmmo * 0.3) {
          ammoColor = Colors.yellow;
          _drawText(canvas, 'RELOAD (R)', x + 5, startY + slotSize + 5, Colors.yellow, bold: true);
        }
        
        _drawText(
          canvas, 
          '${weapon.currentAmmo}/${weapon.maxAmmo}', 
          x + 5, 
          startY + slotSize - 20, 
          ammoColor
        );
      } else {
         _drawText(
          canvas, 
          '∞', 
          x + 5, 
          startY + slotSize - 20, 
          Colors.white
        );
      }
      
      // Key Hint (1, 2, etc - though we use Q to switch, let's show index+1)
      _drawText(
        canvas, 
        '${i + 1}', 
        x + slotSize - 15, 
        startY + 5, 
        Colors.grey
      );
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
    canvas.drawRect(
      Rect.fromLTWH(x, y, width, 20),
      bgPaint,
    );
    
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
    canvas.drawRect(
      Rect.fromLTWH(x, y, width, 20),
      borderPaint,
    );
    
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
    canvas.drawRect(
      Rect.fromLTWH(x, y, width, 10),
      bgPaint,
    );
    
    // Progreso
    final progressPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(x, y, width * progress, 10),
      progressPaint,
    );
    
    // Borde
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(
      Rect.fromLTWH(x, y, width, 10),
      borderPaint,
    );
  }
}
