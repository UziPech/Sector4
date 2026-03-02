import re

path = 'lib/narrative/systems/bunker_room_manager.dart'
with open(path, 'r') as f:
    content = f.read()

# Make sure we don't mess up targetSpawnPosition
# The rules:
# Top door means we go UP, so we arrive at Bottom. Target spawn: Y=350 or Y=300
# Bottom door means we go DOWN, so we arrive at Top. Target spawn: Y=150
# Left door means we go LEFT, so we arrive at Right. Target spawn: X=500
# Right door means we go RIGHT, so we arrive at Left. Target spawn: X=200

# But wait, looking at the code, it's easier to just do text replacements.
replacements = [
    # exterior_large
    ("targetSpawnPosition: Vector2(350, 350),", "targetSpawnPosition: Vector2(350, 150), // Spawn arriba en exterior"),
    
    # exterior
    ("targetSpawnPosition: Vector2(350, 350), // Spawn abajo en vestíbulo", "targetSpawnPosition: Vector2(350, 150), // Spawn arriba en vestíbulo"),
    
    # vestibule
    ("targetSpawnPosition: Vector2(350, 350), // Spawn abajo en pasillo", "targetSpawnPosition: Vector2(350, 150), // Spawn arriba en pasillo"),
    
    # hallway
    ("targetSpawnPosition: Vector2(350, 350), // Spawn abajo en armería", "targetSpawnPosition: Vector2(350, 150), // Spawn arriba en armería"),
    ("targetSpawnPosition: Vector2(550, 250), // Spawn derecha en biblioteca", "targetSpawnPosition: Vector2(400, 250), // Alejado de la puerta derecha"),
    ("targetSpawnPosition: Vector2(\n            150,\n            250,\n          ), // Spawn izquierda en laboratorio", "targetSpawnPosition: Vector2(250, 250), // Alejado de puerta izq en laboratorio"),
    ("targetSpawnPosition: Vector2(350, 350), // Spawn abajo en comando", "targetSpawnPosition: Vector2(350, 150), // Spawn arriba en comando"),
    
    # library
    ("targetSpawnPosition: Vector2(150, 250), // Spawn izquierda en pasillo", "targetSpawnPosition: Vector2(250, 250), // Alejado de puerta izq en pasillo"),
    
    # lab
    ("targetSpawnPosition: Vector2(\n            550,\n            250,\n          ), // Ajustado de 600 a 550 para evitar colisión con pared", "targetSpawnPosition: Vector2(400, 250), // Alejado de la puerta derecha"),
    ("targetSpawnPosition: Vector2(350, 350), // Spawn abajo en cuartel", "targetSpawnPosition: Vector2(350, 150), // Spawn arriba en cuartel"),
    ("targetSpawnPosition: Vector2(150, 250), // Spawn izquierda en comedor", "targetSpawnPosition: Vector2(250, 250), // Alejado de puerta izq comedor"),
    
    # cafeteria
    ("targetSpawnPosition: Vector2(\n            550,\n            250,\n          ), // Spawn derecha en laboratorio", "targetSpawnPosition: Vector2(400, 250), // Alejado de puerta derecha lab"),
]

for old, new in replacements:
    content = content.replace(old, new)


with open(path, 'w') as f:
    f.write(content)

