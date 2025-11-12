import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Servicio para manejar todos los efectos de sonido y música del juego
class AudioService with WidgetsBindingObserver {
  // Instancia singleton
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  // Players separados para música y efectos
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _glitchPlayer = AudioPlayer();

  // Control de volumen
  double _musicVolume = 0.2; // 20% para música de fondo
  double _sfxVolume = 0.4; // 40% para efectos
  double _glitchVolume = 0.35; // 35% para glitch

  bool _isMusicPlaying = false;

  /// Inicializar el servicio de audio
  Future<void> initialize() async {
    // Configurar modo de loop
    await _musicPlayer.setReleaseMode(ReleaseMode.loop); // Loop para música
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    await _glitchPlayer.setReleaseMode(ReleaseMode.stop);
  }

  /// Reproducir música de fondo del login
  Future<void> playLoginMusic() async {
    if (!_isMusicPlaying) {
      try {
        await _musicPlayer.setVolume(_musicVolume);
        await _musicPlayer.play(AssetSource('audio/music/login_ambient.mp3'));
        _isMusicPlaying = true;
      } catch (e) {
        // Silenciar error si el navegador bloquea el audio
        // Esto es normal y esperado en la primera carga
      }
    }
  }

  /// Detener música de fondo
  Future<void> stopLoginMusic() async {
    await _musicPlayer.stop();
    _isMusicPlaying = false;
  }

  /// Reproducir efecto de glitch (sincronizado con efecto visual)
  Future<void> playGlitchEffect() async {
    try {
      await _glitchPlayer.setVolume(_glitchVolume);
      await _glitchPlayer.play(AssetSource('audio/sfx/glitch_01.mp3'));
    } catch (e) {
      // Silenciar error si el navegador bloquea el audio
    }
  }

  /// Reproducir efecto de hover en botones
  Future<void> playButtonHover() async {
    try {
      await _sfxPlayer.setVolume(_sfxVolume * 0.6); // Más bajo para hover
      await _sfxPlayer.play(AssetSource('audio/sfx/button_hover.mp3'));
    } catch (e) {
      // Silenciar error
    }
  }

  /// Reproducir efecto de click en botones
  Future<void> playButtonClick() async {
    try {
      await _sfxPlayer.setVolume(_sfxVolume);
      await _sfxPlayer.play(AssetSource('audio/sfx/button_click.mp3'));
    } catch (e) {
      // Silenciar error
    }
  }

  /// Ajustar volumen de música
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    _musicPlayer.setVolume(_musicVolume);
  }

  /// Ajustar volumen de efectos
  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  /// Pausar música
  Future<void> pauseMusic() async {
    await _musicPlayer.pause();
  }

  /// Reanudar música
  Future<void> resumeMusic() async {
    await _musicPlayer.resume();
  }

  /// Limpiar recursos
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _musicPlayer.dispose();
    await _sfxPlayer.dispose();
    await _glitchPlayer.dispose();
  }

  /// Manejar cambios en el ciclo de vida de la app (pausar/reanudar audio)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App en segundo plano o inactiva - pausar música
        pauseMusic();
        break;
      case AppLifecycleState.resumed:
        // App vuelve al frente - reanudar música
        resumeMusic();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App cerrada o oculta
        break;
    }
  }
}
