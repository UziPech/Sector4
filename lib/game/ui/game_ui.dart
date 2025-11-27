import 'package:flutter/material.dart';
import '../expediente_game.dart';

class GameUI extends StatelessWidget {
  final ExpedienteKorinGame game;

  const GameUI({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Panel Narrativo (Top Right - movido para no chocar con HUD de vidas)
        Positioned(
          top: 15,
          right: 15,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end, // Alineado a la derecha
              children: [
                // Capítulo
                ValueListenableBuilder<String>(
                  valueListenable: game.chapterNameNotifier,
                  builder: (context, value, child) {
                    return Text(
                      value.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.right,
                    );
                  },
                ),
                const SizedBox(height: 4),
                // Ubicación
                ValueListenableBuilder<String>(
                  valueListenable: game.locationNotifier,
                  builder: (context, value, child) {
                    return Text(
                      value,
                      style: TextStyle(
                        color: Colors.cyanAccent.withOpacity(0.9),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.right,
                    );
                  },
                ),
                const SizedBox(height: 2),
                // Objetivo
                ValueListenableBuilder<String>(
                  valueListenable: game.objectiveNotifier,
                  builder: (context, value, child) {
                    return Text(
                      'Objetivo: $value',
                      style: TextStyle(
                        color: Colors.amberAccent.withOpacity(0.9),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.right,
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Guía de Controles (Bottom Left - balanceado)
        Positioned(
          bottom: 15,
          left: 15,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'WASD/Flechas: Mover',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'E: Interactuar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
