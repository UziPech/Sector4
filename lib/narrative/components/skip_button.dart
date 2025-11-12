import 'package:flutter/material.dart';
import '../services/save_system.dart';
import '../screens/menu_screen.dart';

/// Botón de skip para escenas narrativas
class SkipButton extends StatefulWidget {
  final int chapterNumber;
  final VoidCallback? onSkip;

  const SkipButton({
    Key? key,
    required this.chapterNumber,
    this.onSkip,
  }) : super(key: key);

  @override
  State<SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<SkipButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => _showSkipDialog(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isHovered
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.black.withOpacity(0.5),
              border: Border.all(
                color: _isHovered ? Colors.orange : Colors.white,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.skip_next,
                  color: _isHovered ? Colors.orange : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'SKIPEAR',
                  style: TextStyle(
                    color: _isHovered ? Colors.orange : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSkipDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Skipear Capítulo',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de que quieres skipear este capítulo?\n\nPodrás volver a jugarlo desde el menú de Historia.',
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

    if (confirm == true && context.mounted) {
      // Marcar como skipeado
      await SaveSystem.markChapterSkipped(widget.chapterNumber);
      
      // Callback personalizado si existe
      widget.onSkip?.call();
      
      // Volver al menú
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MenuScreen(),
          ),
          (route) => false,
        );
      }
    }
  }
}
