import 'package:flutter/material.dart';
import '../models/dialogue_data.dart';

/// Widget de caja de diálogo estilo RPG clásico
class DialogueBox extends StatefulWidget {
  final DialogueData dialogue;
  final VoidCallback onComplete;
  final double typewriterSpeed; // Caracteres por segundo
  final bool showHintText; // Si mostrar el texto de ayuda

  const DialogueBox({
    Key? key,
    required this.dialogue,
    required this.onComplete,
    this.typewriterSpeed = 20.0, // Reducido de 30 a 20 para mejor legibilidad
    this.showHintText = true, // Por defecto mostrar
  }) : super(key: key);

  @override
  State<DialogueBox> createState() => _DialogueBoxState();
}

class _DialogueBoxState extends State<DialogueBox>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String _displayedText = '';
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    
    // Animación de pulso para el indicador
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
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
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.dialogue.canSkip ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.dialogue.canSkip ? _handleTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.90),
            border: Border.all(
              color: _isComplete 
                  ? Colors.yellow.withOpacity(0.4)
                  : Colors.white.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar pequeño (si existe)
            if (widget.dialogue.avatarPath != null) ...[
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRect(
                  child: Image.asset(
                    widget.dialogue.avatarPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 40,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
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
                  // Indicador de "presiona para continuar" con animación (solo primeros diálogos)
                  if (_isComplete && widget.dialogue.canSkip && widget.showHintText)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: FadeTransition(
                        opacity: _pulseAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.touch_app,
                              color: Colors.yellow.withOpacity(0.9),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Toca para continuar',
                              style: TextStyle(
                                color: Colors.yellow.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
