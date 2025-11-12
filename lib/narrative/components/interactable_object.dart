import 'package:flutter/material.dart';
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
    return Positioned(
      left: data.position.x,
      top: data.position.y,
      child: GestureDetector(
        onTap: isInRange ? () => _handleInteraction(context) : null,
        child: Container(
          width: data.size.x,
          height: data.size.y,
          decoration: BoxDecoration(
            color: _getColorForType(),
            border: Border.all(
              color: isInRange ? Colors.yellow : Colors.white.withOpacity(0.3),
              width: isInRange ? 3 : 1,
            ),
          ),
          child: Stack(
            children: [
              // Icono del objeto
              Center(
                child: Icon(
                  _getIconForType(),
                  color: Colors.white,
                  size: 32,
                ),
              ),
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

  Color _getColorForType() {
    switch (data.type) {
      case InteractableType.phone:
        return Colors.green.withOpacity(0.5);
      case InteractableType.photo:
        return Colors.blue.withOpacity(0.5);
      case InteractableType.door:
        return Colors.brown.withOpacity(0.5);
      case InteractableType.furniture:
        return Colors.grey.withOpacity(0.5);
      case InteractableType.document:
        return Colors.orange.withOpacity(0.5);
      case InteractableType.npc:
        return Colors.purple.withOpacity(0.5);
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
      default:
        return Icons.help_outline;
    }
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
