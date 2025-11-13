import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  final AudioPlayer _hoverPlayer = AudioPlayer(); // Player dedicado para hover

  // Control de volumen
  double _musicVolume = 0.25; // 25% para música de fondo (un poco más alto)
  double _sfxVolume = 0.3; // 30% para efectos (más bajo para no interrumpir)
  double _glitchVolume = 0.25; // 25% para glitch

  bool _isMusicPlaying = false;

  /// Inicializar el servicio de audio
  Future<void> initialize() async {
    // Configurar modo de loop para música
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(_musicVolume);
    
    // Configurar el glitch para NO interrumpir la música en Android
    if (!kIsWeb) {
      await _glitchPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none, // NO tomar audio focus
          ),
        ),
      );
    }
    
    // Configurar release mode para efectos
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    await _glitchPlayer.setReleaseMode(ReleaseMode.stop);
    await _hoverPlayer.setReleaseMode(ReleaseMode.stop);
  }

  /// Reproducir música de fondo del login
  Future<void> playLoginMusic() async {
    try {
      await _musicPlayer.stop(); // Detener cualquier reproducción anterior
      await _musicPlayer.setVolume(_musicVolume);
      await _musicPlayer.play(AssetSource('audio/music/login_ambient.mp3'));
      _isMusicPlaying = true;
    } catch (e) {
      // Silenciar error
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
    // Solo reproducir en web, no en Android para evitar conflictos con música
    if (kIsWeb) {
      try {
        await _hoverPlayer.setVolume(_sfxVolume * 0.6); // Más bajo para hover
        await _hoverPlayer.play(AssetSource('audio/sfx/button_hover.mp3'));
      } catch (e) {
        // Silenciar error
      }
    }
  }

  /// Reproducir efecto de click en botones
  Future<void> playButtonClick() async {
    // Solo reproducir en web, no en Android para evitar conflictos con música
    if (kIsWeb) {
      try {
        await _sfxPlayer.setVolume(_sfxVolume);
        await _sfxPlayer.play(AssetSource('audio/sfx/button_click.mp3'));
      } catch (e) {
        // Silenciar error
      }
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
    await _hoverPlayer.dispose();
  }

  /// Manejar cambios en el ciclo de vida de la app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App completamente en segundo plano (usuario fue al home) - pausar música
        pauseMusic();
        break;
      case AppLifecycleState.resumed:
        // App vuelve al frente - reanudar música si estaba sonando
        if (_isMusicPlaying) {
          resumeMusic();
        }
        break;
      case AppLifecycleState.inactive:
        // App temporalmente inactiva (panel de control, notificaciones, etc.)
        // NO pausar la música, solo es temporal
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App cerrada
        break;
    }
  }
}
