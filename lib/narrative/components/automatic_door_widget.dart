import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/room_data.dart';
import '../models/interactable_data.dart'; // For Vector2

class AutomaticDoorWidget extends StatefulWidget {
  final DoorData doorData;
  final Vector2 playerPosition;
  final double activationDistance;

  const AutomaticDoorWidget({
    Key? key,
    required this.doorData,
    required this.playerPosition,
    this.activationDistance = 100.0,
  }) : super(key: key);

  @override
  State<AutomaticDoorWidget> createState() => _AutomaticDoorWidgetState();
}

class _AutomaticDoorWidgetState extends State<AutomaticDoorWidget> with SingleTickerProviderStateMixin {
  ui.Image? _spriteSheet;
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _loadSpriteSheet();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 3).animate(_controller);
  }

  Future<void> _loadSpriteSheet() async {
    // Cargar la imagen del sprite sheet
    final imageProvider = const AssetImage('assets/images/door_sliding_spritesheet.png');
    final stream = imageProvider.resolve(ImageConfiguration.empty);
    stream.addListener(ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _spriteSheet = info.image;
        });
      }
    }));
  }

  @override
  void didUpdateWidget(AutomaticDoorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkProximity();
  }

  void _checkProximity() {
    final doorCenter = widget.doorData.position + widget.doorData.size / 2;
    final dist = widget.playerPosition.distanceTo(doorCenter);
    
    if (dist < widget.activationDistance) {
      if (!_isOpen) {
        _isOpen = true;
        _controller.forward();
      }
    } else {
      if (_isOpen) {
        _isOpen = false;
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_spriteSheet == null) {
      // Placeholder mientras carga o si falla
      return Container(
        width: widget.doorData.size.x,
        height: widget.doorData.size.y,
        color: Colors.transparent, // Invisible, solo debug si es necesario
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.doorData.size.x, widget.doorData.size.y),
          painter: _DoorPainter(
            spriteSheet: _spriteSheet!,
            frame: _animation.value,
          ),
        );
      },
    );
  }
}

class _DoorPainter extends CustomPainter {
  final ui.Image spriteSheet;
  final double frame;

  _DoorPainter({required this.spriteSheet, required this.frame});

  @override
  void paint(Canvas canvas, Size size) {
    final int currentFrameIndex = frame.round();
    
    // El sprite sheet es 2x2
    // Frame 0: (0,0)
    // Frame 1: (1,0)
    // Frame 2: (0,1)
    // Frame 3: (1,1)
    
    final int col = currentFrameIndex % 2;
    final int row = currentFrameIndex ~/ 2;
    
    final double frameWidth = spriteSheet.width / 2;
    final double frameHeight = spriteSheet.height / 2;
    
    final Rect srcRect = Rect.fromLTWH(
      col * frameWidth,
      row * frameHeight,
      frameWidth,
      frameHeight,
    );
    
    final Rect dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    canvas.drawImageRect(spriteSheet, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant _DoorPainter oldDelegate) {
    return oldDelegate.frame != frame || oldDelegate.spriteSheet != spriteSheet;
  }
}
