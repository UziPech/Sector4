# Estado Actual del Proyecto - Noviembre 2025

## 1. Arquitectura técnica limpia
- `lib/main.dart`: aplicación Flutter con `MenuScreen` y el `GameWidget` limpio que carga `ExpedienteKorinGame` y el overlay `GameOverOverlay`.
- `lib/game/expediente_game.dart`: motor principal Flame, carga mapas por capítulo, gestiona Dan y Mel, cámara, HUD y transiciones.
- `lib/game/systems/map_loader.dart`: registro de mapas por capítulo, carga de `TiledComponent`, colisiones y entidades desde las capas `collisions` y `entities`.
- `lib/game/components/player.dart`: Dan con movimiento WASD/flechas, cooldown de disparo, sistema de vida/invencibilidad y placeholder para balas.
- `lib/game/components/mel.dart`: Mel sigue al jugador, habilidad Soporte Vital (curación completa tecla E) con cooldown visual, espacios para futuras habilidades (esencias, mimetismo).
- `lib/game/ui/game_hud.dart`: HUD muestra vida de Dan, barra de progreso de Mel y texto de disponibilidad.
- Activos: `assets/tiles/capitulo_1/` y `capitulo_2/` como contenedores para los mapas Tiled; `assets/avatars/` para avatares narrativos.

## 2. Narrativa y flujo actual
- `MenuScreen` → menú principal con título, descripción, botones y versión `v0.1.0 - Capítulo 1`.
- Capítulo 1 (`HouseScene`): exploración de la casa, interactables (foto, habitación, escritorio, teléfono), monólogo inicial, llamada con Marcus, transición a combate tras completar la llamada.
- Capítulo 2 (`BunkerScene`): monólogo en tránsito, encuentro con Mel con diálogos ya definidos, posibilidad de iniciar diálogo manual y recibir introducción a habilidades.
- Archivo narrativo `DIALOGOS_CAPITULOS_1_2.md` documenta todos los diálogos por personaje en Capítulos 1 y 2.

## 3. Flujos de demo planificados
1. Inicio en el menú → `HouseScene` (Capítulo 1).
2. Interacción con objetos para exponer emociones y activar diálogo telefónico.
3. Llamada a Marcus activa transición → búnker (Capítulo 2) con diálogo entre Dan y Mel.
4. Primer combate contra un Resonante menor, obligando a buscar y destruir un objeto obsesivo antes de poder dañar al enemigo.
5. HUD del juego muestra vida y cooldown de Mel; Mel puede curar una vez.
6. Mensaje final prepara la inserción al Sector 4/Universidad.

## 4. Mecanismos ya definidos o en progreso
- **Sistema de skip de diálogo**: Presionar ESC durante cualquier diálogo lo cierra inmediatamente y ejecuta el callback `onComplete`. El HUD muestra "ESC: Saltar diálogo" cuando está activo.
- **Sistema de habitaciones con transiciones**: Cada habitación (Sala, Pasillo, Emma, Estudio) tiene puertas que activan transiciones con pantalla negra (fade out/in de 400ms). Cooldown de 0.5s evita transiciones múltiples.
- Licencia de armas y objetos destructibles se implementarán vinculándolos a `objects` en el mapa Tiled.
- La mecánica de romper objetos (mesas, vitrinas) se vincula a `DestructibleObjectComponent` con drops (munición, curación, pistas narrativas). El mapa definirá propiedades como `type = destructible` y `drop = ammo`.
- Inventario rápido permitirá cambiar entre pistola y cuchillo; cada arma tendrá stats (daño, cadencia) y la pistola puede mantener el homing actual.
- Interactivos del búnker (consolas, laboratorio, centro de mando) se definen en Tiled con propiedades `dialogueId` para reutilizar el `DialogueOverlay` y activar eventos de historia.

## 5. Documentación útil restante
- `REFACTOR_SUMMARY.md`: reporte completo de la limpieza, nueva estructura y pasos siguientes.
- `CURRENT_STATE.md` (desde aquí) centraliza qué está implementado.
- `DIALOGOS_CAPITULOS_1_2.md`: textos narrativos definitivos.

## 6. Próximos hitos sugeridos
1. Diseñar mapa Tiled de la casa con interactables y el teléfono como trigger de transición.
2. Extender `MapLoader` para instanciar interactuables/destructibles/weapon pickups desde propiedades del `.tmx`.
3. Implementar la primera arma secundaria y el sistema de destrucción de objetos con drops.
4. Crear componente `Resonante` que requiere destruir un objeto obsesivo antes de recibir daño.
5. Mantener la narrativa en el HUD y las escenas mientras el combate en el búnker se activa después de la llamada.
