import 'package:flutter/material.dart';
import 'interactable_data.dart';

/// Tipos de habitación
enum RoomType {
  livingRoom,
  emmaRoom,
  study,
  hallway,
  exterior,
  armory,
  library,
  laboratory,
  command,
  bedroom,
  cafeteria,
}

/// Modo de cámara para la habitación
enum CameraMode {
  fixed,     // Cámara fija (habitaciones pequeñas)
  follow,    // Cámara sigue al jugador (mapas grandes)
}

/// Datos de una habitación
class RoomData {
  final String id;
  final String name;
  final RoomType type;
  final Color backgroundColor;
  final List<InteractableData> interactables;
  final List<DoorData> doors;
  final Vector2 playerSpawnPosition;
  final Size roomSize;
  final CameraMode cameraMode;

  const RoomData({
    required this.id,
    required this.name,
    required this.type,
    required this.backgroundColor,
    required this.interactables,
    required this.doors,
    required this.playerSpawnPosition,
    this.roomSize = const Size(700, 500),
    this.cameraMode = CameraMode.fixed, // Por defecto cámara fija
  });
}

/// Datos de una puerta (área de transición)
class DoorData {
  final String id;
  final Vector2 position;
  final Vector2 size;
  final String targetRoomId;
  final String label;

  const DoorData({
    required this.id,
    required this.position,
    required this.size,
    required this.targetRoomId,
    required this.label,
  });

  /// Verifica si el jugador está en el área de la puerta
  bool isPlayerInRange(Vector2 playerPosition, double playerSize) {
    final doorRect = Rect.fromLTWH(
      position.x,
      position.y,
      size.x,
      size.y,
    );
    final playerRect = Rect.fromCenter(
      center: Offset(playerPosition.x, playerPosition.y),
      width: playerSize,
      height: playerSize,
    );
    return doorRect.overlaps(playerRect);
  }
}
