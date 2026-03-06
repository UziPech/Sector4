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
      backgroundColor: const Color(
        0xFF3A4A3A,
      ), // Verde oscuro (bosque/exterior)
      playerSpawnPosition: const Vector2(400, 1200),
      roomSize: const Size(2000, 1500),
      cameraMode: CameraMode.follow,
      backgroundImage: 'assets/images/city_map_night.png',
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
                text:
                    'Un vehículo militar abandonado. Hace tiempo que nadie viene por aquí.',
                type: DialogueType.internal,
              ),
            ],
          ),
        ),

        // 200 árboles generados proceduralmente (ELIMINADOS)
        // ...TreeGenerator.generateTrees(),
      ],
      doors: [
        const DoorData(
          id: 'door_to_bunker_entrance',
          position: Vector2(950, 300),
          size: Vector2(100, 100),
          targetRoomId: 'exterior',
          label: 'Entrada',
          targetSpawnPosition: Vector2(350, 350), // bottom of exterior
        ),
      ],
    );

    // 1. EXTERIOR DEL BÚNKER (entrada del búnker y área de mini-combate)
    _rooms['exterior'] = RoomData(
      id: 'exterior',
      name: 'Exterior',
      type: RoomType.exterior,
      backgroundColor: const Color(0xFF4A5A4A), // Verde grisáceo
      playerSpawnPosition: const Vector2(350, 350),
      roomSize: const Size(700, 500),
      interactables: [],
      doors: [
        const DoorData(
          id: 'door_to_vestibule',
          position: Vector2(285, -15),
          size: Vector2(130, 130),
          targetRoomId: 'vestibule',
          label: 'Entrar',
          targetSpawnPosition: Vector2(350, 350), // bottom of vestibule
        ),
        const DoorData(
          id: 'door_to_road',
          position: Vector2(285, 385),
          size: Vector2(130, 130),
          targetRoomId: 'exterior_large',
          label: 'Camino',
          targetSpawnPosition: Vector2(950, 450), // Regresar al camino
        ),
      ],
    );

    // 1. VESTÍBULO
    _rooms['vestibule'] = RoomData(
      id: 'vestibule',
      name: 'Vestíbulo',
      type: RoomType.hallway,
      backgroundColor: const Color(0xFF3A3A4A),
      playerSpawnPosition: const Vector2(350, 350),
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
                text:
                    'Casilleros vacíos. El personal fue evacuado hace tiempo.',
                type: DialogueType.internal,
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_exterior',
          position: Vector2(285, 385),
          size: Vector2(130, 130),
          targetRoomId: 'exterior',
          label: 'Salir',
          targetSpawnPosition: Vector2(350, 150), // top of exterior
        ),
        const DoorData(
          id: 'door_to_hallway',
          position: Vector2(285, -15),
          size: Vector2(130, 130),
          targetRoomId: 'hallway',
          label: 'Pasillo',
          targetSpawnPosition: Vector2(350, 350), // bottom of hallway
        ),
      ],
    );

    // 2. PASILLO PRINCIPAL (hub)
    _rooms['hallway'] = RoomData(
      id: 'hallway',
      name: 'Pasillo Principal',
      type: RoomType.hallway,
      backgroundColor: const Color(0xFF3A3A5A),
      playerSpawnPosition: const Vector2(350, 350),
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
                text:
                    'El layout del búnker. Laboratorio, armería, centro de comando...',
                type: DialogueType.internal,
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_vestibule_from_hallway',
          position: Vector2(285, 385),
          size: Vector2(130, 130),
          targetRoomId: 'vestibule',
          label: 'Vestíbulo',
          targetSpawnPosition: Vector2(350, 150), // top of vestibule
        ),
        const DoorData(
          id: 'door_to_armory',
          position: Vector2(285, -15),
          size: Vector2(130, 130),
          targetRoomId: 'armory',
          label: 'Armería',
          targetSpawnPosition: Vector2(350, 350), // bottom of armory
        ),
        const DoorData(
          id: 'door_to_library',
          position: Vector2(-15, 185), // Izquierda
          size: Vector2(130, 130),
          targetRoomId: 'library',
          label: 'Archivo',
          targetSpawnPosition: Vector2(550, 250), // right of library
        ),
        const DoorData(
          id: 'door_to_lab',
          position: Vector2(585, 185), // Derecha
          size: Vector2(130, 130),
          targetRoomId: 'laboratory',
          label: 'Laboratorio',
          targetSpawnPosition: Vector2(150, 250), // left of lab
        ),
        const DoorData(
          id: 'door_to_command',
          position: Vector2(485, -15), // Arriba (offset)
          size: Vector2(130, 130),
          targetRoomId: 'command',
          label: 'Comando',
          targetSpawnPosition: Vector2(350, 350), // bottom of command
        ),
      ],
    );

    // 3. ARMERÍA
    _rooms['armory'] = RoomData(
      id: 'armory',
      name: 'Armería',
      type: RoomType.armory,
      backgroundColor: const Color(0xFF4A4A3A),
      playerSpawnPosition: const Vector2(350, 350),
      roomSize: const Size(700, 500),
      interactables: [
        InteractableData(
          id: 'weapon_rack',
          name: 'Estante de Armas',
          position: const Vector2(200, 200),
          size: const Vector2(80, 80),
          type: InteractableType.object,
          spritePath: 'assets/images/objects/weapon_rack.png',
          dialogue: DialogueSequence(
            id: 'weapons_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Dan',
                text: 'Cuchillo táctico \'Diente Caótico\' y mi arma reglamentaria. Es hora de despertar al perro de caza.',
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
          position: Vector2(285, 385),
          size: Vector2(130, 130),
          targetRoomId: 'hallway',
          label: 'Pasillo',
          targetSpawnPosition: Vector2(350, 150), // top of hallway center
        ),
      ],
    );

    // 4. BIBLIOTECA/ARCHIVOS
    _rooms['library'] = RoomData(
      id: 'library',
      name: 'Archivo',
      type: RoomType.library,
      backgroundColor: const Color(0xFF3A3A4A),
      playerSpawnPosition: const Vector2(550, 250),
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
                text: 'Expedientes de Resonantes... Parásitos que se anclan a los peores recuerdos de la humanidad. Tendremos que cortar esas anclas.',
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
          spritePath: 'assets/images/objects/terminal.png',
          dialogue: DialogueSequence(
            id: 'terminal_dialogue',
            dialogues: const [
              DialogueData(
                speakerName: 'Sistema',
                text:
                    'ÚLTIMA UBICACIÓN REGISTRADA: Emma Kowalski - Universidad de Kioto, Sector 4',
                type: DialogueType.system,
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_hallway_from_library',
          position: Vector2(585, 185),
          size: Vector2(130, 130),
          targetRoomId: 'hallway',
          label: 'Pasillo',
          targetSpawnPosition: Vector2(150, 250), // left of hallway
        ),
      ],
    );

    // 5. LABORATORIO CENTRAL (Mel)
    _rooms['laboratory'] = RoomData(
      id: 'laboratory',
      name: 'Laboratorio',
      type: RoomType.laboratory,
      backgroundColor: const Color(0xFF2A4A5A),
      playerSpawnPosition: const Vector2(150, 250),
      roomSize: const Size(700, 500),
      interactables: [
        InteractableData(
          id: 'mel_capsule',
          name: 'Mel',
          position: const Vector2(350, 250),
          size: const Vector2(100, 100),
          type: InteractableType.character,
          spritePath: 'assets/images/objects/mel_capsule.png',
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
                text: 'Lo sé. El ex-investigador clínico que cruzó el mundo para convertirse en un padre desesperado.',
                avatarPath: 'assets/avatars/dialogue_icons/mel_dialogue.png',
              ),
              DialogueData(
                speakerName: 'Mel',
                text: 'El perfil exacto que viene a morir aquí.',
                avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Dan',
                text: 'Marcus te asignó conmigo. Dijo que cubrirías mi espalda, que serías mi soporte en el campo.',
                avatarPath: 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Mel',
                text: 'No soy un escudo, Dan. Soy tu ancla a este lado del velo.',
                avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Mel',
                text: 'No nos enfrentamos a bestias que cazan por instinto. Son Kijin. Analizan. Esperan. Beben de tu ira y saben exactamente qué recuerdo utilizar para romperte.',
                avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Dan',
                text: 'He leído los expedientes. Conozco los riesgos.',
                avatarPath: 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Mel',
                text: 'Los expedientes no respiran. Cuando la desesperación carcoma tu mente y tu pulso ceda, yo tendré que devolverte a la luz.',
                avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Mel',
                text: 'Pero mi luz no es infinita. Toma tiempo hilar la conexión de nuevo.',
                avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Dan',
                text: '¿Me estás diciendo que si pido tu ayuda a ciegas...?',
                avatarPath: 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Mel',
                text: 'Si te lanzas al matadero por impulso o egoísmo y tu alma se apaga antes de que yo pueda extender la mano...',
                avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Mel',
                text: 'Te quedarás en la oscuridad. Ahora solo somos tú, tu caída, y yo.',
                avatarPath: 'assets/avatars/dialogue_icons/Mel_Dialogue.png',
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
          position: Vector2(-15, 185),
          size: Vector2(130, 130),
          targetRoomId: 'hallway',
          label: 'Pasillo',
          targetSpawnPosition: Vector2(500, 250), // right of hallway
        ),
        const DoorData(
          id: 'door_to_quarters',
          position: Vector2(285, -15),
          size: Vector2(130, 130),
          targetRoomId: 'quarters',
          label: 'Cuartel',
          targetSpawnPosition: Vector2(350, 350), // bottom of quarters
        ),
        const DoorData(
          id: 'door_to_cafeteria',
          position: Vector2(585, 185),
          size: Vector2(130, 130),
          targetRoomId: 'cafeteria',
          label: 'Comedor',
          targetSpawnPosition: Vector2(150, 250), // left of cafeteria
        ),
      ],
    );

    // 6. CENTRO DE COMANDO
    _rooms['command'] = RoomData(
      id: 'command',
      name: 'Centro de Comando',
      type: RoomType.command,
      backgroundColor: const Color(0xFF3A3A5A),
      playerSpawnPosition: const Vector2(350, 350),
      roomSize: const Size(700, 500),
      interactables: [
        InteractableData(
          id: 'main_console',
          name: 'Consola Principal',
          position: const Vector2(350, 200),
          size: const Vector2(100, 80),
          type: InteractableType.object,
          spritePath: 'assets/images/objects/main_console.png',
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
                text: 'Fuerte y claro. Estoy en el centro de mando.',
                avatarPath: 'assets/avatars/dialogue_icons/Dan_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Marcus',
                text: 'Confirmamos la anomalía cerca de la facultad donde estudiaba Emma.',
                avatarPath: 'assets/avatars/dialogue_icons/Marcus_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Marcus',
                text: 'Escucha con atención: los ecos que enfrentarás atan su ser a este mundo a través de objetos corruptos. Reliquias de su sufrimiento.',
                avatarPath: 'assets/avatars/dialogue_icons/Marcus_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Marcus',
                text: 'Mientras esos objetos sigan intactos en el entorno, ellos no morirán. Destruye la fuente, rompe el eco.',
                avatarPath: 'assets/avatars/dialogue_icons/Marcus_Dialogue.png',
              ),
              DialogueData(
                speakerName: 'Dan',
                text: 'Buscar y destruir el origen. Entendido.',
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
          position: Vector2(185, 385),
          size: Vector2(130, 130),
          targetRoomId: 'hallway',
          label: 'Pasillo',
          targetSpawnPosition: Vector2(485, 150), // top of hallway offset
        ),
      ],
    );

    // 7. DORMITORIO (opcional)
    _rooms['quarters'] = RoomData(
      id: 'quarters',
      name: 'Cuartel',
      type: RoomType.bedroom,
      backgroundColor: const Color(0xFF3A3A4A),
      playerSpawnPosition: const Vector2(350, 350),
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
                text:
                    'Cuántas noches pasé aquí. Planeando misiones, estudiando amenazas...',
                type: DialogueType.internal,
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_lab_from_quarters',
          position: Vector2(285, 385),
          size: Vector2(130, 130),
          targetRoomId: 'laboratory',
          label: 'Laboratorio',
          targetSpawnPosition: Vector2(350, 150), // top of lab
        ),
      ],
    );

    // 8. COMEDOR (opcional)
    _rooms['cafeteria'] = RoomData(
      id: 'cafeteria',
      name: 'Comedor',
      type: RoomType.cafeteria,
      backgroundColor: const Color(0xFF4A4A3A),
      playerSpawnPosition: const Vector2(150, 250),
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
                text:
                    'La última comida que tuve aquí fue hace... ¿cuánto? ¿Años?',
                type: DialogueType.internal,
              ),
            ],
          ),
        ),
      ],
      doors: [
        const DoorData(
          id: 'door_to_lab_from_cafeteria',
          position: Vector2(-15, 185),
          size: Vector2(130, 130),
          targetRoomId: 'laboratory',
          label: 'Laboratorio',
          targetSpawnPosition: Vector2(500, 250), // right of lab
        ),
      ],
    );
  }
}
