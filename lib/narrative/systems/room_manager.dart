import 'package:flutter/material.dart';
import '../models/room_data.dart';
import '../models/interactable_data.dart';
import '../models/dialogue_data.dart';
import '../components/room_shape_clipper.dart';

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
    // SALA DE ESTAR (forma de U con 2 puertas norte)
    _rooms['living_room'] = RoomData(
      id: 'living_room',
      name: 'Sala de Estar',
      type: RoomType.livingRoom,
      backgroundColor: const Color(0xFF2C1810),
      playerSpawnPosition: const Vector2(350, 350),
      roomSize: const Size(700, 600),
      shape: RoomShape.uShape, // Forma de U
      interactables: [
        // Reloj de Abuelo (Grandfather Clock) - Esquina inferior derecha
        InteractableData(
          id: 'grandfather_clock',
          name: 'Reloj de Abuelo',
          type: InteractableType.furniture,
          position: const Vector2(630, 480),
          size: const Vector2(50, 100),
          spritePath: 'assets/images/grandfather_clock.png',
        ),

        // Sofá - Zona norte de la sala (al lado de puerta central)
        InteractableData(
          id: 'sofa',
          name: 'Sofá',
          type: InteractableType.furniture,
          position: const Vector2(100, 130),
          size: const Vector2(200, 100),
          spritePath: 'assets/images/sofa.png',
        ),

        // Puerta de Sarah - Zona central norte (sin sprite propio, activa monólogo interno)
        InteractableData(
          id: 'wife_door',
          name: 'Habitación de Sarah',
          type: InteractableType.furniture,
          position: const Vector2(304, 120),
          size: const Vector2(90, 40),
          isOneTime: false,
          dialogue: DialogueSequence(
            id: 'wife_door_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Dan',
                text: '...',
                type: DialogueType.internal,
              ),
              DialogueData(
                speakerName: 'Dan',
                text: 'El pomo sigue frío. Como si nadie lo hubiera tocado en años.',
                type: DialogueType.internal,
              ),
              DialogueData(
                speakerName: 'Dan',
                text: 'Sarah... siempre dejabas la luz encendida. Decías que el silencio traía a los fantasmas.',
                type: DialogueType.internal,
              ),
              DialogueData(
                speakerName: 'Dan',
                text: 'Te equivocabas. Los fantasmas ya estaban aquí.',
                type: DialogueType.internal,
              ),
              DialogueData(
                speakerName: 'Dan',
                text: 'Aún no puedo entrar. Si lo hago, tendré que aceptar que ya no estás.',
                type: DialogueType.internal,
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_study',
          position: Vector2(
            45,
            0,
          ), // Torre izquierda - ajustado al punto medio (45)
          size: Vector2(46, 18),
          targetRoomId: 'study',
          label: 'Estudio',
          targetSpawnPosition: Vector2(
            300,
            250,
          ), // Dentro del nuevo estudio (altura 320)
        ),
        // Puerta decorativa del centro - no funcional, solo visual
        const DoorData(
          id: 'door_center',
          position: Vector2(327, 102),
          size: Vector2(46, 18),
          targetRoomId: '', // Sin destino - solo decorativa
          label: '',
        ),
        const DoorData(
          id: 'door_to_emma',
          position: Vector2(605, 0), // Torre derecha
          size: Vector2(46, 18),
          targetRoomId: 'emma_room',
          label: 'Habitación Emma',
          targetSpawnPosition: Vector2(
            300,
            750,
          ), // Spawn cerca de la puerta sur
        ),
      ],
    );

    // HABITACIÓN DE EMMA
    _rooms['emma_room'] = RoomData(
      id: 'emma_room',
      name: 'Habitación de Emma',
      type: RoomType.emmaRoom,
      backgroundColor: const Color(0xFF2C2C3E),
      playerSpawnPosition: const Vector2(300, 400),
      roomSize: const Size(600, 800),
      shape: RoomShape.cutCorners,
      interactables: [
        InteractableData(
          id: 'emma_desk',
          name: 'Escritorio de Emma',
          type: InteractableType.furniture,
          position: const Vector2(200, 200),
          size: const Vector2(92, 70),
          // spritePath: 'assets/sprites/objects/desk.png',
          dialogue: DialogueSequence(
            id: 'emma_desk_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Dan',
                text: 'Incluso en el caos, Emma siempre mantenía el orden. Notas codificadas, libros apilados.',
                type: DialogueType.internal,
              ),
              DialogueData(
                speakerName: 'Dan',
                text: 'El único ancla a la cordura que me queda en este mundo.',
                type: DialogueType.internal,
              ),
            ],
          ),
        ),

        InteractableData(
          id: 'emma_bed',
          name: 'Cama de Emma',
          type: InteractableType.furniture,
          position: const Vector2(400, 200),
          size: const Vector2(100, 120),
          // spritePath: 'assets/sprites/objects/bed.png',
        ),

        InteractableData(
          id: 'furniture_1',
          name: 'Mueble 1',
          type: InteractableType.furniture,
          position: const Vector2(145, 10),
          size: const Vector2(144, 144),
          // spritePath: 'assets/sprites/objects/furniture_1.png',
        ),
        InteractableData(
          id: 'furniture_2',
          name: 'Mueble 2',
          type: InteractableType.furniture,
          position: const Vector2(285, 10),
          size: const Vector2(44, 144),
          // spritePath: 'assets/sprites/objects/furniture_2.png',
        ),
        InteractableData(
          id: 'furniture_3',
          name: 'Mueble 3',
          type: InteractableType.furniture,
          position: const Vector2(530, 10),
          size: const Vector2(60, 80),
          // spritePath: 'assets/sprites/objects/furniture_3.png',
        ),

        // Sofá - Zona norte de la habitación
        InteractableData(
          id: 'emma_sofa',
          name: 'Sofá',
          type: InteractableType.furniture,
          position: const Vector2(330, 15),
          size: const Vector2(200, 100),
          spritePath: 'assets/images/sofa.png',
        ),

        // Fotos - Pared de la extensión izquierda
        InteractableData(
          id: 'emma_photos',
          name: 'Fotos',
          type: InteractableType.photo,
          position: const Vector2(50, 320),
          size: const Vector2(80, 60),
          // spritePath: 'assets/sprites/objects/photos.png',
          dialogue: DialogueSequence(
            id: 'emma_photos_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Dan',
                text: 'Es extraño ver esta foto. Éramos una familia.',
                type: DialogueType.internal,
              ),
              DialogueData(
                speakerName: 'Dan',
                text: 'Ahora la casa está demasiado silenciosa.',
                type: DialogueType.internal,
              ),
              DialogueData(
                speakerName: 'Dan',
                text: '...Y el teléfono de su apartamento en Kioto ha dejado de sonar.',
                type: DialogueType.internal,
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_living',
          position: Vector2(277, 782), // Pared Sur (800 - 18)
          size: Vector2(46, 18),
          targetRoomId: 'living_room',
          label: 'Sala de Estar',
          targetSpawnPosition: Vector2(617, 150),
        ),
      ],
    );

    // ESTUDIO
    _rooms['study'] = RoomData(
      id: 'study',
      name: 'Estudio',
      type: RoomType.study,
      backgroundColor: const Color(0xFF1C1C28),
      playerSpawnPosition: const Vector2(
        325,
        200,
      ), // Ajustado para nueva altura
      roomSize: const Size(
        650,
        320,
      ), // Reducido a rectángulo (sin la extensión L)
      shape: RoomShape.rectangle, // Cambiado a rectángulo
      interactables: [
        InteractableData(
          id: 'phone',
          name: 'Teléfono',
          type: InteractableType.phone,
          position: const Vector2(350, 200),
          size: const Vector2(60, 60),
          dialogue: DialogueSequence(
            id: 'phone_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'System',
                text: '*El teléfono suena. Un tono insistente.*',
                type: DialogueType.system,
              ),
              DialogueData(
                speakerName: 'Dan',
                text: '... ¿Sí?',
                avatarPath: 'assets/avatars/dialogue_icons/dan_dialogue.png',
              ),
              DialogueData(
                speakerName: 'Marcus',
                text: 'Dan. Ha pasado un tiempo. Sé que no es el mejor momento y que el silencio pesa más que nunca...',
                avatarPath: 'assets/avatars/dialogue_icons/marcus_dialogue.png',
              ),
              DialogueData(
                speakerName: 'Dan',
                text: '¿Marcus? ¿Qué quieres? Te dije que estaba fuera.',
                avatarPath: 'assets/avatars/dialogue_icons/dan_dialogue.png',
              ),
              DialogueData(
                speakerName: 'Marcus',
                text: 'Emma ya no responde, Dan. Y no es solo ella.',
                avatarPath: 'assets/avatars/dialogue_icons/marcus_dialogue.png',
              ),
              DialogueData(
                speakerName: 'Dan',
                text: '...',
                avatarPath: 'assets/avatars/dialogue_icons/dan_dialogue.png',
              ),
              DialogueData(
                speakerName: 'Marcus',
                text: 'La universidad de Kioto es una tumba abierta. Las entidades... no son lo que solíamos ver. Nacen de los ecos de la violencia. La desesperación está tomando forma física.',
                avatarPath: 'assets/avatars/dialogue_icons/marcus_dialogue.png',
              ),
              DialogueData(
                speakerName: 'Marcus',
                text: 'Llevamos días perdiendo terreno. Necesitamos a alguien que no tenga nada más que perder, alguien del Asalto de Élite.',
                avatarPath: 'assets/avatars/dialogue_icons/marcus_dialogue.png',
              ),
              DialogueData(
                speakerName: 'Marcus',
                text: 'Entra ahí, quema lo que tengas que quemar, pero sácala.',
                avatarPath: 'assets/avatars/dialogue_icons/marcus_dialogue.png',
              ),
            ],
          ),
        ),

        // Sofá - Zona norte del estudio
        InteractableData(
          id: 'study_sofa',
          name: 'Sofá',
          type: InteractableType.furniture,
          position: const Vector2(250, 30),
          size: const Vector2(200, 100),
          spritePath: 'assets/images/sofa.png',
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_living',
          position: Vector2(277, 302),
          size: Vector2(46, 18),
          targetRoomId: 'living_room',
          label: 'Sala de Estar',
          targetSpawnPosition: Vector2(60, 150),
        ),
      ],
    );
  }
}
