import 'package:flutter/material.dart';
import 'package:flame_audio/flame_audio.dart';
import '../expediente_game.dart';
import '../../narrative/screens/menu_screen.dart';

class GameUI extends StatefulWidget {
  final ExpedienteKorinGame game;

  const GameUI({Key? key, required this.game}) : super(key: key);

  @override
  State<GameUI> createState() => _GameUIState();
}

class _GameUIState extends State<GameUI> {
  bool _isConfigOpen = false;
  double _volume = 1.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. BOTÓN DE CONFIGURACIÓN (Top Right - Movido para visibilidad)
        Positioned(
          top: 15,
          right: 15,
          child: SafeArea(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isConfigOpen = !_isConfigOpen;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isConfigOpen ? 220 : 50,
                height: _isConfigOpen ? 160 : 50,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: _isConfigOpen
                    ? _buildConfigPanel()
                    : const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 28,
                      ),
              ),
            ),
          ),
        ),

        // 2. PANEL NARRATIVO (Top Left - Ajustado a realidad visual)
        Positioned(
          top: 15,
          left: 15,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ValueListenableBuilder<String>(
                    valueListenable: widget.game.chapterNameNotifier,
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
                  ValueListenableBuilder<String>(
                    valueListenable: widget.game.locationNotifier,
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
                  ValueListenableBuilder<String>(
                    valueListenable: widget.game.objectiveNotifier,
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
        ),

        // 3. GUÍA DE CONTROLES (Bottom Left)
        Positioned(
          bottom: 15,
          left: 15,
          child: SafeArea(
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
        ),
      ],
    );
  }

  Widget _buildConfigPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con botón de cerrar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'CONFIGURACIÓN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isConfigOpen = false;
                });
              },
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ],
        ),
        const Divider(color: Colors.white54),
        
        // Control de Volumen
        const Text(
          'Volumen',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        SizedBox(
          height: 30,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: _volume,
              activeColor: Colors.greenAccent,
              inactiveColor: Colors.grey,
              onChanged: (value) {
                setState(() {
                  _volume = value;
                  // Ajustar volumen global (BGM)
                  FlameAudio.bgm.audioPlayer.setVolume(_volume);
                });
              },
            ),
          ),
        ),

        const Spacer(),

        // Botón Salir
        SizedBox(
          width: double.infinity,
          height: 30,
          child: ElevatedButton(
            onPressed: () {
              // Confirmar salida
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text('¿Salir al Menú?', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'Perderás el progreso no guardado.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Cerrar diálogo
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const MenuScreen()),
                        );
                      },
                      child: const Text('Salir', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.8),
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'SALIR AL MENÚ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
