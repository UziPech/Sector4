# Corrección del Sistema de Puertas del Búnker

Este documento detalla los problemas que existían con la interacción y el cruce de las puertas del mapa del búnker y cómo se solucionaron, siguiendo el modelo más robusto utilizado en la escena "House of Dan".

## 1. Problema de Bucles y Spawns Infinitos
- **Causa:** Las posiciones de reaparición (`targetSpawnPosition`) de las puertas en `bunker_room_manager.dart` dejaban al jugador directamente sobre o demasiado cerca del área de colisión (`hitbox`) de la puerta por la que acababa de entrar. Como el sistema de cruce de puertas era automático, esto provocaba que el jugador inmediatamente activara de regreso la misma puerta, creando un bucle infinito o transiciones raras entre cuartos.
- **Solución:** Se ajustaron manualmente las coordenadas de `targetSpawnPosition` para todas las puertas del `BunkerRoomManager`, de forma que al entrar a un nuevo cuarto, el jugador aparezca en un punto lógico (frente o a un lado de la puerta) y fuera de su respectivo rango de colisión.

## 2. Transiciones Automáticas Indeseadas (Colisiones Invisibles)
- **Causa:** La función `_checkDoorCollisions` en `bunker_scene.dart` evaluaba de forma constante la posición del jugador mediante un `Timer`. Si el jugador se acercaba un poco a cualquier puerta (incluso sin querer cruzarla), el sistema forzaba la transición de escenario instantáneamente.
- **Solución:** Siguiendo la lógica de `house_scene.dart`, se **eliminó** por completo la mecánica de colisiones automáticas de `_checkDoorCollisions()`. Se trasladó la validación de acercamiento a la función manual `_tryInteract()`.

## 3. Implementación de Interacción Manual (Tecla E / Botón Táctil)
- **Causa:** Como se eliminaron las puertas automáticas, se necesitaba una forma controlada de cruzar de habitación. 
- **Solución:**
  - En `_tryInteract()`, iteramos las puertas del cuarto y preguntamos `door.isPlayerInRange()`. Si el jugador está en rango y presiona Acción ('E' o el botón táctil), el jugador cambia de habitación controladamente (`_transitionToRoom`).
  - Para asegurar compatibilidad con dispositivos móviles, en la función `_updatePlayerPosition()`, se añadió la verificación de que existan puertas cercanas para encender/habilitar la UI del botón virtual (es decir, volver `canInteract = true`).

## 4. Problema de Cercanía a Paredes y Rango de Interacción
- **Causa:** Tras cambiar al sistema manual, a veces no era posible interactuar con las puertas porque los límites rígidos o paredes invisibles (`_isPositionValid`) frenaban al jugador un par de píxeles antes de tocar la caja de colisión real de la puerta. Como la colisión requería superposición completa (`overlaps`), el jugador nunca conseguía activar el botón 'E'.
- **Solución:** En el modelo base `DoorData` (`room_data.dart`), la función `isPlayerInRange` ahora usa `inflate(30.0)` en el rectángulo de la puerta. Esto vuelve la caja de detección "*más gordita*" y permisiva, asegurando que el juego reconozca que estamos "frente a una puerta" sin exigir chocar milimétricamente contra ella.
