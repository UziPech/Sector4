import 'package:flutter/material.dart';
import 'package:flame_audio/flame_audio.dart';
import '../expediente_game.dart';
import '../../game/audio_manager.dart';
import '../../narrative/screens/menu_screen.dart';

import 'package:flame/game.dart'; // Para Vector2
import 'dynamic_joystick_overlay.dart';

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
        // 0. JOYSTICK DINÁMICO (Siempre activo para consistencia con HouseScene)
        DynamicJoystickOverlay(
          onInput: (input) {
            widget.game.updateJoystickInput(input);
          },
        ),

        // 1. BOTÓN DE CONFIGURACIÓN (Top Right - Movido para visibilidad)
        // 1. BOTÓN DE CONFIGURACIÓN (Top Right - Movido para visibilidad)
        Positioned(
          top: 15,
          right: 15,
          child: SafeArea(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isConfigOpen = !_isConfigOpen;
                  if (_isConfigOpen) {
                    widget.game.pauseEngine(); // Pausar Flame
                  } else {
                    widget.game.resumeEngine(); // Reanudar Flame
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isConfigOpen ? 280 : 50,
                height: _isConfigOpen ? 340 : 50,
                padding: _isConfigOpen ? const EdgeInsets.all(12) : const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: _isConfigOpen
                    ? OverflowBox(
                        minWidth: 276,
                        maxWidth: 276,
                        minHeight: 336,
                        maxHeight: 336,
                        alignment: Alignment.center,
                        child: Material(
                          type: MaterialType.transparency,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: _buildConfigPanel(),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 28,
                      ),
              ),
            ),
          ),
        ),

        // 2. PANEL NARRATIVO (Top Right - Movido para evitar solapamiento con HUD de Vida)
        Positioned(
          top: 15,
          right: 80, // A la izquierda del botón de configuración
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

        // 3. GUÍA DE CONTROLES (Bottom Left - Oculto en móviles)
        if (Theme.of(context).platform != TargetPlatform.android && 
            Theme.of(context).platform != TargetPlatform.iOS)
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
              'SISTEMA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isConfigOpen = false;
                  widget.game.resumeEngine(); // Reanudar juego Flame
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 20),
        
        // Control de Volumen Música
        Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.white70, size: 20),
            const SizedBox(width: 10),
            const Text(
              'AUDIO',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 30,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.grey[800],
              thumbColor: Colors.white,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: _volume,
              onChanged: (value) {
                setState(() {
                  _volume = value;
                  AudioManager().musicVolume = value;
                  FlameAudio.bgm.audioPlayer.setVolume(value);
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 15),

        // Control de SFX
        Row(
          children: [
            const Icon(Icons.graphic_eq, color: Colors.white70, size: 20),
            const SizedBox(width: 10),
            const Text(
              'EFECTOS (SFX)',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 30,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.grey[800],
              thumbColor: Colors.white,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: AudioManager().sfxVolume, // Usar valor actual de SFX
              onChanged: (value) {
                setState(() {
                  AudioManager().sfxVolume = value;
                });
              },
            ),
          ),
        ),

        const Spacer(),

        // Botón Salir
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(20),
                  child: Container(
                    width: 450,
                    height: 360,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/wood_card_bg.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 85, vertical: 50),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿ABORTAR MISIÓN?',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 18,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'El progreso no guardado se perderá.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontFamily: 'monospace',
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'CANCELAR',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 30),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (context) => const MenuScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.withOpacity(0.8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('CONFIRMAR', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.2),
              foregroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.redAccent),
              ),
              elevation: 0,
            ),
            child: const Text(
              'SALIR AL MENÚ',
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
