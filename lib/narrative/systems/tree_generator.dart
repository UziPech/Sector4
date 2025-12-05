import 'dart:math';
import 'package:flutter/material.dart';
import '../models/interactable_data.dart';

/// Generador de árboles para el mapa del búnker
class TreeGenerator {
  static List<InteractableData> generateTrees() {
    final List<InteractableData> trees = [];
    final random = Random(42);
    
    // Configuración de distribución
    const double minDistance = 80.0; // Distancia mínima para que no se encimen demasiado
    const int maxAttempts = 2000; // Límite de intentos para evitar bucles infinitos
    const int targetTreeCount = 200; // Cantidad objetivo (ajustada para el espacio disponible)
    
    int attempts = 0;
    
    while (trees.length < targetTreeCount && attempts < maxAttempts) {
      attempts++;
      
      final x = random.nextDouble() * 2000;
      final y = random.nextDouble() * 600; // Solo zona superior
      
      // === EXCLUSIONES ===
      
      // 1. CARRETERA VERTICAL CENTRAL (Ampliada)
      // X: 800-1200 para dar buen margen a la carretera de 900-1100
      if (x > 800 && x < 1200) continue;
      
      // 2. Carretera Vertical Derecha
      if (x > 1800) continue;

      // 3. Camino curvo / Límite inferior
      if (y > 550) continue;

      // === VERIFICAR DISTANCIA (Evitar superposición fea) ===
      bool tooClose = false;
      final newPos = Vector2(x, y);
      
      for (final tree in trees) {
        if (tree.position.distanceTo(newPos) < minDistance) {
          tooClose = true;
          break;
        }
      }
      
      if (tooClose) continue;

      // Agregar árbol válido
      trees.add(InteractableData(
        id: 'forest_tree_${trees.length}',
        name: 'Árbol Realista',
        position: newPos,
        size: const Vector2(100, 100),
        type: InteractableType.decoration,
        spritePath: 'assets/sprites/realistic_pine_tree.png',
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
      spritePath: 'assets/sprites/realistic_pine_tree.png',
      // sourceRect: null, // Usar imagen completa (ya no es sprite sheet)
    );
  }
}

