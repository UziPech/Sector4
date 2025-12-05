import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/interactable_data.dart';

class ForestPainter extends CustomPainter {
  final ui.Image image;
  final List<InteractableData> trees;

  ForestPainter({
    required this.image,
    required this.trees,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final tree in trees) {
      // Destination rect
      final dst = Rect.fromLTWH(
        tree.position.x - tree.size.x / 2,
        tree.position.y - tree.size.y / 2,
        tree.size.x,
        tree.size.y,
      );

      if (tree.sourceRect != null) {
        // Sprite sheet case
        canvas.drawImageRect(
          image,
          tree.sourceRect!,
          dst,
          paint,
        );
      } else {
        // Full image case (single asset)
        final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
        canvas.drawImageRect(
          image,
          src,
          dst,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ForestPainter oldDelegate) {
    // Trees are static, so we only repaint if the list changes (which it shouldn't for static scenery)
    // or if the image changes.
    return oldDelegate.image != image || oldDelegate.trees != trees;
  }
}
