import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../models/interactable_data.dart';
import '../models/dialogue_data.dart';
import 'dialogue_system.dart';

/// Widget para objetos interactuables en la escena
class InteractableObject extends StatelessWidget {
  final InteractableData data;
  final Vector2 playerPosition;
  final double interactionRadius;
  final VoidCallback? onInteractionComplete;

  const InteractableObject({
    Key? key,
    required this.data,
    required this.playerPosition,
    this.interactionRadius = 50.0,
    this.onInteractionComplete,
  }) : super(key: key);

  bool get isInRange => data.isInRange(playerPosition, interactionRadius);

  void _handleInteraction(BuildContext context) {
    // Verificar si ya fue interactuado (si es one-time)
    if (data.isOneTime && data.hasBeenInteracted) {
      return;
    }

    // Marcar como interactuado
    data.hasBeenInteracted = true;

    // Ejecutar callback personalizado si existe
    data.onInteract?.call();

    // Mostrar diálogo si existe
    if (data.dialogue != null) {
      DialogueOverlay.show(
        context,
        data.dialogue!,
        onComplete: onInteractionComplete,
      );
    } else {
      onInteractionComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Para muebles decorativos, no mostrar borde a menos que esté en rango
    final isFurniture = data.type == InteractableType.furniture || data.type == InteractableType.photo;
    final showBorder = !isFurniture || isInRange;
    
    return Positioned(
      left: data.position.x,
      top: data.position.y,
      child: GestureDetector(
        onTap: isInRange ? () => _handleInteraction(context) : null,
        child: Container(
          width: data.size.x,
          height: data.size.y,
          decoration: BoxDecoration(
            color: showBorder ? _getColorForType() : Colors.transparent,
            border: showBorder ? Border.all(
              color: isInRange ? Colors.yellow : Colors.white.withOpacity(0.3),
              width: isInRange ? 3 : 1,
            ) : null,
          ),
          child: Stack(
            children: [
              // Sprite o icono del objeto
              if (data.spritePath != null)
                Positioned.fill(
                  child: data.sourceRect != null
                      ? FutureBuilder<ui.Image>(
                          future: _loadImage(data.spritePath!),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return CustomPaint(
                                painter: _SpritePainter(
                                  image: snapshot.data!,
                                  sourceRect: data.sourceRect!,
                                ),
                              );
                            }
                            return _buildCharacterPlaceholder();
                          },
                        )
                      : Image.asset(
                          data.spritePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildCharacterPlaceholder();
                          },
                        ),
                )
              else
                _buildCharacterPlaceholder(),
              // Indicador de interacción
              if (isInRange && !DialogueOverlay.isActive)
                Positioned(
                  top: -30,
                  left: 0,
                  right: 0,
                  child: Container(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.yellow, width: 2),
                      ),
                      child: const Text(
                        'E',
                        style: TextStyle(
                          color: Colors.yellow,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterPlaceholder() {
    if (data.type == InteractableType.character) {
      // Placeholder especial para personajes (como Mel)
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.cyan.withOpacity(0.6),
              Colors.purple.withOpacity(0.6),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_pin_circle,
              color: Colors.white,
              size: 48,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              data.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // Placeholder genérico para otros tipos
    return Center(
      child: Icon(
        _getIconForType(),
        color: Colors.white,
        size: 48,
      ),
    );
  }

  Color _getColorForType() {
    switch (data.type) {
      case InteractableType.phone:
        return Colors.green.withOpacity(0.5);
      case InteractableType.photo:
        return Colors.transparent;
      case InteractableType.door:
        return Colors.brown.withOpacity(0.5);
      case InteractableType.furniture:
        return Colors.grey.withOpacity(0.5);
      case InteractableType.document:
        return Colors.orange.withOpacity(0.5);
      case InteractableType.npc:
        return Colors.purple.withOpacity(0.5);
      case InteractableType.character:
        return Colors.transparent; // El gradiente se maneja en el placeholder
      default:
        return Colors.white.withOpacity(0.3);
    }
  }

  IconData _getIconForType() {
    switch (data.type) {
      case InteractableType.phone:
        return Icons.phone;
      case InteractableType.photo:
        return Icons.photo;
      case InteractableType.door:
        return Icons.door_front_door;
      case InteractableType.furniture:
        return Icons.chair;
      case InteractableType.document:
        return Icons.description;
      case InteractableType.npc:
        return Icons.person;
      case InteractableType.character:
        return Icons.person_pin;
      default:
        return Icons.help_outline;
    }
  }
}

/// Helper function to load image from assets
Future<ui.Image> _loadImage(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final bytes = data.buffer.asUint8List();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// Custom painter to render a specific region of a sprite sheet
class _SpritePainter extends CustomPainter {
  final ui.Image image;
  final Rect sourceRect;

  _SpritePainter({
    required this.image,
    required this.sourceRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final destRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, sourceRect, destRect, Paint());
  }

  @override
  bool shouldRepaint(_SpritePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.sourceRect != sourceRect;
  }
}

/// Widget helper para mostrar indicador de interacción flotante
class InteractionPrompt extends StatelessWidget {
  final String text;

  const InteractionPrompt({
    Key? key,
    this.text = 'Presiona E para interactuar',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow, width: 2),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
