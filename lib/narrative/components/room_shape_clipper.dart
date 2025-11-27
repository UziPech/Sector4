import 'package:flutter/material.dart';

/// Custom clipper para habitaciones con esquinas cortadas
/// Usado para crear formas de habitación más interesantes
class RoomShapeClipper extends CustomClipper<Path> {
  final RoomShape shape;
  
  RoomShapeClipper({required this.shape});
  
  @override
  Path getClip(Size size) {
    final path = Path();
    
    switch (shape) {
      case RoomShape.rectangle:
        // Habitación rectangular normal
        path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
        break;
        
      case RoomShape.cutCorners:
        // Habitación con entrada lateral izquierda (tipo T o L lateral)
        // Dimensiones ajustadas para coincidir con la imagen de referencia
        final hallwayWidth = size.width * 0.25;   // Ancho del pasillo (extensión hacia la izquierda)
        final hallwayHeight = size.height * 0.25; // Altura del pasillo
        final hallwayY = size.height * 0.4;       // Posición Y del pasillo (casi al medio)
        
        // Dibujamos el perímetro: Habitación principal + Pasillo lateral
        // Empezamos en la esquina superior izquierda de la habitación PRINCIPAL
        path.moveTo(hallwayWidth, 0); 
        path.lineTo(size.width, 0); // Top
        path.lineTo(size.width, size.height); // Right
        path.lineTo(hallwayWidth, size.height); // Bottom
        path.lineTo(hallwayWidth, hallwayY + hallwayHeight); // Subir hasta la parte inferior del pasillo
        path.lineTo(0, hallwayY + hallwayHeight); // Izquierda (fondo del pasillo)
        path.lineTo(0, hallwayY); // Subir (ancho del pasillo)
        path.lineTo(hallwayWidth, hallwayY); // Derecha (volver a la pared principal)
        path.close(); // Cerrar (subir hasta el inicio)
        break;
        
      case RoomShape.lShape:
        // Habitación en forma de L
        final cutWidth = size.width * 0.4;
        final cutHeight = size.height * 0.4;
        
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height - cutHeight);
        path.lineTo(size.width - cutWidth, size.height - cutHeight);
        path.lineTo(size.width - cutWidth, size.height);
        path.lineTo(0, size.height);
        path.close();
        break;
        
      case RoomShape.hexagon:
        // Hexágono horizontal (pasillo con 6 lados)
        // Cortes diagonales en las esquinas superior e inferior
        final cornerCut = size.height * 0.15; // 15% de corte en esquinas
        
        path.moveTo(cornerCut, 0); // Inicio: esquina superior izquierda (cortada)
        path.lineTo(size.width - cornerCut, 0); // Línea superior
        path.lineTo(size.width, cornerCut); // Diagonal superior derecha
        path.lineTo(size.width, size.height - cornerCut); // Lado derecho
        path.lineTo(size.width - cornerCut, size.height); // Diagonal inferior derecha
        path.lineTo(cornerCut, size.height); // Línea inferior
        path.lineTo(0, size.height - cornerCut); // Diagonal inferior izquierda
        path.lineTo(0, cornerCut); // Lado izquierdo
        path.close(); // Cerrar con diagonal superior izquierda
        break;
        
      case RoomShape.uShape:
        // Forma de U (sala de estar)
        // Torres izquierda y derecha en la parte superior, con hueco central
        final towerWidth = size.width * 0.17; // 120px de 700px
        final towerHeight = size.height * 0.2; // 120px de 600px
        
        // Empezar en esquina superior izquierda
        path.moveTo(0, 0);
        path.lineTo(towerWidth, 0); // Top de torre izquierda
        path.lineTo(towerWidth, towerHeight); // Bajar torre izquierda
        path.lineTo(size.width - towerWidth, towerHeight); // Cruzar el hueco
        path.lineTo(size.width - towerWidth, 0); // Subir torre derecha
        path.lineTo(size.width, 0); // Top de torre derecha
        path.lineTo(size.width, size.height); // Lado derecho completo
        path.lineTo(0, size.height); // Bottom completo
        path.close(); // Lado izquierdo completo
        break;
    }
    
    return path;
  }
  
  @override
  bool shouldReclip(RoomShapeClipper oldClipper) => oldClipper.shape != shape;
}

/// Tipos de formas de habitación disponibles
enum RoomShape {
  rectangle,    // Rectangular normal
  cutCorners,   // Esquinas cortadas (dormitorio)
  lShape,       // Forma de L
  hexagon,      // Hexágono (pasillo con 6 lados)
  uShape,       // Forma de U (sala de estar)
}
