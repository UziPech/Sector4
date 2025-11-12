import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../main.dart';

/// HUD (Heads-Up Display) - Muestra información vital del jugador
class HudComponent extends PositionComponent with HasGameReference<ExpedienteKorinGame> {
  late TextComponent healthText;
  late TextComponent melCooldownText;
  late TextComponent scoreText;
  late TextComponent waveText;
  late RectangleComponent healthBar;
  late RectangleComponent healthBarBg;
  late RectangleComponent melCooldownBar;
  late RectangleComponent melCooldownBarBg;
  
  final TextPaint textPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  );
  
  final TextPaint melReadyPaint = TextPaint(
    style: const TextStyle(
      color: Colors.greenAccent,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  );
  
  final TextPaint melCooldownPaint = TextPaint(
    style: const TextStyle(
      color: Colors.redAccent,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Posición fija en la esquina superior izquierda
    position = Vector2(20, 20);
    
    // Barra de vida - Fondo
    healthBarBg = RectangleComponent(
      position: Vector2(0, 30),
      size: Vector2(200, 20),
      paint: Paint()..color = const Color.fromRGBO(244, 67, 54, 0.3),
    );
    add(healthBarBg);
    
    // Barra de vida - Actual
    healthBar = RectangleComponent(
      position: Vector2(0, 30),
      size: Vector2(200, 20),
      paint: Paint()..color = Colors.green,
    );
    add(healthBar);
    
    // Texto de vida
    healthText = TextComponent(
      text: 'Vida: 100/100',
      textRenderer: textPaint,
      position: Vector2(0, 0),
    );
    add(healthText);
    
    // Barra de cooldown de Mel - Fondo
    melCooldownBarBg = RectangleComponent(
      position: Vector2(0, 80),
      size: Vector2(200, 20),
      paint: Paint()..color = const Color.fromRGBO(33, 150, 243, 0.3),
    );
    add(melCooldownBarBg);
    
    // Barra de cooldown de Mel - Actual
    melCooldownBar = RectangleComponent(
      position: Vector2(0, 80),
      size: Vector2(200, 20),
      paint: Paint()..color = Colors.cyan,
    );
    add(melCooldownBar);
    
    // Texto de Mel
    melCooldownText = TextComponent(
      text: 'Mel: LISTO',
      textRenderer: melReadyPaint,
      position: Vector2(0, 55),
    );
    add(melCooldownText);
    
    // Texto de puntuación
    scoreText = TextComponent(
      text: 'Puntos: 0',
      textRenderer: textPaint,
      position: Vector2(0, 110),
    );
    add(scoreText);
    
    // Texto de oleada
    waveText = TextComponent(
      text: 'Oleada: 1',
      textRenderer: textPaint,
      position: Vector2(0, 135),
    );
    add(waveText);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Actualizar vida
    final player = game.player;
    final healthPercent = player.health / player.maxHealth;
    healthBar.size.x = 200 * healthPercent;
    healthText.text = 'Vida: ${player.health.toInt()}/${player.maxHealth.toInt()}';
    
    // Actualizar color de la barra de vida según el porcentaje
    if (healthPercent > 0.6) {
      healthBar.paint.color = Colors.green;
    } else if (healthPercent > 0.3) {
      healthBar.paint.color = Colors.orange;
    } else {
      healthBar.paint.color = Colors.red;
    }
    
    // Actualizar cooldown de Mel
    if (game.isMelReady) {
      melCooldownText.text = 'Mel: LISTO';
      melCooldownText.textRenderer = melReadyPaint;
      melCooldownBar.size.x = 200;
      melCooldownBar.paint.color = Colors.cyan;
    } else {
      final cooldownPercent = game.melTimeElapsed / game.melCooldownTime;
      final timeRemaining = (game.melCooldownTime - game.melTimeElapsed).toInt();
      melCooldownText.text = 'Mel: ${timeRemaining}s';
      melCooldownText.textRenderer = melCooldownPaint;
      melCooldownBar.size.x = 200 * cooldownPercent;
      melCooldownBar.paint.color = Colors.grey;
    }
    
    // Actualizar puntuación
    scoreText.text = 'Puntos: ${game.score}';
    
    // Actualizar oleada
    waveText.text = 'Oleada: ${game.enemySpawner?.currentWave ?? 1}';
  }
}
