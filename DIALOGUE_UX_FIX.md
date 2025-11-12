# Fix: UX del Sistema de Diálogos

## Problema Reportado
Los diálogos avanzaban demasiado rápido al hacer clic, impidiendo leer el texto completo.

## Causas Identificadas
1. **Velocidad de typewriter muy alta**: 30 caracteres/segundo era demasiado rápido
2. **Sin protección contra clics accidentales**: Se podía hacer clic inmediatamente al aparecer
3. **Indicador poco claro**: Solo mostraba "▼" cuando estaba listo para avanzar

## Soluciones Implementadas

### 1. Velocidad de Typewriter Reducida
```dart
// Antes
this.typewriterSpeed = 30.0

// Ahora
this.typewriterSpeed = 20.0
```
- **Impacto**: Texto más legible, da tiempo para leer mientras aparece
- **Duración ejemplo**: Diálogo de 100 caracteres = 5 segundos (antes 3.3s)

### 2. Delay Anti-Clic Accidental
```dart
bool _canInteract = false;

@override
void initState() {
  super.initState();
  _startTypewriter();
  // Permitir interacción después de 300ms
  Future.delayed(const Duration(milliseconds: 300), () {
    if (mounted) {
      setState(() {
        _canInteract = true;
      });
    }
  });
}

void _handleTap() {
  if (!_canInteract) return; // Ignorar clics tempranos
  // ... resto de la lógica
}
```
- **Impacto**: Previene avanzar accidentalmente al aparecer el diálogo
- **Duración**: 300ms de gracia antes de permitir clics

### 3. Indicador Visual Mejorado
```dart
// Antes
Text('▼', ...)

// Ahora
Row(
  children: [
    Text('Click para continuar', ...),
    SizedBox(width: 8),
    Text('▼', ...),
  ],
)
```
- **Color**: Amarillo (más visible que blanco)
- **Texto explícito**: "Click para continuar"
- **Posición**: Alineado a la derecha, debajo del texto

## Comportamiento Actualizado

### Flujo de Interacción
1. **Diálogo aparece** → Texto comienza a escribirse
2. **Primeros 300ms** → Clics ignorados (protección)
3. **Durante typewriter** → 
   - Primer clic: Completa el texto inmediatamente
   - Indicador "Click para continuar" aparece
4. **Texto completo** → 
   - Segundo clic: Avanza al siguiente diálogo
   - Indicador visible en amarillo

### Ejemplo con Diálogo Largo
```
Texto: "El silencio. Es más ensordecedor que cualquier explosión..."
Longitud: ~70 caracteres
Duración typewriter: 3.5 segundos

Timeline:
0.0s  - Diálogo aparece
0.0s  - Clics ignorados
0.3s  - Clics permitidos (pero solo completan texto)
3.5s  - Texto completo, indicador aparece
3.5s+ - Clic avanza al siguiente diálogo
```

## Configuración Ajustable

### Velocidad de Typewriter
Editar en `dialogue_box.dart`:
```dart
this.typewriterSpeed = 20.0  // Caracteres por segundo
```
- **Más lento**: 10-15 (muy narrativo)
- **Normal**: 20-25 (actual)
- **Rápido**: 30-40 (para jugadores impacientes)

### Delay Anti-Clic
Editar en `dialogue_box.dart`:
```dart
Future.delayed(const Duration(milliseconds: 300), ...)
```
- **Más corto**: 200ms (menos protección)
- **Normal**: 300ms (actual)
- **Más largo**: 500ms (más protección)

## Testing

### Checklist
- [x] Typewriter más lento (20 chars/s)
- [x] Delay de 300ms antes de permitir clics
- [x] Indicador "Click para continuar" visible
- [x] Primer clic completa texto
- [x] Segundo clic avanza diálogo

### Casos de Prueba

#### Caso 1: Diálogo Corto (< 50 chars)
```
Texto: "Sarah..."
Esperado: 
- Typewriter: ~2.5s
- Indicador aparece rápido
- Fácil de leer completo
```

#### Caso 2: Diálogo Medio (50-100 chars)
```
Texto: "Tres años. Tres años desde que el cáncer te arrebató..."
Esperado:
- Typewriter: ~4-5s
- Tiempo suficiente para leer
- Indicador claro al terminar
```

#### Caso 3: Diálogo Largo (> 100 chars)
```
Texto: "El duelo me convirtió en un desecho, un Yūrei sin misión..."
Esperado:
- Typewriter: ~6-7s
- Posible clic para completar antes
- Indicador visible después
```

#### Caso 4: Clic Accidental
```
Acción: Clic inmediato al aparecer diálogo
Esperado: Ignorado (primeros 300ms)
```

#### Caso 5: Clic Durante Typewriter
```
Acción: Clic mientras texto se escribe
Esperado: 
- Texto completa inmediatamente
- Indicador aparece
- Requiere segundo clic para avanzar
```

## Mejoras Futuras

### Corto Plazo
- [ ] Sonido de typewriter (opcional, configurable)
- [ ] Animación del indicador "▼" (bounce)
- [ ] Opción de auto-avance para diálogos cortos

### Medio Plazo
- [ ] Configuración de velocidad en opciones
- [ ] Modo "lectura rápida" (saltar typewriter)
- [ ] Historial de diálogos (backlog)

### Largo Plazo
- [ ] Voces sintéticas (text-to-speech)
- [ ] Animación de labios en avatares
- [ ] Efectos de pantalla según emoción

## Notas de Diseño

### Filosofía UX
- **Respeto al jugador**: Dar tiempo suficiente para leer
- **Claridad**: Indicadores explícitos de cuándo avanzar
- **Protección**: Prevenir errores accidentales
- **Flexibilidad**: Permitir acelerar si se desea

### Accesibilidad
- Texto grande (18px)
- Alto contraste (blanco sobre negro)
- Indicadores visuales claros
- Sin dependencia de color únicamente

### Performance
- Animaciones ligeras (solo texto)
- Sin lag en typewriter
- Dispose correcto de controllers

---

**Versión:** 1.1
**Fecha:** Noviembre 2025
**Archivo:** `lib/narrative/components/dialogue_box.dart`
