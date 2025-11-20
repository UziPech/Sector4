# Capítulo: Observatorio / Mapa exterior post-resonante

## 1. Contexto narrativo
1. Después de eliminar al resonante, Mel detecta múltiples focos de mutación a la distancia y transmite que la evacuación debe posponerse unos minutos mientras se despeja la zona.
2. El jugador ya desbloqueó la salida gracias a su última acción, pero todavía debe aguantar y despejar el perímetro exterior del búnker.
3. La escena transcurre en el "Observatorio de la Colmena" (una sala técnica con sintetizadores de luz y equipos japoneses dan la entrada a la plataforma exterior) justo antes de salir al mapa abierto.

## 2. Diseño del mapa exterior
- **Dimensiones en Tiled**: 200 px × 200 px (ajustar la escala según la unidad del motor, pero la malla base debe ocupar ese cuadrado para coincidir con los tiles existentes). 
- **Zonas clave**:
  - Entrada al búnker (punto seguro).
  - Corredores laterales con luz tenue (apariciones de irracionales).
  - Sector central iluminado por humo y drones caídos.
- **Flujo**: el jugador debe moverse hacia la salida natural mientras se enfrentan oleadas leves.

## 3. Enemigos: irracionales ligeros
- Son mutados cuerpo a cuerpo de bajo peligro; atacan al contacto y pueden ser derribados o eliminados.
- Se articularán como cuadrillas pequeñas que aparecen en intervalos/respawn.
- Si no se rematan, pueden quedar aturdidos y, en el caso de Mel, ofrecer la opción de resucitar.

## 4. Flujo de diálogo y selección de rol
- **Intro**: tras el mensaje de Mel, una secuencia de diálogos internos repite la urgencia (Dan reflexiona sobre la responsabilidad; Mel recuerda la evolución de su brazo mutante). Nada de voces, todo texto con el estilo ya usado en el juego.
- **Tarjetas**: enseguida aparecen dos tarjetas rectangulares con texto:
  - **Dan**: "Cuchillo y pistola. Ritmo directo." (listar stats: daño, velocidad).
  - **Mel**: "Mano mutante, regeneración, 2 resurrecciones." (mostrar HP 200, regeneración +2/seg y el contador 0/2 o 2/2 libre).
- La tarjeta activa se resalta con glow; al confirmar se reproduce una animación breve y se oculta el módulo dialogal para pasar al mapa exterior.
- Este flujo debe poder reutilizarse en otros capítulos donde se cambie de héroe o se agreguen cartas de rol.

## 5. Mecánica de tumba para resurrecciones
- Cuando un irracional muere, se materializa una tumba luminosa (base circular con un pequeño holograma). Para Mel, se muestra un prompt emergente:
  - Texto: "Presiona E para revivir" + contador de resurrecciones restantes.
  - El prompt permanece unos segundos antes de disiparse si no se usa.
- El cadáver pasa a estado "tumbar" y no desaparece hasta que se acaba el tiempo o se revive.
- Al revivirlo, el irracional reaparece como aliado temporal (no la misma AI destrabada) y genera distracción para bajar presión mientras el jugador se mueve hacia la salida.
- El sistema lleva un contador global (max 2) que persiste sólo en este capítulo y se muestra en HUD (por ejemplo, pequeños orbes entre el retrato de Mel).

## 6. Roles y mecánicas diferenciadas
### Dan
- Usa armas convencionales: cuchillo y pistola.
- No tiene resurrección ni habilidades especiales.
- Juego más directo: puntería, cobertura y ritmo de combate tradicional.
- Opcional: si se desea, se le puede regalar una ventana de ejecución rápida cuando un irracional es aturdido (prompt para rematar o dejar inconsciente).

### Mel
- Salud total: 200 HP (alta resistencia); regenera lentamente a lo largo del combate, por ejemplo, +2 HP cada 2 segundos o algo balanceado.
- Habilidad pasiva: mano mutante que drena vida al golpear (genera una pequeña cantidad de curación y mantiene presión visual).
- **Resurrección controlada**:
  - Cuando un irracional muere, aparece un prompt en pantalla con la opción contextual de resucitarlo (icono + animación de energía verde).
  - Máximo 2 resurrecciones por capítulo, independiente del tipo. El contador se muestra en el HUD (p. ej. "Revivir: 1/2" o ícono cromático).
  - La acción revive al enemigo aliado convertido en defensor breve, ofreciendo distracción o apoyo para escapar.
- Su estilo combina sigilo/soporte con un leve control de multitudes.

## 5. UI y retroalimentación
- Al derrotar un enemigo, el HUD despliega una ventana pequeña con:
  - Nombre: "Revivir".
  - Coste: 1 de los 2 recurrences, se marca como usado.
  - Temporizador breve que permite decidir (2 s) antes de que el cadáver se disipe.
- El contador de resurrecciones restantes se mantiene visible, quizás junto al retrato de Mel.
- La regeneración de vida puede representarse con partículas verdes en la barra de HP.

## 6. Assets y siguientes pasos
1. Crear layout Tiled 200px × 200px con iluminación y rampas de humo.
2. Diseñar diálogos inmediatos: el mensaje de Mel sobre la evacuación y la sensación de aguantar la zona.
3. Confirmar sprites y animaciones para la mano mutante y el UI de resurrección.
4. Ajustar la salud y regeneración de Mel en el sistema de combate; validar que Dan no recibe la misma mecánica.
5. Planear cómo se ligan estas decisiones a la ruta futura de la historia (¿Dan y Mel se separan o se fusionan?).

Este documento servirá como guía para implementar el capítulo combinado de rol/defensa. Cuando estemos listos podemos dividir tareas en subtareas de código y narrativa.
