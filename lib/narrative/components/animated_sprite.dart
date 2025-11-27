import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Componente para renderizar sprites animados desde un sprite sheet
/// Soporta 8 direcciones de movimiento con múltiples frames de animación
class AnimatedSprite {
  final ui.Image spriteSheet;
  final double frameWidth;
  final double frameHeight;
  final int columns;
  final int rows;
  
  AnimatedSprite({
    required this.spriteSheet,
    required this.frameWidth,
    required this.frameHeight,
    this.columns = 3,
    this.rows = 3,
  });
  
  /// Carga el sprite sheet desde assets
  static Future<AnimatedSprite> load(String assetPath, {int columns = 3, int rows = 3}) async {
    final ByteData data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    
    final frameWidth = frame.image.width / columns;
    final frameHeight = frame.image.height / rows;
    
    // Debug: imprimir dimensiones
    print('=== SPRITE SHEET DEBUG ===');
    print('Asset: $assetPath');
    print('Image size: ${frame.image.width}x${frame.image.height}');
    print('Grid: ${columns}x${rows}');
    print('Frame size: ${frameWidth}x${frameHeight}');
    
    return AnimatedSprite(
      spriteSheet: frame.image,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
      columns: columns,
      rows: rows,
    );
  }
  
  /// Calcula la dirección basada en el vector de velocidad
  static String calculateDirection(double vx, double vy) {
    if (vx == 0 && vy == 0) return 'SOUTH'; // Idle por defecto
    
    // Normalizar para obtener ángulo
    final angle = (atan2(vy, vx) * 180 / pi + 360) % 360;
    
    // Mapear ángulo a dirección (8 direcciones, 45° cada una)
    if (angle >= 337.5 || angle < 22.5) return 'EAST';
    if (angle >= 22.5 && angle < 67.5) return 'SOUTH-EAST';
    if (angle >= 67.5 && angle < 112.5) return 'SOUTH';
    if (angle >= 112.5 && angle < 157.5) return 'SOUTH-WEST';
    if (angle >= 157.5 && angle < 202.5) return 'WEST';
    if (angle >= 202.5 && angle < 247.5) return 'NORTH-WEST';
    if (angle >= 247.5 && angle < 292.5) return 'NORTH';
    return 'NORTH-EAST'; // 292.5 - 337.5
  }
  
  /// Obtiene el rectángulo del frame actual
  Rect getFrameRect(String direction, int frameIndex) {
    // Calcular fila y columna basado en el índice lineal y el número de columnas
    final row = frameIndex ~/ columns; 
    final col = frameIndex % columns;
    
    return Rect.fromLTWH(
      col * frameWidth,
      row * frameHeight,
      frameWidth,
      frameHeight,
    );
  }
}

/// Painter para dibujar un frame específico del sprite sheet
class SpriteSheetPainter extends CustomPainter {
  final AnimatedSprite sprite;
  final String direction;
  final int frameIndex;
  
  SpriteSheetPainter({
    required this.sprite,
    required this.direction,
    required this.frameIndex,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final srcRect = sprite.getFrameRect(direction, frameIndex);
    final dstRect = Offset.zero & size;
    
    canvas.drawImageRect(
      sprite.spriteSheet,
      srcRect,
      dstRect,
      Paint()..filterQuality = FilterQuality.none, // Pixel art sin suavizado
    );
  }
  
  @override
  bool shouldRepaint(SpriteSheetPainter oldDelegate) {
    return oldDelegate.direction != direction || 
           oldDelegate.frameIndex != frameIndex;
  }
}

/// Widget que muestra un sprite animado
class AnimatedSpriteWidget extends StatelessWidget {
  final AnimatedSprite sprite;
  final String direction;
  final int frameIndex;
  final double size;
  
  const AnimatedSpriteWidget({
    Key? key,
    required this.sprite,
    required this.direction,
    required this.frameIndex,
    required this.size,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: SpriteSheetPainter(
          sprite: sprite,
          direction: direction,
          frameIndex: frameIndex,
        ),
      ),
    );
  }
}
