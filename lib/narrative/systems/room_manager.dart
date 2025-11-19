import 'package:flutter/material.dart';
import '../models/room_data.dart';
import '../models/interactable_data.dart';
import '../models/dialogue_data.dart';

/// Gestor de habitaciones para el Capítulo 1
class RoomManager {
  final Map<String, RoomData> _rooms = {};
  String _currentRoomId = 'living_room';

  RoomManager() {
    _initializeRooms();
  }

  /// Habitación actual
  RoomData get currentRoom => _rooms[_currentRoomId]!;

  /// Cambiar a otra habitación
  void changeRoom(String roomId) {
    if (_rooms.containsKey(roomId)) {
      _currentRoomId = roomId;
    }
  }

  /// Inicializar todas las habitaciones de la casa de Dan
  void _initializeRooms() {
    // SALA DE ESTAR (habitación inicial)
    _rooms['living_room'] = RoomData(
      id: 'living_room',
      name: 'Sala de Estar',
      type: RoomType.livingRoom,
      backgroundColor: const Color(0xFF2C1810),
      playerSpawnPosition: const Vector2(350, 250),
      roomSize: const Size(700, 500),
      interactables: [
        // Foto de la esposa
        InteractableData(
          id: 'photo_wife',
          name: 'Foto de familia',
          position: const Vector2(150, 200),
          size: const Vector2(60, 60),
          type: InteractableType.photo,
          dialogue: DialogueSequence(
            id: 'photo_wife_dialogue',
            dialogues: [
              const DialogueData(
                speakerName: 'Dan',
                text: 'Sarah...',
                type: DialogueType.internal,
              ),
              const DialogueData(
                speakerName: 'Dan',
                text: 'Tres años. Tres años desde que el cáncer te arrebató de mí. Y aún duele como si fuera ayer.',
                type: DialogueType.internal,
              ),
              const DialogueData(
                speakerName: 'Dan',
                text: 'Eras mi ancla, mi brújula moral en un mundo de grises. Sabías exactamente qué decir, cómo calmar mis demonios.',
                type: DialogueType.internal,
              ),
              const DialogueData(
                speakerName: 'Dan',
                text: 'Si estuvieras aquí ahora, sabrías qué hacer. Sabrías cómo proteger a Emma sin asfixiarla.',
                type: DialogueType.internal,
              ),
              const DialogueData(
                speakerName: 'Dan',
                text: 'Pero no estás. Y yo... yo solo soy un cascarón vacío tratando de recordar cómo ser humano.',
                type: DialogueType.internal,
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_hallway',
          position: Vector2(650, 200),
          size: Vector2(50, 100),
          targetRoomId: 'hallway',
          label: 'Pasillo',
        ),
      ],
    );

    // PASILLO (conecta las habitaciones)
    _rooms['hallway'] = RoomData(
      id: 'hallway',
      name: 'Pasillo',
      type: RoomType.hallway,
      backgroundColor: const Color(0xFF1A1410),
      playerSpawnPosition: const Vector2(100, 250),
      roomSize: const Size(700, 500),
      interactables: [],
      doors: [
        const DoorData(
          id: 'door_to_living',
          position: Vector2(50, 200),
          size: Vector2(50, 100),
          targetRoomId: 'living_room',
          label: 'Sala',
        ),
        const DoorData(
          id: 'door_to_emma',
          position: Vector2(350, 50),
          size: Vector2(100, 50),
          targetRoomId: 'emma_room',
          label: 'Habitación Emma',
        ),
        const DoorData(
          id: 'door_to_study',
          position: Vector2(350, 450),
          size: Vector2(100, 50),
          targetRoomId: 'study',
          label: 'Estudio',
        ),
      ],
    );

    // HABITACIÓN DE EMMA
    _rooms['emma_room'] = RoomData(
      id: 'emma_room',
      name: 'Habitación de Emma',
      type: RoomType.emmaRoom,
      backgroundColor: const Color(0xFF2C2C3E),
      playerSpawnPosition: const Vector2(350, 450),
      roomSize: const Size(700, 500),
      interactables: [
        InteractableData(
          id: 'emma_desk',
          name: 'Escritorio de Emma',
          position: const Vector2(200, 200),
          size: const Vector2(80, 60),
          type: InteractableType.desk,
          dialogue: DialogueSequence(
            id: 'emma_desk_dialogue',
            dialogues: [
              const DialogueData(
                speakerName: 'Dan',
                text: 'Su escritorio. Tan ordenado, tan meticuloso.',
                type: DialogueType.internal,
              ),
              const DialogueData(
                speakerName: 'Dan',
                text: 'Libros de biología molecular, notas en japonés que apenas puedo leer.',
                type: DialogueType.internal,
              ),
              const DialogueData(
                speakerName: 'Dan',
                text: 'Es brillante. Mucho más de lo que yo jamás fui.',
                type: DialogueType.internal,
              ),
              const DialogueData(
                speakerName: 'Dan',
                text: 'Kioto la está esperando. Un futuro que yo nunca podría darle aquí.',
                type: DialogueType.internal,
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_hallway_from_emma',
          position: Vector2(350, 450),
          size: Vector2(100, 50),
          targetRoomId: 'hallway',
          label: 'Pasillo',
        ),
      ],
    );

    // ESTUDIO (donde está el teléfono)
    _rooms['study'] = RoomData(
      id: 'study',
      name: 'Estudio',
      type: RoomType.study,
      backgroundColor: const Color(0xFF1C1C28),
      playerSpawnPosition: const Vector2(350, 100),
      roomSize: const Size(700, 500),
      interactables: [
        InteractableData(
          id: 'phone',
          name: 'Teléfono',
          position: const Vector2(400, 300),
          size: const Vector2(60, 60),
          type: InteractableType.phone,
          dialogue: DialogueSequence(
            id: 'phone_dialogue',
            dialogues: [
              const DialogueData(
                speakerName: 'Sistema',
                text: '*Ring Ring*',
                type: DialogueType.system,
              ),
              const DialogueData(
                speakerName: 'Dan',
                text: '¿Hola?',
                avatarPath: 'assets/avatars/dialogue_icons/dan_dialogue.png',
              ),
              const DialogueData(
                speakerName: 'Marcus',
                text: 'Dan. Soy Marcus.',
                avatarPath: 'assets/avatars/dialogue_icons/marcus_dialogue.png',
              ),
              const DialogueData(
                speakerName: 'Dan',
                text: 'Marcus. Hace tiempo.',
                avatarPath: 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
              ),
              const DialogueData(
                speakerName: 'Marcus',
                text: 'Necesito que escuches con atención. Tu hija, Emma.',
                avatarPath: 'assets/avatars/dialogue_icons/Marcus_Dialogue.png',
              ),
              const DialogueData(
                speakerName: 'Dan',
                text: '¿Qué pasa con Emma?',
                avatarPath: 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
              ),
              const DialogueData(
                speakerName: 'Marcus',
                text: 'Está en Kioto. En la universidad. Hay una situación.',
                avatarPath: 'assets/avatars/dialogue_icons/Marcus_Dialogue.png',
              ),
              const DialogueData(
                speakerName: 'Marcus',
                text: 'Sector 4. Amenazas activas.',
                avatarPath: 'assets/avatars/dialogue_icons/Marcus_Dialogue.png',
              ),
              const DialogueData(
                speakerName: 'Dan',
                text: 'Voy para allá.',
                avatarPath: 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_hallway_from_study',
          position: Vector2(350, 50),
          size: Vector2(100, 50),
          targetRoomId: 'hallway',
          label: 'Pasillo',
        ),
      ],
    );
  }
}
