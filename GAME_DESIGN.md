# Expediente Kōrin - Documento de Diseño

## Estructura General del Juego

### Fases del Juego
1. **Capítulos Narrativos** - Exploración, diálogos, construcción de historia
2. **Misiones de Combate** - Top-down shooter con mecánicas de Mel

### Flujo de Juego
```
Menú Principal
    ↓
Capítulo 1: Casa de Dan (narrativo)
    ↓
Misión 1: Universidad - Sector Exterior (combate)
    ↓
Capítulo 2: Encuentro con Mel (narrativo)
    ↓
Misión 2: Universidad - Edificio Principal (combate)
    ↓
Capítulo 3: Revelación (narrativo)
    ↓
Misión 3: Universidad - Laboratorio (combate + jefe)
    ↓
[Capítulos futuros...]
```

## Capítulo 1: El Llamado (IMPLEMENTADO)

### Objetivos
- Establecer el estado mental de Dan (duelo, depresión)
- Introducir la tragedia de Sarah
- Presentar a Emma como motivación
- Recibir la llamada de Marcus
- Establecer la urgencia de la misión

### Mecánicas
- Exploración libre de la casa
- Objetos interactuables con monólogos internos
- Trigger del teléfono → llamada de Marcus
- Transición automática a Misión 1

### Objetos Interactuables
- ✅ Foto de Sarah (esposa fallecida)
- ✅ Habitación de Emma (hija desaparecida)
- ✅ Escritorio (pasado como agente)
- ✅ Teléfono (trigger principal)

## Misión 1: Universidad - Sector Exterior (IMPLEMENTADO)

### Objetivos
- Tutorial de combate básico
- Introducir mutados de bajo nivel
- Sistema de Mel (curación)
- Supervivencia por oleadas

### Mecánicas Actuales
- Movimiento 8 direcciones (WASD/Flechas)
- Disparo (Espacio/Botón móvil)
- Curación de Mel (E/Botón móvil)
- Sistema de oleadas progresivas
- Mundo infinito con generación procedural

## Capítulo 2: Encuentro con Mel (PENDIENTE)

### Objetivos
- Presentación formal de Mel
- Explicar su rol en el Sector 4
- Revelar sus habilidades básicas
- Establecer la dinámica Dan-Mel
- Introducir el concepto de "mutados de alto rango"

### Propuesta de Escena
**Ubicación:** Campamento temporal del Sector 4 cerca de la universidad

**Secuencia:**
1. Dan llega exhausto tras la primera oleada
2. Conoce a Mel en el briefing del Sector 4
3. Mel demuestra su habilidad de curación
4. Marcus explica la misión: infiltrar el edificio principal
5. Mel es asignada como compañera de Dan
6. Diálogo sobre las capacidades de Mel (sin revelar su origen aún)

### Objetos Interactuables Propuestos
- Mapa táctico (muestra zonas de mutados)
- Equipo médico (Mel explica su curación)
- Reportes de campo (lore sobre mutados)
- Radio de comunicación (contacto con Marcus)

## Misión 2: Universidad - Edificio Principal (PENDIENTE)

### Objetivos
- Introducir enemigos más fuertes
- Enseñar mecánica de "posesión" de Mel
- Primeros indicios del origen sobrenatural
- Encontrar pistas sobre Emma

### Mecánicas Nuevas a Implementar
- **Posesión de Mel**: Cuando Mel "muere", puede poseer temporalmente a un mutado
  - Mel controla al mutado por 10 segundos
  - El mutado atacará a otros enemigos
  - Al terminar, Mel reaparece con cooldown
- **Pistas de Emma**: Objetos coleccionables que avanzan la narrativa
  - Mochila de Emma
  - Notas de clase
  - Teléfono de Emma (último mensaje)

### Diseño de Nivel
- 3 pisos del edificio
- Pasillos estrechos (combate táctico)
- Aulas con emboscadas
- Sala de servidores (pista principal)

## Capítulo 3: Revelación (PENDIENTE)

### Objetivos
- Dan encuentra evidencia de que Emma está viva
- Mel comienza a mostrar señales de su naturaleza angelical
- Introducir el concepto de "Yūrei" y folklore japonés
- Preparar para el enfrentamiento con el primer jefe

### Propuesta de Escena
**Ubicación:** Sala de servidores de la universidad

**Secuencia:**
1. Dan recupera el teléfono de Emma
2. Último mensaje de Emma: "Hay algo en el laboratorio..."
3. Mel tiene una reacción extraña al mensaje
4. Flashback breve de Mel (su padre adoptivo)
5. Dan nota que Mel no sangra cuando se lastima
6. Mel evade preguntas sobre su pasado
7. Decisión: ir al laboratorio

## Misión 3: Universidad - Laboratorio (PENDIENTE)

### Objetivos
- Primer jefe: Kijin de Fuego
- Introducir mecánica de "Mimetismo"
- Clímax del arco de la universidad
- Revelar ubicación de Emma

### Jefe: Kijin de Fuego

**Fase 1 (100% - 50% HP):**
- Ráfagas cónicas de fuego (3 proyectiles)
- Embestida telegráfica
- Invoca 2 mutados menores cada 20 segundos

**Fase 2 (50% - 0% HP):**
- Pilares de fuego zonales (AOE)
- Sobrecalentamiento (vulnerable por 5 segundos)
- Ráfagas más rápidas y numerosas

**Recompensa:**
- Mimetismo: Aura Ignífuga (30 segundos)
  - Dan es inmune al fuego
  - Ataques de Dan queman a enemigos
- Pista: Coordenadas del escondite de Emma

## Mecánicas de Mel (Sistema Completo)

### 1. Soporte Vital (Curación) - IMPLEMENTADO
- Cooldown: 15 segundos
- Efecto: Restaura 100% de vida de Dan
- Visual: Aura verde

### 2. Inmortalidad/Posesión - PENDIENTE
- Cuando Mel es "derrotada", no muere
- Posee al mutado más cercano
- Duración: 10 segundos
- Cooldown tras posesión: 30 segundos
- Visual: Aura morada en el mutado poseído

### 3. Mimetismo - PENDIENTE
- Se activa al derrotar jefes/élites
- Dan obtiene 1 habilidad temporal
- Duración: 30-45 segundos o 3 cargas
- Ejemplos:
  - **Kijin de Fuego**: Aura ignífuga + ataques de fuego
  - **Oni de Hielo**: Ralentización de enemigos
  - **Yūrei Vengativo**: Dash fantasmal

## Sistema de Progresión (Futuro)

### Mejoras de Dan
- Vida máxima aumentada
- Velocidad de movimiento
- Cadencia de disparo
- Daño de balas

### Mejoras de Mel
- Reducción de cooldown de curación
- Duración de posesión aumentada
- Múltiples habilidades de mimetismo simultáneas

## Capítulos Futuros (Roadmap)

### Capítulo 4: El Refugio
- Dan encuentra a Emma en un refugio subterráneo
- Emma revela que ha visto "ángeles y demonios"
- Introducción del antagonista principal

### Capítulo 5: La Verdad de Mel
- Mel revela su origen como "Semilla del Ángel Caído"
- Flashback: El amor prohibido de su padre celestial
- Dan debe decidir si confiar en Mel

### Capítulo 6: El Origen
- Investigación del epicentro del brote
- Revelación: Los mutados son almas en pena (Yūrei)
- Conexión entre Mel y el fenómeno

### Capítulo Final: El Legado
- Enfrentamiento con el Ángel Primigenio corrupto
- Decisión moral: ¿Sacrificar a Mel para detener el brote?
- Múltiples finales según elecciones

## Enemigos (Bestiario)

### Mutados de Bajo Nivel (IMPLEMENTADO)
- **Comportamiento:** Persecución simple, ataque cuerpo a cuerpo
- **HP:** 20
- **Velocidad:** Media
- **Spawn:** Oleadas progresivas

### Mutados de Alto Rango (PENDIENTE)

#### Kijin (Oni de Fuego)
- **Inspiración:** Oni del folklore japonés
- **Ataques:** Fuego, embestidas
- **HP:** 500 (jefe)
- **Mecánica especial:** Sobrecalentamiento

#### Yuki-Onna (Mujer de Nieve)
- **Inspiración:** Espíritu del invierno
- **Ataques:** Proyectiles de hielo, ralentización
- **HP:** 300 (mini-jefe)
- **Mecánica especial:** Crea zonas de hielo

#### Gashadokuro (Esqueleto Gigante)
- **Inspiración:** Yōkai de huesos
- **Ataques:** Pisotones, ondas de choque
- **HP:** 800 (jefe)
- **Mecánica especial:** Invoca esqueletos menores

## Estética y Atmósfera

### Visual
- Estilo pixel art / 2D top-down
- Paleta de colores oscura (grises, azules, rojos)
- Efectos de partículas para habilidades
- UI estilo RPG clásico (Undertale, Earthbound)

### Audio (Futuro)
- Música ambiental tensa para exploración
- Música intensa para combate
- Efectos de sonido impactantes
- Voces sintéticas para diálogos (opcional)

### Narrativa
- Tono: Oscuro, melancólico, con esperanza
- Temas: Duelo, redención, paternidad, sacrificio
- Inspiración: Silent Hill, The Last of Us, Undertale

## Métricas Técnicas

### Rendimiento Objetivo
- FPS: 60 constantes
- Resolución: 1920x1080 (escalable)
- Plataformas: Desktop, Web, Móvil

### Controles
- **PC:** WASD + Espacio + E + ESC
- **Móvil:** Joystick virtual + Botones táctiles
- **Gamepad:** Soporte futuro

## Próximos Pasos de Desarrollo

### Corto Plazo (Sprint 1)
- [ ] Agregar avatares de Dan y Marcus
- [ ] Pulir sistema de diálogo (sonidos, animaciones)
- [ ] Crear Capítulo 2 (Encuentro con Mel)
- [ ] Diseñar Misión 2 (Edificio Principal)

### Medio Plazo (Sprint 2-3)
- [ ] Implementar mecánica de posesión de Mel
- [ ] Implementar sistema de mimetismo
- [ ] Crear primer jefe (Kijin de Fuego)
- [ ] Sistema de coleccionables (pistas de Emma)

### Largo Plazo (Sprint 4+)
- [ ] Sistema de guardado/carga
- [ ] Múltiples capítulos narrativos
- [ ] Bestiario completo
- [ ] Sistema de progresión
- [ ] Múltiples finales

## Notas de Diseño

### Filosofía de Diseño
- **Narrativa primero:** La historia impulsa la jugabilidad
- **Mecánicas significativas:** Cada mecánica refleja la narrativa (Mel como ancla)
- **Respeto al jugador:** No padding, experiencia concentrada
- **Escalabilidad:** Arquitectura modular para expansión

### Inspiraciones
- **Narrativa:** The Last of Us, Silent Hill 2
- **Combate:** Hotline Miami, Enter the Gungeon
- **Diálogos:** Undertale, Disco Elysium
- **Folklore:** Shin Megami Tensei, Persona

### Consideraciones Culturales
- Investigar folklore japonés con respeto
- Consultar fuentes primarias sobre Yūrei y Yōkai
- Evitar estereotipos y apropiación cultural
- Representar Japón con autenticidad
