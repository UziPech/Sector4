import re

path = 'lib/narrative/systems/bunker_room_manager.dart'
with open(path, 'r') as f:
    t = f.read()

# I will replace each doors: [ ... ], block with exact correct text.
# To be safe, I will use regex to find doors: [ ... ], inside each room.

import re

def replace_doors(room_id, new_doors_str):
    global t
    # find `_rooms['<room_id>'] = RoomData( ... doors: [`
    # to find the specific doors we use a regex that captures everything until the next `);`
    pattern = r"(_rooms\['" + room_id + r"'\]\s*=\s*RoomData\(.*?doors:\s*\[)(.*?)(\],\s*\);)"
    t = re.sub(pattern, r"\g<1>\n" + new_doors_str + r"\n      \g<3>", t, flags=re.DOTALL)

replace_doors('exterior_large', """        const DoorData(
          id: 'door_to_bunker_entrance',
          position: Vector2(950, 300),
          size: Vector2(100, 100),
          targetRoomId: 'exterior',
          label: 'Entrada',
          targetSpawnPosition: Vector2(350, 350), // bottom of exterior
        ),""")

replace_doors('exterior', """        const DoorData(
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
        ),""")

replace_doors('vestibule', """        const DoorData(
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
        ),""")

replace_doors('hallway', """        const DoorData(
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
        ),""")

replace_doors('armory', """        const DoorData(
          id: 'door_to_hallway_from_armory',
          position: Vector2(285, 385),
          size: Vector2(130, 130),
          targetRoomId: 'hallway',
          label: 'Pasillo',
          targetSpawnPosition: Vector2(350, 150), // top of hallway center
        ),""")

replace_doors('library', """        const DoorData(
          id: 'door_to_hallway_from_library',
          position: Vector2(585, 185),
          size: Vector2(130, 130),
          targetRoomId: 'hallway',
          label: 'Pasillo',
          targetSpawnPosition: Vector2(150, 250), // left of hallway
        ),""")

replace_doors('laboratory', """        const DoorData(
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
        ),""")

replace_doors('command', """        const DoorData(
          id: 'door_to_hallway_from_command',
          position: Vector2(185, 385),
          size: Vector2(130, 130),
          targetRoomId: 'hallway',
          label: 'Pasillo',
          targetSpawnPosition: Vector2(485, 150), // top of hallway offset
        ),""")

replace_doors('quarters', """        const DoorData(
          id: 'door_to_lab_from_quarters',
          position: Vector2(285, 385),
          size: Vector2(130, 130),
          targetRoomId: 'laboratory',
          label: 'Laboratorio',
          targetSpawnPosition: Vector2(350, 150), // top of lab
        ),""")

replace_doors('cafeteria', """        const DoorData(
          id: 'door_to_lab_from_cafeteria',
          position: Vector2(-15, 185),
          size: Vector2(130, 130),
          targetRoomId: 'laboratory',
          label: 'Laboratorio',
          targetSpawnPosition: Vector2(500, 250), // right of lab
        ),""")

# Run dart format
with open(path, 'w') as f:
    f.write(t)
