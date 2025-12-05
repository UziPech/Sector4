import 'package:flame_audio/flame_audio.dart';

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

  /// Inicializa el sistema de audio
  Future<void> init() async {
    // Precargar audios comunes si es necesario
    await FlameAudio.audioCache.loadAll([
      'music/login.mp3',
      'music/bosque.mp3',
      'music/inicios de pelea.mp3',
      'music/pelea con el stalker.mp3',
      'music/dan peleando con cuchillo.mp3',
    ]);
  }

  /// Reproduce la música de Login en bucle
  void playLoginMusic() {
    stopMusic();
    FlameAudio.bgm.play('music/login.mp3', volume: musicVolume);
  }

  /// Reproduce la música del Bosque en bucle (modo focus)
  void playForestMusic() {
    stopMusic();
    FlameAudio.bgm.play('music/bosque.mp3', volume: musicVolume);
  }

  /// Reproduce la secuencia de combate: Intro + Loop simultáneos
  void playCombatMusicSequence() {
    stopMusic();

    // Reproducir intro como efecto de sonido (una sola vez)
    FlameAudio.play('music/inicios de pelea.mp3', volume: musicVolume);

    // Reproducir música de fondo (loop) inmediatamente
    FlameAudio.bgm.play('music/pelea con el stalker.mp3', volume: musicVolume);
  }

  /// Reproduce SFX de ataque (superpuesto)
  void playAttackSfx() {
    FlameAudio.play('music/dan peleando con cuchillo.mp3', volume: sfxVolume);
  }

  /// Detiene cualquier música de fondo
  void stopMusic() {
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
