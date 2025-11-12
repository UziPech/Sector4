import 'package:flutter/material.dart';
import '../models/dialogue_data.dart';
import 'dialogue_box.dart';

/// Sistema gestor de secuencias de diálogo
class DialogueSystem extends StatefulWidget {
  final DialogueSequence sequence;
  final VoidCallback? onSequenceComplete;

  const DialogueSystem({
    Key? key,
    required this.sequence,
    this.onSequenceComplete,
  }) : super(key: key);

  @override
  State<DialogueSystem> createState() => _DialogueSystemState();
}

class _DialogueSystemState extends State<DialogueSystem> {
  int _currentDialogueIndex = 0;

  void _advanceDialogue() {
    debugPrint('DialogueSystem: Advancing from index $_currentDialogueIndex to ${_currentDialogueIndex + 1}');
    
    setState(() {
      _currentDialogueIndex++;
    });

    // Si terminamos la secuencia
    if (_currentDialogueIndex >= widget.sequence.dialogues.length) {
      debugPrint('DialogueSystem: Sequence complete, calling callbacks');
      widget.sequence.onComplete?.call();
      widget.onSequenceComplete?.call();
    } else {
      debugPrint('DialogueSystem: Now showing dialogue $_currentDialogueIndex');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si ya terminamos todos los diálogos, no mostrar nada
    if (_currentDialogueIndex >= widget.sequence.dialogues.length) {
      return const SizedBox.shrink();
    }

    final currentDialogue = widget.sequence.dialogues[_currentDialogueIndex];

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: DialogueBox(
            key: ValueKey('dialogue_$_currentDialogueIndex'), // Key única para forzar reconstrucción
            dialogue: currentDialogue,
            onComplete: _advanceDialogue,
          ),
        ),
      ),
    );
  }
}

/// Overlay para mostrar diálogos sobre cualquier pantalla
class DialogueOverlay {
  static OverlayEntry? _currentOverlay;

  /// Muestra una secuencia de diálogo
  static void show(
    BuildContext context,
    DialogueSequence sequence, {
    VoidCallback? onComplete,
  }) {
    // Remover overlay anterior si existe
    dismiss();

    _currentOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            DialogueSystem(
              sequence: sequence,
              onSequenceComplete: () {
                dismiss();
                onComplete?.call();
              },
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  /// Cierra el diálogo actual
  static void dismiss() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  /// Verifica si hay un diálogo activo
  static bool get isActive => _currentOverlay != null;
}
