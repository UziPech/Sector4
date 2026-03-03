# Corrección de UI de Combate, Codificación y Colisiones (03-03-2026)

Este documento detalla las correcciones aplicadas para limpiar errores visuales, problemas de codificación de texto y errores de colisión en el mapa exterior y escenas de combate.

## 1. Corrección de Codificación de Texto (UTF-8)
- **Problema:** Tras un pull de git, múltiples caracteres especiales y símbolos (corazones, calaveras, flechas, etc.) se corrompieron mostrando cadenas como "CAPÃÂTULO".
- **Archivos corregidos:**
  - `game_ui.dart`
  - `game_over_with_advice.dart`
  - `bunker_boss_level.dart`
  - `stalker_enemy.dart`
  - `exterior_map_level.dart`
  - `main.dart`
- **Cambios:** Se restauraron los símbolos originales (♥, ⚡, ►, ⚠️, π, ∈, —, etc.) asegurando que la interfaz se vea profesional y legible.

## 2. Ajustes en Botones de Combate y Mel
- **Mejora de Mel (Heal):** Se sincronizaron los `ValueNotifiers` (`melReadyNotifier` y `melCooldownNotifier`) directamente desde el componente `MelCharacter` para asegurar que el botón de curación en el HUD responda instantáneamente al cooldown.
- **Detección de Taps:** Se añadió `HitTestBehavior.opaque` a todos los botones de acción (Ataque, Heal, Q, E, R) en `game_ui.dart` para evitar fallos de pulsación, especialmente cuando se usan cerca del área del joystick.
- **Posicionamiento:** Se ajustó el padding y posición de los botones en móviles para evitar solapamientos con otros elementos del HUD.

## 3. Resolución de Errores Visuales y Colisiones
- **Hitboxes de Debug:** Se eliminaron (comentaron) los rectángulos rojos que se dibujaban sobre las paredes y obstáculos en el mapa exterior.
- **Colisiones Fantasma:** Se deshabilitó el método `_createMapObjectCollisions()` en `ExteriorMapLevel`.
  - **Razón:** El mapa actual usa una imagen con bordes pre-diseñados. Las colisiones invisibles antiguas (Jeeps, barriles, vallas) estaban bloqueando el paso de forma inconsistente con la nueva estética visual.
- **Limpieza de Código:** Se removieron variables no utilizadas detectadas por `flutter analyze` (`shortSide` en `main.dart` y `debugPaint` en niveles) para mantener un build limpio.

## 4. Ajuste Global de Linterna
- **Dimensiones:** Siguiendo el feedback del usuario, se redujeron los radios de la linterna para hacerla más pequeña y atmosférica.
- **Globalización:** Se actualizaron los métodos `globalInnerRadius` y `globalOuterRadius` en `flashlight_overlay.dart` para que todas las escenas (combate y exploración) compartan el mismo tamaño de luz escalado proporcionalmente al ancho de la pantalla.
