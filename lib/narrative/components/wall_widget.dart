import 'dart:ui' as ui;
import 'package:flutter/material.dart';

enum WallSide { top, bottom, left, right }

class WallWidget extends StatelessWidget {
  final double width;
  final double height;
  final WallSide side;
  final ui.Image? image;

  const WallWidget({
    Key? key,
    required this.width,
    required this.height,
    required this.side,
    this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (image == null) return Container(); // O mostrar un placeholder

    return CustomPaint(
      size: Size(width, height),
      painter: WallPainter(
        image: image!,
        side: side,
      ),
    );
  }
}

class WallPainter extends CustomPainter {
  final ui.Image image;
  final WallSide side;

  WallPainter({required this.image, required this.side});

  @override
  void paint(Canvas canvas, Size size) {
    final imgWidth = image.width.toDouble();
    final imgHeight = image.height.toDouble();

    Rect srcRect;

    // Definir el recorte (slice) según el lado de la pared
    // Asumimos que el grosor visual de la pared en la textura es igual al grosor físico (100px)
    // Replicando la lógica de Wall.render en BunkerBossLevel
    switch (side) {
      case WallSide.top:
        // Barra superior de la textura horizontal
        srcRect = Rect.fromLTWH(0, 0, imgWidth, size.height);
        break;
      case WallSide.bottom:
        // Barra inferior de la textura horizontal
        srcRect = Rect.fromLTWH(0, imgHeight - size.height, imgWidth, size.height);
        break;
      case WallSide.left:
        // Barra izquierda de la textura vertical
        srcRect = Rect.fromLTWH(0, 0, size.width, imgHeight);
        break;
      case WallSide.right:
        // Barra derecha de la textura vertical
        srcRect = Rect.fromLTWH(imgWidth - size.width, 0, size.width, imgHeight);
        break;
    }

    // Renderizar el recorte repetido a lo largo de la pared
    if (side == WallSide.top || side == WallSide.bottom) {
      // Horizontal: Repetir en X
      for (double x = 0; x < size.width; x += imgWidth) {
        final w = (x + imgWidth > size.width) ? size.width - x : imgWidth;

        canvas.drawImageRect(
          image,
          Rect.fromLTWH(srcRect.left, srcRect.top, w, srcRect.height),
          Rect.fromLTWH(x, 0, w, size.height),
          Paint(),
        );
      }
    } else {
      // Vertical: Repetir en Y
      for (double y = 0; y < size.height; y += imgHeight) {
        final h = (y + imgHeight > size.height) ? size.height - y : imgHeight;

        canvas.drawImageRect(
          image,
          Rect.fromLTWH(srcRect.left, srcRect.top, srcRect.width, h),
          Rect.fromLTWH(0, y, size.width, h),
          Paint(),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant WallPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.side != side;
  }
}
