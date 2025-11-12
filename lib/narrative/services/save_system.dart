import 'package:shared_preferences/shared_preferences.dart';

/// Sistema de guardado para rastrear progreso de capítulos
class SaveSystem {
  static const String _keyChapterProgress = 'chapter_progress';
  static const String _keyChapterSkipped = 'chapter_skipped';
  
  /// Obtener instancia de SharedPreferences
  static Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }
  
  /// Marcar un capítulo como completado
  static Future<void> markChapterCompleted(int chapterNumber) async {
    final prefs = await _getPrefs();
    final completed = await getCompletedChapters();
    if (!completed.contains(chapterNumber)) {
      completed.add(chapterNumber);
      await prefs.setStringList(
        _keyChapterProgress,
        completed.map((e) => e.toString()).toList(),
      );
    }
  }
  
  /// Marcar un capítulo como skipeado
  static Future<void> markChapterSkipped(int chapterNumber) async {
    final prefs = await _getPrefs();
    final skipped = await getSkippedChapters();
    if (!skipped.contains(chapterNumber)) {
      skipped.add(chapterNumber);
      await prefs.setStringList(
        _keyChapterSkipped,
        skipped.map((e) => e.toString()).toList(),
      );
    }
    // También marcar como completado para desbloquear el siguiente
    await markChapterCompleted(chapterNumber);
  }
  
  /// Obtener lista de capítulos completados
  static Future<List<int>> getCompletedChapters() async {
    final prefs = await _getPrefs();
    final stringList = prefs.getStringList(_keyChapterProgress) ?? [];
    return stringList.map((e) => int.parse(e)).toList();
  }
  
  /// Obtener lista de capítulos skipeados
  static Future<List<int>> getSkippedChapters() async {
    final prefs = await _getPrefs();
    final stringList = prefs.getStringList(_keyChapterSkipped) ?? [];
    return stringList.map((e) => int.parse(e)).toList();
  }
  
  /// Verificar si un capítulo está completado
  static Future<bool> isChapterCompleted(int chapterNumber) async {
    final completed = await getCompletedChapters();
    return completed.contains(chapterNumber);
  }
  
  /// Verificar si un capítulo fue skipeado
  static Future<bool> isChapterSkipped(int chapterNumber) async {
    final skipped = await getSkippedChapters();
    return skipped.contains(chapterNumber);
  }
  
  /// Verificar si un capítulo está desbloqueado
  static Future<bool> isChapterUnlocked(int chapterNumber) async {
    if (chapterNumber == 1) return true; // Capítulo 1 siempre desbloqueado
    final completed = await getCompletedChapters();
    return completed.contains(chapterNumber - 1); // Desbloqueado si el anterior está completo
  }
  
  /// Obtener el último capítulo completado
  static Future<int> getLastCompletedChapter() async {
    final completed = await getCompletedChapters();
    if (completed.isEmpty) return 0;
    completed.sort();
    return completed.last;
  }
  
  /// Resetear todo el progreso (para debug)
  static Future<void> resetProgress() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyChapterProgress);
    await prefs.remove(_keyChapterSkipped);
  }
}
