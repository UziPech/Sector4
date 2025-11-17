# Diseño del Búnker - Capítulo 2

## Análisis de la imagen de referencia

### Habitaciones identificadas (de arriba a abajo, izquierda a derecha):

1. **Armería/Arsenal** (superior izquierda)
   - Estantes con armas
   - Mesa de trabajo
   - Posible punto de pickup de armas

2. **Dormitorio/Cuartel** (superior centro)
   - Cama
   - Muebles personales
   - Posible diálogo sobre la vida en el búnker

3. **Comedor/Cocina** (superior derecha)
   - Mesas
   - Área de preparación
   - Posible interacción casual

4. **Biblioteca/Archivos** (centro izquierda)
   - Estantes con documentos
   - Mesa de lectura
   - Posible lore/información del Sector 4

5. **Laboratorio Central** (centro)
   - Cápsula/tanque central con luz azul
   - Consolas de monitoreo
   - **PUNTO CLAVE: Aquí está Mel**
   - Diálogo principal del capítulo

6. **Centro de Comando** (inferior centro)
   - Símbolo circular en el suelo
   - Consolas de control
   - Posible briefing/misión

## Flujo narrativo propuesto

### Secuencia completa del Capítulo 2:

```
CAPÍTULO 1: Casa de Dan
    ↓ (teléfono con Marcus)
    ↓
TRANSICIÓN (fade to black, viaje)
    ↓
CAPÍTULO 2: EXTERIOR DEL BÚNKER (spawn inicial)
    ↓
Interactuar con la entrada (E)
    ↓
VESTÍBULO (primera habitación interior)
    ↓
PASILLO PRINCIPAL (hub central)
    ↓
[Exploración opcional de habitaciones]
    ↓
LABORATORIO CENTRAL (objetivo principal)
    ↓
Encuentro con Mel (diálogo clave)
    ↓
CENTRO DE COMANDO (briefing)
    ↓
Salir al EXTERIOR (volver afuera del búnker)
    ↓
🎮 MINI-COMBATE (fuera del búnker, primer Resonante)
    ↓
Destruir objeto obsesivo
    ↓
Derrotar al Resonante
    ↓
TRANSICIÓN AL COMBATE PRINCIPAL (Sector 4/Universidad)
    ↓
MyApp/ExpedienteKorinGame (combate completo)

NOTA: El mini-combate sucede EN EL EXTERIOR del búnker,
      no dentro. Es parte del BunkerScene pero en modo combate.
```

## Habitaciones definidas para implementación

### 0. Exterior del Búnker ⭐ (NUEVO)
- **Nombre:** "Exterior"
- **Descripción:** Vista aérea/mapa del búnker enterrado. Se ve la entrada metálica
- **Spawn inicial:** Dan aparece cerca de la entrada (llegada desde la casa)
- **Spawn después del briefing:** Dan sale del búnker para el mini-combate
- **Interactables:**
  - **Puerta del búnker** - Al interactuar (E) → Transición al interior
  - Señalización (diálogo: "Búnker clasificado. Acceso restringido.")
- **Puertas:** 
  - Entrada del búnker → Vestíbulo (fade to black)
- **Visual:** Mapa simple con la estructura del búnker visible desde arriba, entrada destacada
- **MODO COMBATE:** Después del briefing, esta misma habitación cambia a modo combate:
  - Aparece el primer Resonante
  - Aparece el objeto obsesivo (debe destruirse primero)
  - Mel está disponible para usar su habilidad
  - Al derrotar al Resonante → Transición a MyApp (Sector 4)

### 1. Vestíbulo/Recepción (NUEVO)
- **Nombre:** "Vestíbulo"
- **Descripción:** Primera habitación al entrar. Área de seguridad y descontaminación
- **Spawn:** Frente a la puerta de entrada
- **Interactables:**
  - Panel de control (diálogo sobre sistemas de seguridad)
  - Casilleros/taquillas (diálogo sobre el personal)
- **Puertas:**
  - **Norte → Pasillo Principal** (hacia el interior del búnker)
  - **Sur → Salida al Exterior** (puerta de emergencia)
- **Objetivo inicial:** "Explorar el búnker"

### 2. Pasillo Principal (antes era #1)
- **Nombre:** "Pasillo Principal"
- **Descripción:** Hub central con puertas a todas las áreas
- **Spawn:** Desde el Vestíbulo
- **Puertas:** 
  - Sur → Vestíbulo
  - Norte → Armería
  - Este → Laboratorio Central
  - Oeste → Biblioteca
  - Noreste → Centro de Comando
- **Interactables:** Mapa del búnker en la pared (muestra layout)

### 3. Armería
- **Nombre:** "Armería"
- **Descripción:** Sala con armamento y equipo táctico
- **Interactables:**
  - Estante de armas (diálogo sobre el equipo disponible)
  - Mesa de trabajo (futuro: pickup de armas)
- **Puertas:** Sur → Pasillo Principal

### 4. Biblioteca/Archivos
- **Nombre:** "Archivo"
- **Descripción:** Documentos clasificados sobre el Sector 4
- **Interactables:**
  - Estante de documentos (lore sobre Resonantes)
  - Terminal (información sobre Emma)
- **Puertas:** Este → Pasillo Principal

### 5. Laboratorio Central ⭐
- **Nombre:** "Laboratorio"
- **Descripción:** Sala principal con cápsula de contención
- **Interactables:**
  - **Mel (cápsula)** - Diálogo principal del capítulo
  - Consola de monitoreo (estado de Mel)
- **Puertas:** 
  - Oeste → Pasillo Principal
  - Norte → Dormitorio
  - Este → Comedor

### 6. Centro de Comando
- **Nombre:** "Centro de Comando"
- **Descripción:** Sala de operaciones con el símbolo en el suelo
- **Interactables:**
  - **Consola principal** - Briefing de la misión
  - Mapa holográfico (ubicación del Sector 4)
- **Puertas:** Suroeste → Pasillo Principal
- **Trigger:** Después del diálogo aquí → Transición al combate

### 7. Dormitorio (opcional)
- **Nombre:** "Cuartel"
- **Descripción:** Habitación de descanso
- **Interactables:** Cama (diálogo interno sobre el cansancio)
- **Puertas:** Sur → Laboratorio

### 8. Comedor (opcional)
- **Nombre:** "Comedor"
- **Descripción:** Área de alimentación
- **Interactables:** Mesa (diálogo sobre la última comida)
- **Puertas:** Oeste → Laboratorio

## Objetivos del capítulo

1. **Explorar el búnker** (opcional: visitar habitaciones secundarias)
2. **Encontrar a Mel** en el Laboratorio Central
3. **Diálogo con Mel** (explicación de su naturaleza, habilidades)
4. **Ir al Centro de Comando** para el briefing
5. **Transición al combate** (Sector 4)

## Mecánicas a implementar

### Fase de exploración:
- ✅ Sistema de habitaciones (igual que HouseScene)
- ✅ Transiciones con fade (400ms)
- ✅ Cooldown de puertas (0.5s)
- ✅ Interacción con E
- ✅ Skip de diálogos con ESC
- 🆕 HUD muestra "Objetivo: Encontrar a Mel" → "Objetivo: Ir al Centro de Comando"
- 🆕 Mel como personaje especial (posible animación/efecto en la cápsula)

### Fase de mini-combate (Exterior):
- 🆕 Cambio de modo: exploración → combate
- 🆕 Spawn de enemigo (Resonante menor)
- 🆕 Spawn de objeto obsesivo (destructible)
- 🆕 Mecánica: el Resonante es invulnerable hasta destruir el objeto
- 🆕 Controles de combate: WASD + Espacio (disparar) + E (Mel)
- 🆕 Mel disponible como companion con habilidad de curación
- 🆕 Al derrotar al Resonante → Transición a MyApp (Sector 4)

## Diálogos clave a implementar

### Mel (Laboratorio):
- Presentación de Mel
- Explicación de su origen (IA/entidad)
- Habilidad de curación (Soporte Vital)
- Vínculo con Dan

### Centro de Comando:
- Marcus (voz/comunicación remota)
- Briefing sobre el Sector 4
- Ubicación de Emma
- Amenazas activas (Resonantes)

## Resumen de habitaciones

**Total: 9 habitaciones**

0. Exterior (spawn inicial, vista del mapa)
1. Vestíbulo (entrada/salida)
2. Pasillo Principal (hub)
3. Armería
4. Biblioteca/Archivos
5. Laboratorio Central ⭐ (Mel)
6. Centro de Comando ⭐ (briefing final)
7. Dormitorio (opcional)
8. Comedor (opcional)

## Próximos pasos de implementación

1. Crear `BunkerRoomManager` similar a `RoomManager`
2. Definir las **9 habitaciones** con sus datos (incluyendo Exterior y Vestíbulo)
3. Implementar `BunkerScene` reutilizando la lógica de `HouseScene`
4. Agregar los diálogos del Capítulo 2 desde `DIALOGOS_CAPITULOS_1_2.md`
5. Conectar la transición desde `HouseScene._transitionToCombat()` → `BunkerScene`
6. Implementar el trigger final que lleva al combate real
7. **Especial:** El Exterior debe mostrar un mapa visual simple del búnker

---

**Nota:** Este diseño prioriza la experiencia narrativa y la exploración antes que los gráficos. Los mapas Tiled se integrarán después.
