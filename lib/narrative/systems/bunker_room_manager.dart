import 'package:flutter/material.dart';
import '../models/room_data.dart';
import '../models/interactable_data.dart';
import '../models/dialogue_data.dart';

/// Gestor de habitaciones del búnker (Capítulo 2)
class BunkerRoomManager {
  final Map<String, RoomData> _rooms = {};
  String _currentRoomId = 'exterior_large';

  BunkerRoomManager() {
    _initializeRooms();
  }

  RoomData get currentRoom => _rooms[_currentRoomId]!;
  
  void changeRoom(String roomId) {
    if (_rooms.containsKey(roomId)) {
      _currentRoomId = roomId;
    }
  }

  void _initializeRooms() {
    // 0. EXTERIOR AMPLIO (mapa grande con cámara que sigue)
    _rooms['exterior_large'] = RoomData(
      id: 'exterior_large',
      name: 'Camino al Búnker',
      type: RoomType.exterior,
      backgroundColor: const Color(0xFF3A4A3A), // Verde oscuro (bosque/exterior)
      playerSpawnPosition: const Vector2(400, 1200),
      roomSize: const Size(2000, 1500),
      cameraMode: CameraMode.follow,
      interactables: [
        InteractableData(
          id: 'road_sign',
          name: 'Señal de Carretera',
          position: const Vector2(400, 1000),
          size: const Vector2(60, 60),
          type: InteractableType.object,
          dialogue: DialogueSequence(
            id: 'road_sign_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Sistema',
                text: 'ZONA RESTRINGIDA - Solo personal autorizado',
                type: DialogueType.system,
              ),
            ],
          ),
        ),
        InteractableData(
          id: 'abandoned_car',
          name: 'Vehículo Abandonado',
          position: const Vector2(800, 800),
          size: const Vector2(80, 80),
          type: InteractableType.object,
          dialogue: DialogueSequence(
            id: 'car_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Dan',
                text: 'Un vehículo militar abandonado. Hace tiempo que nadie viene por aquí.',
                type: DialogueType.internal,
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_bunker_entrance',
          position: Vector2(950, 300),
          size: Vector2(100, 100),
          targetRoomId: 'exterior',
          label: 'Entrada',
          targetSpawnPosition: Vector2(350, 400),
        ),
      ],
    );

    // 1. EXTERIOR DEL BÚNKER (entrada del búnker y área de mini-combate)
    _rooms['exterior'] = RoomData(
      id: 'exterior',
      name: 'Exterior',
      type: RoomType.exterior,
      backgroundColor: const Color(0xFF4A5A4A), // Verde grisáceo
      playerSpawnPosition: const Vector2(350, 400),
      roomSize: const Size(700, 500),
      interactables: [
        InteractableData(
          id: 'bunker_entrance',
          name: 'Entrada del Búnker',
          position: const Vector2(350, 100),
          size: const Vector2(100, 80),
          type: InteractableType.door,
          dialogue: DialogueSequence(
            id: 'entrance_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Dan',
                text: 'El búnker. Hace años que no venía aquí.',
                type: DialogueType.internal,
              ),
            ],
          ),
        ),
        InteractableData(
          id: 'bunker_sign',
          name: 'Señalización',
          position: const Vector2(200, 150),
          size: const Vector2(60, 60),
          type: InteractableType.object,
          dialogue: DialogueSequence(
            id: 'sign_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Sistema',
                text: 'BÚNKER CLASIFICADO - ACCESO RESTRINGIDO',
                type: DialogueType.system,
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_vestibule',
          position: Vector2(300, 0), // Arriba (Flush)
          size: Vector2(100, 80),
          targetRoomId: 'vestibule',
          label: 'Entrar',
          targetSpawnPosition: Vector2(350, 400), // Spawn abajo en vestíbulo
        ),
      ],
    );

    // 1. VESTÍBULO
    _rooms['vestibule'] = RoomData(
      id: 'vestibule',
      name: 'Vestíbulo',
      type: RoomType.hallway,
      backgroundColor: const Color(0xFF3A3A4A),
      playerSpawnPosition: const Vector2(350, 400),
      roomSize: const Size(700, 500),
      interactables: [
        InteractableData(
          id: 'security_panel',
          name: 'Panel de Seguridad',
          position: const Vector2(150, 200),
          size: const Vector2(60, 60),
          type: InteractableType.object,
          dialogue: DialogueSequence(
            id: 'security_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Dan',
                text: 'Sistemas de seguridad activos. Todo parece en orden.',
                type: DialogueType.internal,
              ),
            ],
          ),
        ),
        InteractableData(
          id: 'lockers',
          name: 'Casilleros',
          position: const Vector2(550, 200),
          size: const Vector2(60, 60),
          type: InteractableType.object,
          dialogue: DialogueSequence(
            id: 'lockers_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Dan',
                text: 'Casilleros vacíos. El personal fue evacuado hace tiempo.',
                type: DialogueType.internal,
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_exterior',
          position: Vector2(300, 450), // Abajo (Flush)
          size: Vector2(100, 50),
          targetRoomId: 'exterior',
          label: 'Salir',
          targetSpawnPosition: Vector2(350, 100), // Spawn arriba en exterior
        ),
        const DoorData(
          id: 'door_to_hallway',
          position: Vector2(300, 0), // Arriba (Flush)
          size: Vector2(100, 50),
          targetRoomId: 'hallway',
          label: 'Pasillo',
          targetSpawnPosition: Vector2(350, 400), // Spawn abajo en pasillo
        ),
      ],
    );

    // 2. PASILLO PRINCIPAL (hub)
    _rooms['hallway'] = RoomData(
      id: 'hallway',
      name: 'Pasillo Principal',
      type: RoomType.hallway,
      backgroundColor: const Color(0xFF3A3A5A),
      playerSpawnPosition: const Vector2(350, 400),
      roomSize: const Size(700, 500),
      interactables: [
        InteractableData(
          id: 'bunker_map',
          name: 'Mapa del Búnker',
          position: const Vector2(350, 250),
          size: const Vector2(80, 60),
          type: InteractableType.object,
          dialogue: DialogueSequence(
            id: 'map_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Dan',
                text: 'El layout del búnker. Laboratorio, armería, centro de comando...',
                type: DialogueType.internal,
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_vestibule_from_hallway',
          position: Vector2(300, 450), // Abajo (Flush)
          size: Vector2(100, 50),
          targetRoomId: 'vestibule',
          label: 'Vestíbulo',
          targetSpawnPosition: Vector2(350, 100), // Spawn arriba en vestíbulo
        ),
        const DoorData(
          id: 'door_to_armory',
          position: Vector2(300, 0), // Arriba (Flush) - Asumiendo Armería arriba por coordenadas originales
          size: Vector2(100, 50),
          targetRoomId: 'armory',
          label: 'Armería',
          targetSpawnPosition: Vector2(350, 400), // Spawn abajo en armería
        ),
        const DoorData(
          id: 'door_to_library',
          position: Vector2(0, 250), // Izquierda (Flush)
          size: Vector2(50, 100),
          targetRoomId: 'library',
          label: 'Archivo',
          targetSpawnPosition: Vector2(600, 250), // Spawn derecha en biblioteca
        ),
        const DoorData(
          id: 'door_to_lab',
          position: Vector2(650, 250), // Derecha (Flush)
          size: Vector2(50, 100),
          targetRoomId: 'laboratory',
          label: 'Laboratorio',
          targetSpawnPosition: Vector2(100, 250), // Spawn izquierda en laboratorio
        ),
        const DoorData(
          id: 'door_to_command',
          position: Vector2(500, 0), // Arriba (Flush) - Offset
          size: Vector2(100, 50),
          targetRoomId: 'command',
          label: 'Comando',
          targetSpawnPosition: Vector2(350, 400), // Spawn abajo en comando
        ),
      ],
    );

    // 3. ARMERÍA
    _rooms['armory'] = RoomData(
      id: 'armory',
      name: 'Armería',
      type: RoomType.armory,
      backgroundColor: const Color(0xFF4A4A3A),
      playerSpawnPosition: const Vector2(350, 400),
      roomSize: const Size(700, 500),
      interactables: [
        InteractableData(
          id: 'weapon_rack',
          name: 'Estante de Armas',
          position: const Vector2(200, 200),
          size: const Vector2(80, 80),
          type: InteractableType.object,
          dialogue: DialogueSequence(
            id: 'weapons_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Dan',
                text: 'Cuchillo del Diente Caótico y mi pistola estándar. Hora de trabajar.',
                type: DialogueType.internal,
              ),
              DialogueData(
                speakerName: 'Sistema',
                text: 'ARMAS ADQUIRIDAS: Cuchillo (100 DMG) | Pistola (20 DMG)',
                type: DialogueType.system,
              ),
            ],
          ),
        ),
        InteractableData(
          id: 'workbench',
          name: 'Mesa de Trabajo',
          position: const Vector2(500, 200),
          size: const Vector2(80, 80),
          type: InteractableType.object,
          dialogue: DialogueSequence(
            id: 'workbench_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Dan',
                text: 'Herramientas de mantenimiento. Todo en perfecto estado.',
                type: DialogueType.internal,
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_hallway_from_armory',
          position: Vector2(300, 450), // Abajo (Flush)
          size: Vector2(100, 50),
          targetRoomId: 'hallway',
          label: 'Pasillo',
          targetSpawnPosition: Vector2(350, 100), // Spawn arriba en pasillo
        ),
      ],
    );

    // 4. BIBLIOTECA/ARCHIVOS
    _rooms['library'] = RoomData(
      id: 'library',
      name: 'Archivo',
      type: RoomType.library,
      backgroundColor: const Color(0xFF3A3A4A),
      playerSpawnPosition: const Vector2(600, 250),
      roomSize: const Size(700, 500),
      interactables: [
        InteractableData(
          id: 'documents',
          name: 'Documentos Clasificados',
          position: const Vector2(200, 200),
          size: const Vector2(80, 80),
          type: InteractableType.object,
          dialogue: DialogueSequence(
            id: 'documents_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Dan',
                text: 'Reportes sobre Resonantes. Entidades que se alimentan de emociones...',
                type: DialogueType.internal,
              ),
              const DialogueData(
                speakerName: 'Dan',
                text: 'Necesitan un "ancla" física. Un objeto obsesivo que los mantiene en este plano.',
                type: DialogueType.internal,
              ),
            ],
          ),
        ),
        InteractableData(
          id: 'terminal',
          name: 'Terminal',
          position: const Vector2(500, 250),
          size: const Vector2(60, 60),
          type: InteractableType.object,
          dialogue: DialogueSequence(
            id: 'terminal_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Sistema',
                text: 'ÚLTIMA UBICACIÓN REGISTRADA: Emma Kowalski - Universidad de Kioto, Sector 4',
                type: DialogueType.system,
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_hallway_from_library',
          position: Vector2(650, 250), // Derecha (Flush)
          size: Vector2(50, 100),
          targetRoomId: 'hallway',
          label: 'Pasillo',
          targetSpawnPosition: Vector2(100, 250), // Spawn izquierda en pasillo
        ),
      ],
    );

    // 5. LABORATORIO CENTRAL (Mel)
    _rooms['laboratory'] = RoomData(
      id: 'laboratory',
      name: 'Laboratorio',
      type: RoomType.laboratory,
      backgroundColor: const Color(0xFF2A4A5A),
      playerSpawnPosition: const Vector2(100, 250),
      roomSize: const Size(700, 500),
      interactables: [
        InteractableData(
          id: 'mel_capsule',
          name: 'Mel',
          position: const Vector2(350, 250),
          size: const Vector2(100, 100),
          type: InteractableType.character,
          spritePath: 'assets/avatars/full_body/mel_fullbody.png',
          dialogue: DialogueSequence(
            id: 'mel_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Dan',
                text: '¿Mel? Keller.',
                avatarPath: 'assets/avatars/dialogue_icons/dan_dialogue.png',
              ),
              DialogueData(
                speakerName: 'Mel',
                text: 'Lo sé. El ex-investigador que voló doce horas para convertirse en un padre desesperado.',
                avatarPath: 'assets/avatars/dialogue_icons/mel_dialogue.png',
              ),
              DialogueData(
                speakerName: 'Mel',
                text: 'Un perfil que el Sector 4 ama.',
                avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Dan',
                text: 'Marcus dijo que eres Soporte Vital. ¿Qué significa en campo?',
                avatarPath: 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Mel',
                text: 'Significa que soy el ancla.',
                avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Mel',
                text: 'Aquí no cazamos básicos de Sector 2, los que atacan por puro instinto.',
                avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Mel',
                text: 'Aquí enfrentamos Amenazas de Sector 4. Kijin. Cazadores tácticos.',
                avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Mel',
                text: 'Piensan. Priorizan objetivos. Flanquean. Se alimentan de la ira.',
                avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Dan',
                text: 'Lo sé. Marcus me lo explicó.',
                avatarPath: 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Mel',
                text: 'No todo.',
                avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Mel',
                text: 'Si te superan, si la desesperación te rompe, no solo detengo sangrados.',
                avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Mel',
                text: 'Te afirmo a la vida. Te devuelvo al foco cuando el cuerpo cede.',
                avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Dan',
                text: 'Recuperación. Lo entiendo.',
                avatarPath: 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Mel',
                text: 'Es más que eso. Y no es infinito.',
                avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Dan',
                text: '¿Recurso?',
                avatarPath: 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Mel',
                text: 'Tengo una ventana de recarga. Si me fuerzas sin cabeza, me pedirás cuando aún no esté lista.',
                avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Mel',
                text: 'Y entonces mueres.',
                avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Dan',
                text: 'Gestión de recursos. Sinergia. Entendido.',
                avatarPath: 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
              ),
            ],
          ),
        ),
        InteractableData(
          id: 'monitoring_console',
          name: 'Consola de Monitoreo',
          position: const Vector2(550, 150),
          size: const Vector2(60, 60),
          type: InteractableType.object,
          dialogue: DialogueSequence(
            id: 'console_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Sistema',
                text: 'MEL - Estado: Activo. Soporte Vital disponible.',
                type: DialogueType.system,
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_hallway_from_lab',
          position: Vector2(0, 250), // Izquierda (Flush)
          size: Vector2(50, 100),
          targetRoomId: 'hallway',
          label: 'Pasillo',
          targetSpawnPosition: Vector2(600, 250), // Spawn derecha en pasillo
        ),
        const DoorData(
          id: 'door_to_quarters',
          position: Vector2(300, 0), // Arriba (Flush)
          size: Vector2(100, 50),
          targetRoomId: 'quarters',
          label: 'Cuartel',
          targetSpawnPosition: Vector2(350, 400), // Spawn abajo en cuartel
        ),
        const DoorData(
          id: 'door_to_cafeteria',
          position: Vector2(650, 250), // Derecha (Flush)
          size: Vector2(50, 100),
          targetRoomId: 'cafeteria',
          label: 'Comedor',
          targetSpawnPosition: Vector2(100, 250), // Spawn izquierda en comedor
        ),
      ],
    );

    // 6. CENTRO DE COMANDO
    _rooms['command'] = RoomData(
      id: 'command',
      name: 'Centro de Comando',
      type: RoomType.command,
      backgroundColor: const Color(0xFF3A3A5A),
      playerSpawnPosition: const Vector2(350, 400),
      roomSize: const Size(700, 500),
      interactables: [
        InteractableData(
          id: 'main_console',
          name: 'Consola Principal',
          position: const Vector2(350, 200),
          size: const Vector2(100, 80),
          type: InteractableType.object,
          dialogue: DialogueSequence(
            id: 'briefing_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Marcus',
                text: 'Dan, aquí Marcus. ¿Me copias?',
                avatarPath: 'assets/avatars/dialogue_icons/marcus_dialogue.png',
              ),
              DialogueData(
                speakerName: 'Dan',
                text: 'Te copio. Estoy en el centro de comando.',
                avatarPath: 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Marcus',
                text: 'Emma está en el Sector 4. Actividad Resonante confirmada.',
                avatarPath: 'assets/avatars/dialogue_icons/Marcus_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Marcus',
                text: 'Recuerda: los Resonantes son invulnerables hasta que destruyas su objeto obsesivo.',
                avatarPath: 'assets/avatars/dialogue_icons/Marcus_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Dan',
                text: 'Entendido. Voy para allá.',
                avatarPath: 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
              ),
            ],
          ),
        ),
        InteractableData(
          id: 'holographic_map',
          name: 'Mapa Holográfico',
          position: const Vector2(500, 300),
          size: const Vector2(80, 60),
          type: InteractableType.object,
          dialogue: DialogueSequence(
            id: 'holo_map_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Sistema',
                text: 'SECTOR 4 - Universidad de Kioto. Distancia: 8,547 km',
                type: DialogueType.system,
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_hallway_from_command',
          position: Vector2(200, 450), // Abajo (Flush)
          size: Vector2(100, 50),
          targetRoomId: 'hallway',
          label: 'Pasillo',
          targetSpawnPosition: Vector2(350, 100), // Spawn arriba en pasillo
        ),
      ],
    );

    // 7. DORMITORIO (opcional)
    _rooms['quarters'] = RoomData(
      id: 'quarters',
      name: 'Cuartel',
      type: RoomType.bedroom,
      backgroundColor: const Color(0xFF3A3A4A),
      playerSpawnPosition: const Vector2(350, 400),
      roomSize: const Size(700, 500),
      interactables: [
        InteractableData(
          id: 'bed',
          name: 'Cama',
          position: const Vector2(300, 200),
          size: const Vector2(100, 80),
          type: InteractableType.object,
          dialogue: DialogueSequence(
            id: 'bed_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Dan',
                text: 'Cuántas noches pasé aquí. Planeando misiones, estudiando amenazas...',
                type: DialogueType.internal,
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_lab_from_quarters',
          position: Vector2(300, 450), // Abajo (Flush)
          size: Vector2(100, 50),
          targetRoomId: 'laboratory',
          label: 'Laboratorio',
          targetSpawnPosition: Vector2(350, 100), // Spawn arriba en laboratorio
        ),
      ],
    );

    // 8. COMEDOR (opcional)
    _rooms['cafeteria'] = RoomData(
      id: 'cafeteria',
      name: 'Comedor',
      type: RoomType.cafeteria,
      backgroundColor: const Color(0xFF4A4A3A),
      playerSpawnPosition: const Vector2(100, 250),
      roomSize: const Size(700, 500),
      interactables: [
        InteractableData(
          id: 'table',
          name: 'Mesa',
          position: const Vector2(350, 250),
          size: const Vector2(120, 80),
          type: InteractableType.object,
          dialogue: DialogueSequence(
            id: 'table_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Dan',
                text: 'La última comida que tuve aquí fue hace... ¿cuánto? ¿Años?',
                type: DialogueType.internal,
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_lab_from_cafeteria',
          position: Vector2(0, 250), // Izquierda (Flush)
          size: Vector2(50, 100),
          targetRoomId: 'laboratory',
          label: 'Laboratorio',
          targetSpawnPosition: Vector2(600, 250), // Spawn derecha en laboratorio
        ),
      ],
    );
  }
}
