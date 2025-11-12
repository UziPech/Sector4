# Sistema de Login - Expediente Kōrin

## 📋 Plan General
- **Objetivo**: Crear sistema de login para el juego de terror
- **Plataformas**: Gmail/Correo y Facebook
- **Backend**: Supabase (futuro)
- **Autenticación**: No necesaria por ahora
- **Enfoque**: Solo login, sin tocar el resto del proyecto

## 🎯 Fase Actual: Pantalla de Inicio con Efectos

### ✅ Completado
- [x] Imagen de login mejorada en `assets/images/login_screen_new.jpg` (generada con Leonardo AI)
- [x] Configuración de assets en `pubspec.yaml`
- [x] Pantalla de login básica creada
- [x] Integración con main.dart
- [x] **Orientación horizontal forzada** en dispositivos móviles
- [x] **Debug banner eliminado** (cinta amarilla)
- [x] **Diseño responsive** para móviles y tablets
  - Tamaño de fuente adaptativo (32px móvil, 52px desktop)
  - Ancho de botones adaptativo (70% móvil, 300px desktop)
  - Padding adaptativo (20px móvil, 40px desktop)
- [x] Botones visuales de "INICIAR SESIÓN" y "REGISTRARSE"
- [x] Google Fonts agregado (specialElite para título)
- [x] Efecto de viñeta con gradiente radial (oscurece bordes)
- [x] Capa de oscurecimiento semitransparente (0.4 opacity)
- [x] Efecto de lluvia animada con CustomPaint y AnimationController
- [x] **Efecto VHS/TV Glitch** en el título (cada 8s, 25% probabilidad - más ocasional)
  - Separación de canales RGB (rojo y cyan)
  - Desplazamiento horizontal aleatorio
  - Opacidad variable
  - **Cambio de color dinámico** (6 tonos de rojo/sangre)
  - Sombra y glow que cambian con el color
  - Duración aleatoria (100-300ms)
  - Efecto de TV/grabación fallando terrorífico
  - Sincronizado con sonido de glitch
- [x] Botones mejorados con sombras rojas y efectos hover
- [x] Stack con 5 capas: Imagen → Viñeta → Lluvia → Oscurecimiento → Contenido
- [x] **Efecto de sangre derritiéndose** del título (CustomPaint con gradientes)
  - Manchas de sangre sobre cada letra del título (13 letras)
  - 20 gotas de sangre animadas cayendo desde las letras
  - Gradiente realista: rojo muy oscuro → rojo oscuro → crimson → rojo brillante
  - Animación de crecimiento y caída con velocidades variables
  - Gotas con forma orgánica e irregular usando Path y Bezier curves
  - Ancho variable que aumenta con la longitud
  - Gotas acumuladas en las puntas (efecto de tensión superficial)
  - Posicionadas correctamente dentro del ancho del título (no sobrepasan)
  - Layout alineado a la izquierda (título, botones, versión)

### 🔄 Completado - Audio
- [x] **Sistema de audio implementado** con `audioplayers`
- [x] Música de fondo en loop (login_ambient.mp3, 20% volumen)
  - Se inicia automáticamente al cargar la pantalla
  - **Pausado automático** cuando la app va a segundo plano
  - **Reanudado automático** cuando la app vuelve al frente
  - **Controlado por botones de volumen** del dispositivo (Android/iOS)
- [x] Efecto glitch sincronizado con visual (35% volumen, cada 8s con 25% probabilidad)
- [x] Efecto hover en botones "ghostly whoosh" (24% volumen)
- [x] Efecto click en botones "bone crack" (40% volumen)
- [x] AudioService singleton para gestionar todos los sonidos
- [x] Frecuencia de glitch ajustada (más ocasional) para no interferir con música de fondo
- [x] Gestión del ciclo de vida de la app (WidgetsBindingObserver)

## 🎯 Próximos Pasos
- [ ] Implementar funcionalidad real de login con AuthService
- [ ] Agregar validación de campos
- [ ] Conectar con Supabase (futuro)
- [ ] **Agregar efectos de sonido y música de fondo**
  - Estructura de carpetas creada: `assets/audio/music/` y `assets/audio/sfx/`
  - Ver `assets/audio/README.md` para lista de archivos necesarios
  - Buscar sonidos en Pixabay, Freesound, Zapsplat, etc. terrorífico
- Gradientes oscuros con transiciones
- Efectos de niebla/vapor
- Texto tembloroso para títulos

## 🎮 Efectos Visuales Planeados
- Animación de entrada suave
- Efectos de parpadeo terrorífico
- Gradientes oscuros con transiciones
- Efectos de niebla/vapor
- Texto tembloroso para títulos

## 🔊 Efectos de Sonido (Pendiente)
- **Sugerencias de páginas**:
  - Freesound.org
  - Zapsplat.com
  - Mixkit.co
- **Búsquedas recomendadas**:
  - "horror ambient"
  - "dark atmosphere"
  - "creepy background"
  - "terror game menu"
  - "horror UI sounds"

## 📝 Notas de Desarrollo
- Mantener separado del juego principal
- Enfocarse en experiencia de usuario
- Estética terror/noir consistente
