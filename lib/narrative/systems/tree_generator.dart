import 'dart:math';
import 'package:flutter/material.dart';
import '../models/interactable_data.dart';

/// Generador de árboles para el mapa del búnker
class TreeGenerator {
  static List<InteractableData> generateTrees() {
    final List<InteractableData> trees = [];
    final random = Random(42); // Seed fijo para consistencia
    
    // Tamaño del árbol para calcular buffers
    const treeSize = 150.0;
    const buffer = treeSize / 2; // 75px de buffer
    
    // Carretera vertical: X: 900-1100 (con buffer: 825-1175)
    // Carretera horizontal: Y: 700-800 (con buffer: 625-875)
    
    // Cuadrante NOROESTE: 200 árboles (Bosque MUY denso)
    // X: 50 hasta (900 - buffer), Y: 50 hasta (700 - buffer)
    for (int i = 0; i < 200; i++) {
      trees.add(_createTree(
        'tree_nw_$i',
        50 + random.nextDouble() * 700,   // X: 50-750 (evita 825+)
        50 + random.nextDouble() * 500,   // Y: 50-550 (evita 625+)
        random.nextInt(3),
      ));
    }
    
    // Cuadrante NORESTE: 200 árboles
    // X: (1100 + buffer) hasta 1950, Y: 50 hasta (700 - buffer)
    for (int i = 0; i < 200; i++) {
      trees.add(_createTree(
        'tree_ne_$i',
        1200 + random.nextDouble() * 750, // X: 1200-1950 (evita hasta 1175)
        50 + random.nextDouble() * 500,   // Y: 50-550 (evita 625+)
        random.nextInt(3),
      ));
    }
    
    // Cuadrante SUROESTE: 200 árboles
    // X: 50 hasta (900 - buffer), Y: (800 + buffer) hasta 1450
    for (int i = 0; i < 200; i++) {
      trees.add(_createTree(
        'tree_sw_$i',
        50 + random.nextDouble() * 700,   // X: 50-750 (evita 825+)
        900 + random.nextDouble() * 550,  // Y: 900-1450 (evita hasta 875)
        random.nextInt(3),
      ));
    }
    
    // Cuadrante SURESTE: 200 árboles
    // X: (1100 + buffer) hasta 1950, Y: (800 + buffer) hasta 1450
    for (int i = 0; i < 200; i++) {
      trees.add(_createTree(
        'tree_se_$i',
        1200 + random.nextDouble() * 750, // X: 1200-1950 (evita hasta 1175)
        900 + random.nextDouble() * 550,  // Y: 900-1450 (evita hasta 875)
        random.nextInt(3),
      ));
    }
    
    return trees;
  }
  
  static InteractableData _createTree(String id, double x, double y, int variant) {
    return InteractableData(
      id: id,
      name: 'Árbol',
      position: Vector2(x, y),
      size: const Vector2(150, 150), // Reducido a 150x150 para evitar overlap
      type: InteractableType.decoration,
      spritePath: 'assets/sprites/pine_trees.png',
      sourceRect: Rect.fromLTWH(variant * 128.0, 0, 128, 128),
    );
  }
}

