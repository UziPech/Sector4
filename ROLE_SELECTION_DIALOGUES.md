# Diálogos: Selección de Rol Post-Resonante

## Contexto
Después de derrotar al resonante en el búnker, Mel detecta nuevas amenazas en el perímetro exterior. Dan y Mel deben decidir quién tomará el liderazgo en la evacuación.

---

## Secuencia 1: Post-Victoria (Diálogo automático)

### Diálogo 1
**Tipo**: `DialogueType.system`  
**Speaker**: Sistema  
**Texto**: "AMENAZA NEUTRALIZADA. Resonante eliminado. Escaneando perímetro..."

### Diálogo 2
**Tipo**: `DialogueType.normal`  
**Speaker**: Mel  
**Avatar**: `assets/avatars/mel.png`  
**Texto**: "Dan, espera. Los sensores están detectando múltiples firmas biológicas anómalas. No estamos solos."

### Diálogo 3
**Tipo**: `DialogueType.internal`  
**Speaker**: Dan  
**Texto**: "Por supuesto. Nunca es solo uno. La Caída no funciona así. Es como una infección... se propaga."

### Diálogo 4
**Tipo**: `DialogueType.normal`  
**Speaker**: Mel  
**Avatar**: `assets/avatars/mel.png`  
**Texto**: "Son irracionales. Mutados de bajo nivel, pero en número. Necesitamos aguantar mientras preparo la ruta de evacuación."

### Diálogo 5
**Tipo**: `DialogueType.internal`  
**Speaker**: Dan  
**Texto**: "Aguantar. Siempre aguantar. Como si mi vida entera no hubiera sido eso... aguantar hasta que algo se rompa."

### Diálogo 6
**Tipo**: `DialogueType.normal`  
**Speaker**: Mel  
**Avatar**: `assets/avatars/mel.png`  
**Texto**: "Dan, escúchame. Podemos hacer esto de dos formas."

### Diálogo 7
**Tipo**: `DialogueType.normal`  
**Speaker**: Mel  
**Avatar**: `assets/avatars/mel.png`  
**Texto**: "Tú puedes liderar con tus armas, tu entrenamiento. O... yo puedo usar esto."

### Diálogo 8
**Tipo**: `DialogueType.internal`  
**Speaker**: Dan  
**Texto**: "Su brazo. Esa cosa que crece en ella. Parte orgánica, parte... otra cosa. La Caída la marcó, pero no la destruyó."

### Diálogo 9
**Tipo**: `DialogueType.normal`  
**Speaker**: Mel  
**Avatar**: `assets/avatars/mel.png`  
**Texto**: "He estado aprendiendo a controlarlo. Puedo absorber energía vital, incluso... traer de vuelta a los caídos. Temporalmente."

### Diálogo 10
**Tipo**: `DialogueType.internal`  
**Speaker**: Dan  
**Texto**: "Resurrección. Qué ironía. Yo que no pude salvar a nadie, y ella puede devolver la vida. Aunque sea por un momento."

### Diálogo 11
**Tipo**: `DialogueType.normal`  
**Speaker**: Mel  
**Avatar**: `assets/avatars/mel.png`  
**Texto**: "La decisión es tuya, Dan. ¿Quién toma el punto?"

---

## Secuencia 2: Tarjetas de Selección (UI estática, no diálogo)

### Tarjeta: Dan
**Título**: DAN - OPERADOR TÁCTICO  
**Descripción corta**: "Entrenamiento militar. Armas convencionales. Sin margen de error."

**Stats**:
- HP: 100
- Velocidad: 200
- Armas: Cuchillo del Diente Caótico, Pistola Estándar
- Habilidades: Ninguna

**Texto narrativo**:
"El peso del metal. El olor de la pólvora. Esto es lo que conozco. Esto es lo que soy. Un soldado sin guerra, un fantasma con un propósito."

---

### Tarjeta: Mel
**Título**: MEL - PORTADORA DE LA CAÍDA  
**Descripción corta**: "Mutación controlada. Regeneración. Dominio sobre la vida y la muerte."

**Stats**:
- HP: 200
- Regeneración: +2 HP cada 2 segundos
- Arma: Mano Mutante (drenaje de vida)
- Habilidades: Resurrección (máx. 2)

**Texto narrativo**:
"Siento el pulso de la Caída en mis venas. No es una maldición. Es una herramienta. Y voy a usarla para proteger lo que queda."

---

## Secuencia 3: Post-Selección (Diálogo breve)

### Si se elige a Dan:

#### Diálogo 1
**Tipo**: `DialogueType.internal`  
**Speaker**: Dan  
**Texto**: "Viejo y confiable. Las armas nunca me han fallado. Bueno... casi nunca."

#### Diálogo 2
**Tipo**: `DialogueType.normal`  
**Speaker**: Mel  
**Avatar**: `assets/avatars/mel.png`  
**Texto**: "Te cubro desde atrás. No dejes que te rodeen."

---

### Si se elige a Mel:

#### Diálogo 1
**Tipo**: `DialogueType.normal`  
**Speaker**: Mel  
**Avatar**: `assets/avatars/mel.png`  
**Texto**: "Está bien. Puedo hacer esto. Siento cada latido, cada movimiento. Estoy lista."

#### Diálogo 2
**Tipo**: `DialogueType.internal`  
**Speaker**: Dan  
**Texto**: "Ella es más fuerte de lo que cree. Más fuerte de lo que yo jamás fui. Quizás la Caída eligió a la persona correcta."

---

## Secuencia 4: Inicio del combate (Mapa exterior)

### Diálogo 1
**Tipo**: `DialogueType.system`  
**Speaker**: Sistema  
**Texto**: "ALERTA: Múltiples contactos hostiles detectados. Distancia: 50 metros y acercándose."

### Diálogo 2 (Si Dan)
**Tipo**: `DialogueType.internal`  
**Speaker**: Dan  
**Texto**: "Aquí vienen. Mantén la calma. Respira. Apunta. Dispara."

### Diálogo 2 (Si Mel)
**Tipo**: `DialogueType.internal`  
**Speaker**: Mel  
**Texto**: "Puedo sentirlos. Sus mentes rotas, sus cuerpos retorcidos. No son enemigos... son víctimas. Pero debo sobrevivir."

---

## Notas de implementación

### Timing de diálogos:
1. **Secuencia 1** se activa inmediatamente después de derrotar al resonante en `BunkerBossLevel`.
2. Al terminar Secuencia 1, se muestra la pantalla de selección de rol (tarjetas).
3. **Secuencia 3** se activa después de confirmar la selección.
4. **Secuencia 4** se activa al cargar el mapa exterior.

### Uso de avatares:
- Dan: `assets/avatars/dan.png` y `assets/avatars/dialogue_body/dan_dialogue_complete.png`
- Mel: `assets/avatars/mel.png` y `assets/avatars/dialogue_body/mel_dialogue_complete.png`
- Sistema: Sin avatar (solo texto con estilo especial)

### Estilo visual:
- Diálogos internos en cursiva, sin avatar.
- Diálogos de sistema con fondo rojo/amarillo y tipografía monospace.
- Diálogos normales con avatar grande a la derecha.

### Skipeable:
- Todos los diálogos pueden ser skipeados con el botón "SALTAR" excepto los mensajes de sistema que pueden tener `autoAdvanceDelay` de 2 segundos.

---

## Código de ejemplo para activar diálogos

```dart
// En BunkerBossLevel, después de derrotar al jefe:
void _onBossDefeated() {
  DialogueOverlay.show(
    context,
    DialogueSequence(
      id: 'post_resonante',
      dialogues: const [
        DialogueData(
          speakerName: 'Sistema',
          text: 'AMENAZA NEUTRALIZADA. Resonante eliminado. Escaneando perímetro...',
          type: DialogueType.system,
        ),
        DialogueData(
          speakerName: 'Mel',
          text: 'Dan, espera. Los sensores están detectando múltiples firmas biológicas anómalas. No estamos solos.',
          avatarPath: 'assets/avatars/mel.png',
          type: DialogueType.normal,
        ),
        // ... resto de diálogos
      ],
      onComplete: () {
        // Navegar a pantalla de selección de rol
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const RoleSelectionScreen(),
          ),
        );
      },
    ),
  );
}
```

---

Este documento contiene todos los textos necesarios para implementar la narrativa de la selección de rol. Los diálogos mantienen el tono introspectivo de Dan y el crecimiento de Mel como personaje.
