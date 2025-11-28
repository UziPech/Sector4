import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Widget para renderizar un árbol animado con hojas cayendo
class AnimatedTree extends StatefulWidget {
  final String spritePath;
  final double width;
  final double height;
  
  const AnimatedTree({
    Key? key,
    required this.spritePath,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  State<AnimatedTree> createState() => _AnimatedTreeState();
}

class _AnimatedTreeState extends State<AnimatedTree> {
  int _currentFrame = 0;
  Timer? _animationTimer;
  
  static const int _totalFrames = 4;
  static const double _frameDuration = 0.4; // 400ms por frame = 2.5 FPS
  
  @override
  void initState() {
    super.initState();
    // Animación deshabilitada temporalmente - mostrar solo frame 0
    // TODO: Habilitar cuando tengamos sprite sheet con árbol estático y hojas cayendo
    /*
    _animationTimer = Timer.periodic(
      Duration(milliseconds: (_frameDuration * 1000).toInt()),
      (timer) {
        if (mounted) {
          setState(() {
            _currentFrame = (_currentFrame + 1) % _totalFrames;
          });
        }
      },
    );
    */
  }
  
  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Calcular el sourceRect basado en el frame actual
    final sourceRect = Rect.fromLTWH(
      _currentFrame * 128.0, // Cada frame es 128px de ancho
      0,
      128,
      128,
    );
    
    return FutureBuilder<ui.Image>(
      future: _loadImage(widget.spritePath),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _TreeSpritePainter(
              image: snapshot.data!,
              sourceRect: sourceRect,
            ),
          );
        }
        // Placeholder mientras carga
        return SizedBox(
          width: widget.width,
          height: widget.height,
        );
      },
    );
  }
  
  Future<ui.Image> _loadImage(String path) async {
    final completer = Completer<ui.Image>();
    final image = AssetImage(path);
    final stream = image.resolve(const ImageConfiguration());
    
    stream.addListener(ImageStreamListener((info, _) {
      completer.complete(info.image);
    }));
    
    return completer.future;
  }
}

/// Painter para renderizar un frame específico del sprite sheet
class _TreeSpritePainter extends CustomPainter {
  final ui.Image image;
  final Rect sourceRect;
  
  _TreeSpritePainter({
    required this.image,
    required this.sourceRect,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final destRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, sourceRect, destRect, Paint());
  }
  
  @override
  bool shouldRepaint(_TreeSpritePainter oldDelegate) {
    return oldDelegate.sourceRect != sourceRect;
  }
}
