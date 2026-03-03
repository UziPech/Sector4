# Refactor de HUD, Efecto Linterna y UX de Combate (02-03-2026)

Este documento detalla la reestructuración visual del HUD de combate y la integración del efecto de "linterna" (flashlight) en todas las escenas del juego para potenciar la atmósfera de horror.

## 1. Implementación del Efecto Linterna (`FlashlightOverlay`)
- **Concepto:** Se creó un componente `CustomPainter` que oscurece toda la pantalla dejando un círculo de luz central que simula una linterna.
- **Integración Transversal:**
  - **Escenas Narrativas (`house_scene.dart`, `bunker_scene.dart`):** Se integró en el `Stack` de Flutter arriba de la vista del mapa, permitiendo que la "linterna" siga al jugador calculando su posición relativa a la pantalla.
  - **Escenas de Combate (Flame):** Se registró un nuevo overlay en `main.dart` llamado `FlashlightLayer`. Este se coloca físicamente **encima** del canvas de Flame pero **debajo** de la interfaz de usuario de Flutter (`GameUI`).
- **Configuración:**
  - Radio interno (luz plena): 140.0
  - Radio externo (penumbra): 280.0
  - Opacidad de sombra: 96% (Casi negro absoluto).

## 2. Migración del HUD de Flame a Flutter (`GameUI.dart`)
- **Problema:** El HUD original de combate (vida, vidas, botones) se dibujaba en el canvas de Flame, por lo que el efecto linterna (Flutter) lo cubría por completo, volviéndolo invisible.
- **Solución:** Se migró toda la lógica visual del HUD a un overlay de Flutter (`GameUI`). Esto permite que los indicadores de vida y botones de ataque estén **siempre visibles** por encima de la oscuridad de la linterna.
- **Sincronización:** Se añadieron `ValueNotifiers` en `ExpedienteKorinGame` para que Flutter pueda reaccionar en tiempo real a los cambios de salud (`playerHealth`), vidas (`lives`) y tiempos de recarga de Mel (`melCooldown`).
- **Limpieza:** Se vació el método `render()` de `GameHUD.dart` en Flame para evitar el renderizado doble (el HUD viejo "fantasma" que se veía debajo).

## 3. Rediseño de UX y Estética "Horror"
- **Paleta de Colores:** Se eliminaron los colores neón/brillantes originales. Ahora la UI usa una paleta de **cafés oscuros, negros translúcidos y ambar**, inspirada en juegos de terror clásicos:
  - Fondo HUD: `#1A0F08` (Café muy oscuro/negro).
  - Acentos de selección y botones: `#7B4A2A` y `#D4A96A` (Ámbar).
  - Barras de vida: Verde apagado → Ámbar → Rojo oscuro.
- **Minimalismo Narrativo:**
  - El panel de "MODO BOSS" / "Objetivo" ahora se **auto-oculta tras 4 segundos** de inactividad o al iniciar la escena.
  - Se re-muestra automáticamente solo cuando el objetivo cambia, reduciendo el ruido visual constante.
  - Se añadió una pequeña pestaña (tab) lateral para volver a desplegarlo manualmente.
- **Ayudas Contextuales:**
  - El recordatorio de controles (WASD/Flechas) ahora es un hint que **se desvanece suavemente (fade-out)** tras los primeros 3 segundos de juego.

## 4. Otros Ajustes Técnicos
- **Joystick Dinámico:** Se integró el joystick dentro del mismo `Stack` de `GameUI` para consistencia visual.
- **Fix de Timers:** Se corrigió un error en `bunker_scene.dart` donde el joystick reseteaba incorrectamente el timer de visibilidad del HUD narrativo.
- **Botones de Acción:** Los botones de "Ataque", "Cambio de Arma", "Recarga", "Dash" y "Resurrección" ahora son botones táctiles de Flutter con feedback visual al presionar y sombreado premium.
