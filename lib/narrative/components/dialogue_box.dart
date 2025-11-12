import 'package:flutter/material.dart';
import '../models/dialogue_data.dart';

/// Widget de caja de diálogo estilo RPG clásico
class DialogueBox extends StatefulWidget {
  final DialogueData dialogue;
  final VoidCallback onComplete;
  final double typewriterSpeed; // Caracteres por segundo

  const DialogueBox({
    Key? key,
    required this.dialogue,
    required this.onComplete,
    this.typewriterSpeed = 20.0, // Reducido de 30 a 20 para mejor legibilidad
  }) : super(key: key);

  @override
  State<DialogueBox> createState() => _DialogueBoxState();
}

class _DialogueBoxState extends State<DialogueBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _displayedText = '';
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startTypewriter();
  }

  void _startTypewriter() {
    final totalDuration = widget.dialogue.text.length / widget.typewriterSpeed;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (totalDuration * 1000).toInt()),
    );

    _controller.addListener(() {
      setState(() {
        final charCount =
            (_controller.value * widget.dialogue.text.length).floor();
        _displayedText = widget.dialogue.text.substring(0, charCount);
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isComplete = true;
          _displayedText = widget.dialogue.text;
        });
      }
    });

    _controller.forward();
  }

  void _handleTap() {
    debugPrint('DialogueBox: Tap detected - isComplete: $_isComplete');
    
    if (!_isComplete) {
      // Si no terminó, completar inmediatamente
      debugPrint('DialogueBox: Completing text immediately');
      _controller.stop();
      setState(() {
        _isComplete = true;
        _displayedText = widget.dialogue.text;
      });
    } else {
      // Si ya terminó, avanzar al siguiente diálogo
      debugPrint('DialogueBox: Advancing to next dialogue');
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.dialogue.canSkip ? _handleTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar (si existe)
            if (widget.dialogue.avatarPath != null) ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: widget.dialogue.avatarPath!.isNotEmpty
                    ? Image.asset(
                        widget.dialogue.avatarPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Placeholder si no existe la imagen
                          return const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 48,
                          );
                        },
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 48,
                      ),
              ),
              const SizedBox(width: 16),
            ],
            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nombre del hablante
                  if (widget.dialogue.type != DialogueType.internal)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        widget.dialogue.speakerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  // Texto del diálogo
                  Text(
                    _displayedText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'monospace',
                      fontStyle: widget.dialogue.type == DialogueType.internal
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                  // Indicador de "presiona para continuar"
                  if (_isComplete && widget.dialogue.canSkip)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Click para continuar',
                            style: TextStyle(
                              color: Colors.yellow.withOpacity(0.8),
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '▼',
                            style: TextStyle(
                              color: Colors.yellow.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
