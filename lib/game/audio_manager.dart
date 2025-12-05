import 'package:flutter/foundation.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:audioplayers/audioplayers.dart';

/// Gestor centralizado de audio para Expediente Kōrin
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();

  factory AudioManager() {
    return _instance;
  }

  AudioManager._internal();

  // Cache de volúmenes
  double musicVolume = 0.5;
  double sfxVolume = 0.8;
  
  String? _currentMusic;

  /// Inicializa el sistema de audio
  Future<void> init() async {
    FlameAudio.bgm.initialize();
    // Precargar audios comunes si es necesario
    await FlameAudio.audioCache.loadAll([
      'music/bosque.mp3',
      'music/pelea con el stalker.mp3',
      'music/dan peleando con cuchillo.mp3',
      'sfx/intro_glitch.mp3',
      'music/menu_rain_ambience.mp3',
      'music/house_ambience.mp3',
      'music/bunker_ambience.mp3',
      'music/stalker_theme.mp3',
      'sfx/stalker_alert.mp3',
    ]);
  }

  /// Reproduce la música de Login en bucle (Ambiente Lluvia)
  void playLoginMusic() {
    debugPrint('🎵 AudioManager: Requesting playLoginMusic');
    if (_currentMusic == 'music/menu_rain_ambience.mp3' && FlameAudio.bgm.isPlaying) {
      debugPrint('🎵 AudioManager: Already playing menu ambience');
      return;
    }
    
    stopMusic();
    _currentMusic = 'music/menu_rain_ambience.mp3';
    debugPrint('🎵 AudioManager: Starting menu ambience playback...');
    try {
      FlameAudio.bgm.play('music/menu_rain_ambience.mp3', volume: musicVolume);
      debugPrint('🎵 AudioManager: Playback command sent');
    } catch (e) {
      debugPrint('❌ AudioManager: Error playing menu ambience: $e');
    }
  }

  /// Reproduce la música de la Casa (Capítulo 1)
  void playHouseMusic() {
    if (_currentMusic == 'music/house_ambience.mp3' && FlameAudio.bgm.isPlaying) return;
    
    stopMusic();
    _currentMusic = 'music/house_ambience.mp3';
    FlameAudio.bgm.play('music/house_ambience.mp3', volume: musicVolume);
  }

  /// Reproduce la música del Búnker (Capítulo 2)
  void playBunkerMusic() {
    if (_currentMusic == 'music/bunker_ambience.mp3' && FlameAudio.bgm.isPlaying) return;
    
    stopMusic();
    _currentMusic = 'music/bunker_ambience.mp3';
    FlameAudio.bgm.play('music/bunker_ambience.mp3', volume: musicVolume);
  }

  /// Reproduce la música del Bosque en bucle (modo focus)
  void playForestMusic() {
    stopMusic();
    FlameAudio.bgm.play('music/bosque.mp3', volume: musicVolume);
  }

  /// Reproduce la secuencia de combate: Alert SFX + Boss Theme
  Future<void> playCombatMusicSequence() async {
    stopMusic();

    // 1. Reproducir efecto de alerta (Impacto)
    await FlameAudio.play('sfx/stalker_alert.mp3', volume: sfxVolume);

    // 2. Esperar un poco (opcional, para dramatismo) o iniciar música inmediatamente
    // Si el SFX es largo (6s), podemos esperar un poco o mezclarlo.
    // Vamos a esperar 2 segundos para que el impacto resuene antes de la música
    await Future.delayed(const Duration(seconds: 2));

    // 3. Reproducir música de fondo (loop)
    _currentMusic = 'music/stalker_theme.mp3';
    FlameAudio.bgm.play('music/stalker_theme.mp3', volume: musicVolume);
  }

  /// Reproduce SFX de ataque (superpuesto)
  void playAttackSfx() {
    FlameAudio.play('music/dan peleando con cuchillo.mp3', volume: sfxVolume);
  }

  AudioPlayer? _introPlayer;

  /// Reproduce el audio de la intro (Splash Screen)
  Future<void> playIntroAudio() async {
    _introPlayer = await FlameAudio.play('sfx/intro_glitch.mp3', volume: sfxVolume);
  }

  /// Detiene el audio de la intro
  void stopIntroAudio() {
    _introPlayer?.stop();
    _introPlayer = null;
  }

  /// Detiene cualquier música de fondo
  void stopMusic() {
    _currentMusic = null;
    if (FlameAudio.bgm.isPlaying) {
      FlameAudio.bgm.stop();
    }
  }

  /// Pausa la música
  void pauseMusic() {
    if (FlameAudio.bgm.isPlaying) {
      FlameAudio.bgm.pause();
    }
  }

  /// Reanuda la música
  void resumeMusic() {
    FlameAudio.bgm.resume();
  }
}
