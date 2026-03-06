import 'package:flutter/material.dart';
import '../../game/audio_manager.dart';
import 'package:flame_audio/flame_audio.dart';
import '../../narrative/screens/menu_screen.dart';

class SettingsOverlay extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onToggle;

  const SettingsOverlay({
    super.key,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  late double _volume;
  late double _sfxVolume;

  @override
  void initState() {
    super.initState();
    _volume = AudioManager().musicVolume;
    _sfxVolume = AudioManager().sfxVolume;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!widget.isOpen) {
          widget.onToggle();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        width: widget.isOpen ? 280 : 50,
        height: widget.isOpen ? 340 : 50,
        padding: EdgeInsets.zero,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: widget.isOpen
            ? OverflowBox(
                minWidth: 276,
                maxWidth: 276,
                minHeight: 336,
                maxHeight: 336,
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: _buildConfigPanel(),
                ),
              )
            : const Center(
                child: Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 28,
                ),
              ),
      ),
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
            ),
            GestureDetector(
              onTap: widget.onToggle,
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

        // Control de Volumen
        Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.white70, size: 20),
            const SizedBox(width: 10),
            const Text(
              'AUDIO',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
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
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
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
              value: _sfxVolume,
              onChanged: (value) {
                setState(() {
                  _sfxVolume = value;
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 85,
                      vertical: 50,
                    ),
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
                                  MaterialPageRoute(
                                    builder: (context) => const MenuScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.withValues(
                                  alpha: 0.8,
                                ),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'CONFIRMAR',
                                style: TextStyle(fontSize: 12),
                              ),
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
              backgroundColor: Colors.red.withValues(alpha: 0.2),
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
