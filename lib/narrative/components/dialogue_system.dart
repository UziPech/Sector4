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
  static int _totalDialoguesShown = 0; // Contador global de diálogos mostrados

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

  /// Saltar toda la secuencia de diálogo
  void skipDialogue() {
    debugPrint('DialogueSystem: Skipping dialogue sequence');
    setState(() {
      _currentDialogueIndex = widget.sequence.dialogues.length;
    });
    
    // Llamar callbacks inmediatamente
    widget.sequence.onComplete?.call();
    widget.onSequenceComplete?.call();
  }

  /// Convierte la ruta del avatar pequeño a la ruta de DialogueBody
  String _getDialogueBodyPath(String avatarPath) {
    // Extraer el nombre del personaje (Dan, Mel, Marcus)
    if (avatarPath.contains('Dan')) {
      return 'assets/avatars/dialogue_body/dan_dialogue_complete.png';
    } else if (avatarPath.contains('Mel')) {
      return 'assets/avatars/dialogue_body/mel_dialogue_complete.png';
    } else if (avatarPath.contains('Marcus')) {
      return 'assets/avatars/dialogue_body/marcus_dialogue_complete.png';
    }
    // Fallback a la imagen original si no se encuentra
    return avatarPath;
  }

  /// Obtiene el offset vertical específico para cada personaje
  double _getCharacterBottomOffset(String avatarPath) {
    if (avatarPath.contains('Dan')) {
      return 0;
    } else if (avatarPath.contains('Mel')) {
      return 0;
    } else if (avatarPath.contains('Marcus')) {
      return 0;
    }
    return 0;
  }

  /// Obtiene el ancho específico para cada personaje
  double _getCharacterWidth(String avatarPath) {
    if (avatarPath.contains('Dan')) {
      return 350; // Dan más pequeño
    } else if (avatarPath.contains('Mel')) {
      return 420; // Mel más grande
    } else if (avatarPath.contains('Marcus')) {
      return 380; // Marcus tamaño medio
    }
    return 400;
  }

  /// Obtiene la altura específica para cada personaje
  double _getCharacterHeight(String avatarPath) {
    if (avatarPath.contains('Dan')) {
      return 450; // Dan más pequeño
    } else if (avatarPath.contains('Mel')) {
      return 520; // Mel más grande
    } else if (avatarPath.contains('Marcus')) {
      return 480; // Marcus tamaño medio
    }
    return 500;
  }

  /// Obtiene el offset horizontal específico para cada personaje
  double _getCharacterRightOffset(String avatarPath) {
    if (avatarPath.contains('Dan')) {
      return 50; // Dan más lejos
    } else if (avatarPath.contains('Mel')) {
      return 20; // Mel más cerca
    } else if (avatarPath.contains('Marcus')) {
      return 30; // Marcus posición media
    }
    return 30;
  }

  @override
  Widget build(BuildContext context) {
    // Si ya terminamos todos los diálogos, no mostrar nada
    if (_currentDialogueIndex >= widget.sequence.dialogues.length) {
      return const SizedBox.shrink();
    }

    final currentDialogue = widget.sequence.dialogues[_currentDialogueIndex];
    _totalDialoguesShown++; // Incrementar contador

    return Stack(
      children: [
        // Overlay oscuro con vignette cuando hay diálogo
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),
        
        // Caja de diálogo en la parte inferior (primero para que esté detrás)
        Positioned(
          left: 0,
          right: currentDialogue.avatarPath != null ? 350 : 0, // Dejar espacio para el personaje
          bottom: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: DialogueBox(
                key: ValueKey('dialogue_$_currentDialogueIndex'),
                dialogue: currentDialogue,
                onComplete: _advanceDialogue,
                showHintText: _totalDialoguesShown <= 3, // Solo mostrar en los primeros 3 diálogos
              ),
            ),
          ),
        ),
        
        // Personaje grande a la derecha (después para que esté encima)
        if (currentDialogue.avatarPath != null)
          Positioned(
            right: _getCharacterRightOffset(currentDialogue.avatarPath!),
            bottom: _getCharacterBottomOffset(currentDialogue.avatarPath!),
            child: Image.asset(
              _getDialogueBodyPath(currentDialogue.avatarPath!),
              width: _getCharacterWidth(currentDialogue.avatarPath!),
              height: _getCharacterHeight(currentDialogue.avatarPath!),
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
          ),

        
        // Botón de saltar (Skip)
        Positioned(
          top: 16,
          right: 16,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: skipDialogue,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'SALTAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.fast_forward,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Overlay para mostrar diálogos sobre cualquier pantalla
class DialogueOverlay {
  static OverlayEntry? _currentOverlay;
  static GlobalKey<_DialogueSystemState>? _dialogueKey;

  /// Muestra una secuencia de diálogo
  static void show(
    BuildContext context,
    DialogueSequence sequence, {
    VoidCallback? onComplete,
  }) {
    // Remover overlay anterior si existe
    dismiss();

    // Crear nuevo key para este diálogo
    _dialogueKey = GlobalKey<_DialogueSystemState>();

    _currentOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            DialogueSystem(
              key: _dialogueKey,
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

  /// Saltar el diálogo actual
  static void skipCurrent() {
    debugPrint('DialogueOverlay.skipCurrent() called');
    if (_dialogueKey?.currentState != null) {
      debugPrint('Calling skipDialogue on state');
      _dialogueKey!.currentState!.skipDialogue();
    } else {
      debugPrint('WARNING: No dialogue state available to skip');
    }
  }

  /// Cierra el diálogo actual
  static void dismiss() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  /// Verifica si hay un diálogo activo
  static bool get isActive => _currentOverlay != null;
}
