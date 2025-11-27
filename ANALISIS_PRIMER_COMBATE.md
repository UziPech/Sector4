# Análisis del Primer Combate: "The Stalker" (Final del Capítulo 2)

Este documento detalla el funcionamiento del primer segmento de gameplay de combate real del juego, que ocurre tras finalizar la narrativa del Búnker (Capítulo 2).

## 1. Contexto y Objetivo
El jugador se enfrenta a una entidad hostil conocida como **"The Stalker"** (un Resonante). Este enemigo es invulnerable a los ataques convencionales debido a su conexión con un "Objeto Obsesivo" oculto en el nivel.

*   **Objetivo Principal:** Sobrevivir y derrotar al Stalker.
*   **Condición de Victoria:** Destruir el "Objeto Obsesivo" real para romper la invulnerabilidad del Stalker y luego reducir su vida a cero.
*   **Condición de Derrota:** La vida del jugador llega a 0.

## 2. El Escenario (El Búnker)
El combate se desarrolla en un mapa grande con múltiples habitaciones interconectadas:
*   **Centro de Comando (Inicio):** Donde aparece el jugador.
*   **Pasillo Principal:** Conecta todas las áreas.
*   **Armería y Biblioteca:** A la izquierda.
*   **Laboratorio y Comedor:** A la derecha.
*   **Dormitorios y Vestíbulo:** Abajo.

En estas habitaciones hay distribuidos **7 Objetos** (cajas rojas brillantes). Solo **uno** es el verdadero "Objeto Obsesivo". Los otros 6 son señuelos (decoys).

## 3. Mecánicas del Enemigo ("The Stalker")

### Estados y Comportamiento
El Stalker tiene una Inteligencia Artificial de estados:
1.  **Intro/Dormido:** Comienza inactivo o aturdido temporalmente.
2.  **Activo (Persecución):** Persigue al jugador constantemente.
3.  **Carga (Charging):** Se detiene y vibra (color rojo pulsante) preparando un ataque.
4.  **Embestida (Dash):** Se lanza a gran velocidad hacia la última posición conocida del jugador. Si impacta, causa **60 de daño** (muy alto).
5.  **Berserk:** Se activa al destruir el objeto real o todos los señuelos. Se vuelve rojo intenso, muy rápido y agresivo.

### Sistema de Estabilidad (Escudo)
Aunque el Stalker es **INVENCIBLE** (su vida no baja), tiene una barra amarilla de **Estabilidad**.
*   Al recibir daño, su estabilidad baja.
*   Si la estabilidad llega a 0, el Stalker **se duerme** durante 7 segundos.
*   **Estrategia:** Atacar al Stalker para dormirlo y aprovechar ese tiempo para buscar los objetos en las habitaciones sin ser perseguido.

### Reacción a la Destrucción de Objetos
Cada vez que destruyes un objeto (sea real o falso), el Stalker reacciona:
*   **Objetos Falsos:**
    *   Al quedar 5 objetos: Se vuelve más lento (duda).
    *   Al quedar 3 objetos: Entra en pánico (más rápido, pierde escudo).
    *   Al quedar 1 objeto: Colapso (muy agresivo, se cansa rápido).
*   **Objeto Real:**
    *   **¡VULNERABILIDAD ACTIVADA!** El Stalker pierde su invencibilidad.
    *   Entra en modo **Berserk** (furia total).
    *   Ahora sí puedes matarlo atacando directamente a su vida.

## 4. Cómo se Juega (Guía Paso a Paso)

1.  **Inicio:** Apareces en el Centro de Comando. El Stalker aparece en el Vestíbulo (abajo) y empezará a subir hacia ti.
2.  **Búsqueda:** Debes moverte por las habitaciones buscando los objetos rojos brillantes.
3.  **Combate Defensivo:**
    *   Si el Stalker se acerca, dispárale (Dan) o ataca (Mel) para bajar su barra amarilla.
    *   Cuando se duerma ("Zzz"), corre a la siguiente habitación.
    *   **¡Cuidado con la Embestida!** Si lo ves parpadear en rojo y vibrar, muévete lateralmente rápido para esquivar su dash.
4.  **Destrucción:** Ataca los objetos rojos.
    *   Si sale un mensaje de "Solo era un señuelo...", sigue buscando.
    *   Si sale "¡VULNERABILIDAD DETECTADA!", has encontrado el correcto.
5.  **Fase Final:** Una vez destruido el objeto real, el Stalker será vulnerable pero muy peligroso (rojo). Descarga todo tu arsenal sobre él hasta que su barra de vida (roja) se vacíe.

## 5. Controles
*   **Movimiento:** Joystick Virtual (izquierda de la pantalla) o Teclado (WASD/Flechas).
*   **Ataque:** Botón de ataque (Espacio) o automático si tienes armas de fuego (según configuración).
*   **Cambio de Arma (Dan):** Tecla 'Q'.
*   **Interacción:** Botón táctil o Tecla 'E' (para puertas/objetos).
