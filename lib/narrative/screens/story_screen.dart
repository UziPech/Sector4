import 'package:flutter/material.dart';
import '../services/save_system.dart';
import '../models/chapter_info.dart';
import 'house_scene.dart';
import 'bunker_scene.dart';

/// Pantalla de historia con tarjetas de capítulos
class StoryScreen extends StatefulWidget {
  const StoryScreen({Key? key}) : super(key: key);

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  List<int> _completedChapters = [];
  List<int> _skippedChapters = [];
  bool _isLoading = true;

  // Definición de capítulos disponibles
  final List<ChapterInfo> _chapters = const [
    ChapterInfo(
      number: 1,
      title: 'Capítulo 1: El Despertar',
      description: 'Dan despierta en su casa, sin recordar nada de la noche anterior...',
      sceneBuilder: HouseScene.new,
    ),
    ChapterInfo(
      number: 2,
      title: 'Capítulo 2: El Búnker',
      description: 'Dan descubre un búnker secreto bajo su casa...',
      sceneBuilder: BunkerScene.new,
    ),
    // Agregar más capítulos aquí en el futuro
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final completed = await SaveSystem.getCompletedChapters();
    final skipped = await SaveSystem.getSkippedChapters();
    setState(() {
      _completedChapters = completed;
      _skippedChapters = skipped;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'HISTORIA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              // Lista de capítulos
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = _chapters[index];
                          final isCompleted = _completedChapters.contains(chapter.number);
                          final isSkipped = _skippedChapters.contains(chapter.number);
                          final isUnlocked = chapter.number == 1 || 
                                           _completedChapters.contains(chapter.number - 1);
                          
                          return _ChapterCard(
                            chapter: chapter,
                            isCompleted: isCompleted,
                            isSkipped: isSkipped,
                            isUnlocked: isUnlocked,
                            onPlay: () => _playChapter(chapter),
                            onSkip: () => _skipChapter(chapter),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playChapter(ChapterInfo chapter) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => chapter.sceneBuilder(),
      ),
    );
  }

  Future<void> _skipChapter(ChapterInfo chapter) async {
    // Confirmar skip
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Skipear Capítulo',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de que quieres skipear ${chapter.title}?\n\nPodrás volver a jugarlo más tarde.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Skipear',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SaveSystem.markChapterSkipped(chapter.number);
      await _loadProgress();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${chapter.title} skipeado'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

/// Widget de tarjeta de capítulo
class _ChapterCard extends StatefulWidget {
  final ChapterInfo chapter;
  final bool isCompleted;
  final bool isSkipped;
  final bool isUnlocked;
  final VoidCallback onPlay;
  final VoidCallback onSkip;

  const _ChapterCard({
    required this.chapter,
    required this.isCompleted,
    required this.isSkipped,
    required this.isUnlocked,
    required this.onPlay,
    required this.onSkip,
  });

  @override
  State<_ChapterCard> createState() => _ChapterCardState();
}

class _ChapterCardState extends State<_ChapterCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered && widget.isUnlocked
                ? Colors.white.withOpacity(0.05)
                : Colors.transparent,
            border: Border.all(
              color: widget.isUnlocked
                  ? (_isHovered ? Colors.yellow : Colors.white)
                  : Colors.grey[700]!,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con título y estado
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.chapter.title,
                        style: TextStyle(
                          color: widget.isUnlocked ? Colors.white : Colors.grey[700],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    if (widget.isCompleted && !widget.isSkipped)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Text(
                          'COMPLETADO',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    if (widget.isSkipped)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Text(
                          'SKIPEADO',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    if (!widget.isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          border: Border.all(color: Colors.grey[700]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock,
                              size: 12,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'BLOQUEADO',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Descripción
                Text(
                  widget.chapter.description,
                  style: TextStyle(
                    color: widget.isUnlocked ? Colors.grey[400] : Colors.grey[700],
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
                if (widget.isUnlocked) ...[
                  const SizedBox(height: 16),
                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          text: widget.isCompleted ? 'REJUGAR' : 'JUGAR',
                          icon: Icons.play_arrow,
                          onPressed: widget.onPlay,
                          isPrimary: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!widget.isCompleted || widget.isSkipped)
                        Expanded(
                          child: _ActionButton(
                            text: 'SKIPEAR',
                            icon: Icons.skip_next,
                            onPressed: widget.onSkip,
                            isPrimary: false,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de acción para las tarjetas
class _ActionButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isPrimary ? Colors.yellow : Colors.orange;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: _isHovered ? color.withOpacity(0.1) : Colors.transparent,
            border: Border.all(
              color: _isHovered ? color : Colors.white,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: _isHovered ? color : Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                widget.text,
                style: TextStyle(
                  color: _isHovered ? color : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
