import 'package:flutter/material.dart';
import '../services/save_system.dart';
import '../screens/menu_screen.dart';

/// Botón de skip para escenas narrativas
class SkipButton extends StatefulWidget {
  final int chapterNumber;
  final VoidCallback? onSkip;

  const SkipButton({super.key, required this.chapterNumber, this.onSkip});

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
                  ? Colors.orange.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.5),
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
    // print('💀Ëœ Skip button pressed - Chapter ${widget.chapterNumber}');

    // Asegurarse de que el contexto sea válido
    if (!context.mounted) {
      // print('âÂÅ’ Context not mounted');
      return;
    }

    try {
      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Skipear Capítulo',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '¿Estás seguro de que quieres skipear este capítulo?\n\nPodrás volver a jugarlo desde el menú de Historia.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // print('âÂÅ’ Skip cancelled');
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                // print('âœ… Skip confirmed');
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Skipear',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      // print('Dialog result: $confirm');

      if (confirm == true) {
        if (!context.mounted) {
          // print('âÂÅ’ Context not mounted after dialog');
          return;
        }

        // print('ðŸ’¾ Marking chapter ${widget.chapterNumber} as skipped');

        // Marcar como skipeado
        await SaveSystem.markChapterSkipped(widget.chapterNumber);

        // print('âœ… Chapter marked as skipped');

        // Callback personalizado si existe
        widget.onSkip?.call();

        // Volver al menú
        if (context.mounted) {
          // print('ðÅ¸ÂÂ  Navigating to menu');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MenuScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      // print('âÂÅ’ Error in skip dialog: $e');

      // Mostrar error al usuario
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al skipear: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
