# Capítulo 2: La Semilla y el Sector 4 - Implementación

## Resumen

**Ubicación**: Búnker subterráneo, Osaka, Japón  
**Personajes**: Dan Keller, Mel  
**Objetivo**: Presentar a Mel y establecer la dinámica de Sector 4

## Estructura Implementada

### Archivo Principal
`lib/narrative/screens/bunker_scene.dart`

### Flujo de la Escena

1. **Monólogo de Tránsito** (8 diálogos)
   - Dan reflexiona sobre su misión
   - Establece su estado mental
   - Introduce a Mel como "Soporte Vital"
   - Autosave al completar

2. **Encuentro con Mel** (28 diálogos)
   - Presentación de Mel
   - Explicación de su rol como "ancla"
   - Mecánica de soporte vital y cooldown
   - Protocolo de inserción
   - Mención de Resonantes (Sector 3)
   - Autosave al completar

3. **Transición a Combate**
   - Delay de 2 segundos
   - Navegación al juego de combate

## Diálogos Implementados

### Monólogo de Tránsito (Dan - Interno)

```dart
1. "Marcus me lanzó a esto como un misil teledirigido."
2. "La universidad de Emma. Epicentro. Amenazas de Sector 4."
3. "Si esta jerarquía me da la excusa para cruzar la zona de exclusión, la acepto."
4. "Mi Caída ya no es mental; es literal. Un descenso a la podredumbre."
5. "Necesito ver a Mel. 'Soporte Vital'. Suena a kit de primeros auxilios con pulso."
6. "No hay espacio para sentimentalismos. Es mi seguro contra la corrupción."
7. "La misión es simple: infiltración, extracción, exfiltración."
8. "El resto es ruido."
```

### Encuentro con Mel (28 diálogos)

**Fase 1 - Presentación** (3 diálogos)
- Dan se presenta
- Mel lo identifica como "padre desesperado"
- Establece tono profesional

**Fase 2 - Explicación de Rol** (9 diálogos)
- Mel como "ancla"
- Diferencia entre Sector 2 y Sector 4
- Kijin como cazadores tácticos
- Capacidad de "reafirmar a la vida"

**Fase 3 - Mecánica de Recurso** (6 diálogos)
- Cooldown/recarga
- Consecuencias de mal uso
- Gestión de recursos

**Fase 4 - Protocolo de Inserción** (10 diálogos)
- Túneles de mantenimiento
- Evitar Resonantes de Sector 3
- Prioridad: Emma
- Apertura del Expediente Kōrin

## Características Visuales

### Layout del Búnker
- Fondo oscuro con gradiente (gris oscuro a negro)
- Sala principal dibujada con líneas
- Pasillo superior
- Etiqueta "SALA DE EQUIPOS"

### Personajes
- **Dan**: Círculo azul con icono de persona
- **Mel**: Círculo verde con icono de persona
  - Borde amarillo cuando es interactuable
  - Prompt "Click para hablar"

### HUD
- **Superior Izquierda**: 
  - Título del capítulo
  - Objetivo actual
- **Superior Derecha**:
  - Ubicación (Búnker, Osaka)

## Estados del Capítulo

1. **Inicial**: Monólogo en curso
2. **Post-Monólogo**: Esperando interacción con Mel
3. **Diálogo con Mel**: En conversación
4. **Completado**: Preparando transición

## Navegación

### Desde el Menú Principal
- Botón "CAPÍTULO 2 (DEBUG)" para acceso directo
- Útil para testing sin jugar Capítulo 1

### Transición
- Al completar: navega a `MyApp` (juego de combate)
- Delay de 2 segundos para absorber el último diálogo

## Puntos de Autosave (Futuros)

1. **Checkpoint 1**: Fin del monólogo de tránsito
2. **Checkpoint 2**: Fin del encuentro con Mel
3. **Checkpoint 3**: Antes de la transición a combate

## Conceptos Narrativos Introducidos

### Sector 4
- Cúspide de la jerarquía
- Enfrenta Amenazas de Sector 4 (Kijin)
- Requiere soporte vital constante

### Mel como Soporte Vital
- "Ancla" que reafirma la conexión a la vida
- Recurso limitado con cooldown
- Crítica para la supervivencia

### Kijin
- Cazadores tácticos
- Inteligencia humana
- Corrompidos por ira y odio
- Flanquean y priorizan objetivos

### Resonantes (Sector 3)
- "Rompecabezas"
- Obsesivos
- No son objetivo de Sector 4
- Se evitan en esta misión

### Expediente Kōrin
- Nombre oficial de la operación
- Abierto al iniciar la inserción

## Mejoras Futuras

### Corto Plazo
- [ ] Añadir avatares de Mel (mel.png)
- [ ] Mejorar visualización del búnker
- [ ] Añadir efectos de sonido ambiente
- [ ] Implementar autosave real

### Medio Plazo
- [ ] Animaciones de entrada de personajes
- [ ] Efectos de iluminación del búnker
- [ ] Música de fondo tensa
- [ ] Sistema de backlog de diálogos

### Largo Plazo
- [ ] Escena 3D del búnker
- [ ] Animaciones faciales de Mel
- [ ] Voces sintéticas
- [ ] Cinemáticas pre-renderizadas

## Testing

### Checklist
- [x] Monólogo de tránsito se muestra al entrar
- [x] Mel es interactuable después del monólogo
- [x] Diálogo con Mel tiene 28 líneas
- [x] Transición a combate funciona
- [x] HUD muestra información correcta
- [x] Navegación desde menú funciona

### Casos de Prueba

#### Caso 1: Flujo Completo
```
1. Menú → Capítulo 2
2. Esperar monólogo (8 diálogos)
3. Click en Mel
4. Leer diálogo completo (28 diálogos)
5. Transición automática a combate
```

#### Caso 2: Navegación Rápida
```
1. Menú → Capítulo 2
2. Skip monólogo (si se implementa)
3. Click en Mel
4. Leer diálogo
5. Verificar transición
```

## Notas de Diseño

### Tono
- Profesional y frío
- Mel es distante pero competente
- Dan es pragmático, enfocado en la misión

### Ritmo
- Monólogo: ~2 minutos
- Encuentro con Mel: ~5-6 minutos
- Total: ~7-8 minutos

### Conexión con Capítulo 1
- Referencia a la llamada de Marcus
- Continuación directa de la decisión de Dan
- Emma como motivación central

### Preparación para Combate
- Establece mecánicas (soporte vital, cooldown)
- Introduce enemigos (Kijin, Resonantes)
- Define objetivo (universidad, Emma)

---

**Versión**: 1.0  
**Fecha**: Noviembre 2025  
**Archivo**: `lib/narrative/screens/bunker_scene.dart`  
**Estado**: Implementado y funcional
