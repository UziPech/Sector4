import 'package:flutter/material.dart';

/// Información de un capítulo
class ChapterInfo {
  final int number;
  final String title;
  final String description;
  final Widget Function() sceneBuilder;
  final String? imageAsset; // Opcional: imagen del capítulo
  
  const ChapterInfo({
    required this.number,
    required this.title,
    required this.description,
    required this.sceneBuilder,
    this.imageAsset,
  });
}
