# Expediente Kōrin

Juego narrativo de acción top-down desarrollado con Flutter + Flame.

## 🎮 Controles

### Durante exploración (Casa de Dan):
- **WASD / Flechas**: Mover a Dan
- **E**: Interactuar con objetos
- **ESC**: Saltar diálogo actual

### Durante combate:
- **WASD / Flechas**: Mover
- **Espacio / Click**: Disparar
- **E**: Habilidad de Mel (curación)

## 🚀 Ejecutar el proyecto

```bash
flutter pub get
flutter run -d chrome
```

## 📁 Estructura del proyecto

- `lib/narrative/` - Sistema narrativo (diálogos, escenas, habitaciones)
- `lib/game/` - Motor de combate Flame (jugador, Mel, enemigos, mapas)
- `assets/tiles/capitulo_X/` - Mapas Tiled por capítulo
- `assets/avatars/` - Avatares para diálogos

## 📖 Documentación

- **`CURRENT_STATE.md`** - Estado actual del proyecto
- **`REFACTOR_SUMMARY.md`** - Arquitectura técnica
- **`DIALOGOS_CAPITULOS_1_2.md`** - Narrativa completa
- **`LORE_Y_CONTEXTO.md`** - Historia y lore del juego
- **`ROOM_SYSTEM_IMPLEMENTATION.md`** - Sistema de habitaciones
- **`SKIP_DIALOGUE_IMPLEMENTATION.md`** - Sistema de skip

## ✨ Características implementadas

✅ Sistema de habitaciones con transiciones  
✅ Skip de diálogos con ESC  
✅ Exploración narrativa (Casa de Dan)  
✅ Sistema de combate con Flame  
✅ Mel como companion con habilidades  
✅ HUD dinámico  

## 🎯 Próximos pasos

- Implementar interacción con el teléfono
- Crear enemigos (Resonantes, Kijin)
- Mapas Tiled para cada capítulo
- Sistema de armas e inventario
