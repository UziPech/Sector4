import 'package:flutter/material.dart';
import 'dialogue_data.dart';

/// Modelo para objetos con los que el jugador puede interactuar
class InteractableData {
  final String id;
  final String name;
  final Vector2 position;
  final Vector2 size;
  final InteractableType type;
  final DialogueSequence? dialogue;
  final VoidCallback? onInteract;
  final bool isOneTime; // Si solo se puede interactuar una vez
  final String? requiredItem; // Item requerido para interactuar (futuro)
  
  bool hasBeenInteracted = false;

  InteractableData({
    required this.id,
    required this.name,
    required this.position,
    required this.size,
    required this.type,
    this.dialogue,
    this.onInteract,
    this.isOneTime = false,
    this.requiredItem,
  });

  /// Verifica si el jugador está en rango de interacción
  bool isInRange(Vector2 playerPosition, double interactionRadius) {
    final distance = (position - playerPosition).length;
    return distance <= interactionRadius;
  }
}

/// Tipos de objetos interactuables
enum InteractableType {
  generic, // Objeto genérico
  phone, // Teléfono (trigger especial)
  photo, // Foto (memoria)
  door, // Puerta (transición)
  furniture, // Mueble (ambiente)
  document, // Documento (lore)
  npc, // Personaje (futuro)
}

/// Clase simple para vectores 2D (compatible con Flame)
class Vector2 {
  final double x;
  final double y;

  const Vector2(this.x, this.y);

  Vector2 operator -(Vector2 other) => Vector2(x - other.x, y - other.y);
  
  double get length => (x * x + y * y);
  
  @override
  String toString() => 'Vector2($x, $y)';
}
