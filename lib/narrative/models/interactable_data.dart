import 'package:flutter/material.dart';
import 'dart:math';
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
  final String? spritePath; // Ruta a la imagen del sprite (opcional)
  final Rect? sourceRect; // Área de la imagen a renderizar (para sprite sheets)
  
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
    this.spritePath,
    this.sourceRect,
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
  desk, // Escritorio
  npc, // Personaje (futuro)
  object, // Objeto general
  character, // Personaje interactuable (Mel)
  decoration, // Decoración visual (árboles, efectos)
}



/// Clase simple para vectores 2D (compatible con Flame)
class Vector2 {
  final double x;
  final double y;

  const Vector2(this.x, this.y);

  Vector2 operator -(Vector2 other) => Vector2(x - other.x, y - other.y);
  Vector2 operator +(Vector2 other) => Vector2(x + other.x, y + other.y);
  Vector2 operator *(double scalar) => Vector2(x * scalar, y * scalar);
  Vector2 operator /(double scalar) => Vector2(x / scalar, y / scalar);
  
  double get length => sqrt(x * x + y * y);
  double get length2 => x * x + y * y;
  
  Vector2 normalized() {
    final len = length;
    if (len == 0) return const Vector2(0, 0);
    return Vector2(x / len, y / len);
  }
  
  double get dx => x;
  double get dy => y;

  double distanceTo(Vector2 other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }

  @override
  String toString() => 'Vector2($x, $y)';
}
