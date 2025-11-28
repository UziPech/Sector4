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
      if (tree.sourceRect != null) {
        // Destination rect based on tree position and size
        // Position is center-based in the data, but drawImageRect uses top-left usually, 
        // let's check how InteractableObject renders.
        // InteractableObject uses Positioned: left: pos.x - size.x/2, top: pos.y - size.y/2
        
        final dst = Rect.fromLTWH(
          tree.position.x - tree.size.x / 2,
          tree.position.y - tree.size.y / 2,
          tree.size.x,
          tree.size.y,
        );

        canvas.drawImageRect(
          image,
          tree.sourceRect!,
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
