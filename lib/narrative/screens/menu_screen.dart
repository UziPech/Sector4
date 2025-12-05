import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'house_scene.dart';
import 'bunker_scene.dart';
import 'story_screen.dart';
import 'login_screen.dart';

/// Pantalla del menú principal con efectos visuales avanzados
class MenuScreen extends StatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  // Controladores para la lluvia
  late AnimationController _rainController;
  final List<Raindrop> _raindrops = [];
  final Random _random = Random();

  // Controladores para el efecto Glitch del texto
  Timer? _glitchTimer;
  bool _isTitleGlitching = false;

  @override
  void initState() {
    super.initState();
    
    // Inicializar lluvia
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    
    _generateRaindrops();

    // Inicializar efecto glitch (cada 3-6s)
    _scheduleGlitch();
  }

  void _scheduleGlitch() {
    _glitchTimer = Timer(Duration(milliseconds: 3000 + _random.nextInt(3000)), () {
      if (mounted) {
        setState(() => _isTitleGlitching = true);
        
        // Duración del glitch (corto, como estática)
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() => _isTitleGlitching = false);
            _scheduleGlitch(); // Programar el siguiente
          }
        });
      }
    });
  }

  void _generateRaindrops() {
    // Generar 100 gotas iniciales
    for (int i = 0; i < 100; i++) {
      _raindrops.add(Raindrop(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.01 + _random.nextDouble() * 0.02,
        length: 0.02 + _random.nextDouble() * 0.03,
      ));
    }
  }

  @override
  void dispose() {
    _rainController.dispose();
    _glitchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. CAPA DE FONDO (Imagen Base)
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_screen_new.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 2. EFECTO DE VIÑETA (Radial Gradient)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8), // Bordes oscuros
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ),

          // 3. EFECTO DE LLUVIA (CustomPaint + AnimatedBuilder)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _rainController,
              builder: (context, child) {
                return CustomPaint(
                  painter: RainPainter(
                    raindrops: _raindrops,
                    random: _random,
                  ),
                );
              },
            ),
          ),

          // 4. CAPA DE OSCURECIMIENTO (Overlay general)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),

          // 5. CONTENIDO (Texto y Botones)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 80.0), // Margen izquierdo considerable
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: 800, 
                  height: 700, 
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start, // Todo alineado a la izquierda
                    children: [
                      // Espacio superior para bajar un poco el título del borde
                      const SizedBox(height: 80),
                      
                      // --- TÍTULO ---
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: BleedingTitleWrapper(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VHSGlitchTitle(
                                text: 'EXPEDIENTE', 
                                fontSize: 64, 
                                isGlitching: _isTitleGlitching,
                              ),
                              const SizedBox(width: 24),
                              VHSGlitchTitle(
                                text: 'KŌRIN',
                                fontSize: 64, 
                                isGlitching: _isTitleGlitching,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        'v0.1.0 - Capítulo 1',
                        style: GoogleFonts.robotoMono(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),

                      // Espacio flexible entre Título y Botones
                      const Spacer(), 
                      
                      // --- BOTONES ---
                      // Contenedor de ancho limitado para los botones
                      SizedBox(
                        width: 300, 
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // Botones alineados a la izquierda
                          children: [
                            _MenuButton(
                              text: 'NUEVO JUEGO',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            _MenuButton(
                              text: 'HISTORIA',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const StoryScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            _MenuButton(
                              text: 'CONTINUAR',
                              onPressed: null,
                              isDisabled: true,
                            ),
                            const SizedBox(height: 20),
                            _MenuButton(
                              text: 'OPCIONES',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Opciones - Próximamente'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            _MenuButton(
                              text: 'SALIR',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.black.withOpacity(0.9), // Fondo oscuro
                                      shape: RoundedRectangleBorder(
                                        side: const BorderSide(color: Colors.redAccent, width: 1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                            title: Text(
                                              'CONFIRMACIÓN',
                                              style: GoogleFonts.robotoMono(
                                                color: Colors.redAccent,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: Text(
                                              '¿Estás seguro que quieres salir del juego?',
                                              style: GoogleFonts.robotoMono(
                                                color: Colors.red, // Texto rojo como solicitado
                                                fontSize: 16,
                                              ),
                                            ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(); // Cerrar diálogo
                                          },
                                          child: Text(
                                            'NO',
                                            style: GoogleFonts.robotoMono(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            SystemNavigator.pop(); // Cerrar app
                                          },
                                          child: Text(
                                            'SÍ',
                                            style: GoogleFonts.robotoMono(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // Espacio inferior
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget wrapper para efecto de sangrado goteante (Estilo Referencia)
class BleedingTitleWrapper extends StatefulWidget {
  final Widget child;
  const BleedingTitleWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<BleedingTitleWrapper> createState() => _BleedingTitleWrapperState();
}

class _BleedingTitleWrapperState extends State<BleedingTitleWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<BloodDrip> _drips = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), 
    )..repeat();
    
    // Generar gotas para "cada letra" (aprox)
    // El texto tiene ~16 caracteres. Generamos ~20 gotas distribuidas uniformemente
    // para asegurar cobertura.
    for (int i = 0; i < 20; i++) {
      // Distribución más uniforme con pequeña variación aleatoria
      double baseX = (i / 20.0); 
      double jitter = _random.nextDouble() * 0.04 - 0.02;
      
      _drips.add(BloodDrip(
        x: (baseX + jitter).clamp(0.02, 0.98), 
        length: 0.2 + _random.nextDouble() * 0.4, // Longitud variable
        width: 4.0 + _random.nextDouble() * 2.0, // Grosor variable
        swayPhase: _random.nextDouble() * 2 * pi,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: DrippingBloodPainter(
                  drips: _drips, 
                  time: _controller.value
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class BloodDrip {
  double x; // Posición relativa 0-1
  double length; // Longitud relativa
  double width; // Ancho en pixels
  double swayPhase; // Fase para oscilación leve

  BloodDrip({
    required this.x,
    required this.length,
    required this.width,
    required this.swayPhase,
  });
}

class DrippingBloodPainter extends CustomPainter {
  final List<BloodDrip> drips;
  final double time;

  DrippingBloodPainter({required this.drips, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    // Pintura para la sangre (Rojo sólido y brillante)
    final paint = Paint()
      ..color = const Color(0xFFE60000) // Rojo sangre vivo
      ..style = PaintingStyle.fill; 

    // Pintura para el brillo interior (highlight)
    final highlightPaint = Paint()
      ..color = const Color(0xFFFF4D4D).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Pintura para la sombra/resplandor externo
    final glowPaint = Paint()
      ..color = const Color(0xFF800000).withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

    final path = Path();
    final highlightPath = Path();

    for (var drip in drips) {
      final startX = drip.x * size.width;
      // Ajuste fino para que salga justo del borde inferior de las letras
      final startY = size.height * 0.70; 
      final endY = startY + (drip.length * size.height * 0.5); // Longitud
      
      // Oscilación muy sutil
      final sway = sin(time * 2 * pi + drip.swayPhase) * 1.0;
      final endX = startX + sway;

      // Forma de gota redondeada (no afilada)
      final dripPath = Path();
      dripPath.moveTo(startX - drip.width / 2, startY);
      
      // Cuerpo de la gota (recto hasta cerca del final)
      dripPath.lineTo(endX - drip.width / 3, endY - drip.width);
      
      // Punta redondeada (arco)
      dripPath.arcToPoint(
        Offset(endX + drip.width / 3, endY - drip.width),
        radius: Radius.circular(drip.width / 2),
        clockwise: false,
      );
      
      dripPath.lineTo(startX + drip.width / 2, startY);
      dripPath.close();
      
      path.addPath(dripPath, Offset.zero);

      // Brillo en el centro
      final hlPath = Path();
      hlPath.moveTo(startX - drip.width / 4, startY);
      hlPath.lineTo(endX - drip.width / 6, endY - drip.width * 1.5);
      hlPath.lineTo(startX + drip.width / 4, startY);
      hlPath.close();
      highlightPath.addPath(hlPath, Offset.zero);
      
      // Gota cayendo (separada) - Forma redondeada
      if (time > 0.7 && (drip.swayPhase * 10).toInt() % 4 == 0) {
         final dropProgress = (time - 0.7) / 0.3; // 0 a 1
         final dropY = endY + dropProgress * size.height * 0.3;
         
         // Gota lágrima redondeada
         final dropPath = Path();
         dropPath.addOval(Rect.fromCircle(center: Offset(endX, dropY), radius: drip.width * 0.6));
         path.addPath(dropPath, Offset.zero);
      }
    }

    // Dibujar en orden: Resplandor -> Sangre Base -> Brillo
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant DrippingBloodPainter oldDelegate) => true;
}

/// Widget para efecto VHS/Glitch en el título
class VHSGlitchTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  final bool isGlitching;

  const VHSGlitchTitle({
    Key? key,
    required this.text,
    required this.fontSize,
    required this.isGlitching,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Random random = Random();
    
    // Si no hay glitch, mostrar texto normal blanco
    if (!isGlitching) {
      return Text(
        text,
        style: GoogleFonts.specialElite(
          color: Colors.white, // Blanco solicitado
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 8,
          height: 1.1,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      );
    }

    // Efecto Glitch: Aberración cromática (Rojo/Azul desfasados)
    return Stack(
      children: [
        // Capa Roja (Desfasada a la izquierda)
        Transform.translate(
          offset: const Offset(-3, 0),
          child: Text(
            text,
            style: GoogleFonts.specialElite(
              color: Colors.red.withOpacity(0.8),
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              height: 1.1,
            ),
          ),
        ),
        // Capa Azul (Desfasada a la derecha)
        Transform.translate(
          offset: const Offset(3, 0),
          child: Text(
            text,
            style: GoogleFonts.specialElite(
              color: Colors.blue.withOpacity(0.8),
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              height: 1.1,
            ),
          ),
        ),
        // Capa Blanca (Centro, con leve temblor vertical)
        Transform.translate(
          offset: Offset(0, random.nextDouble() * 2 - 1),
          child: Text(
            text,
            style: GoogleFonts.specialElite(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

/// Clase para representar una gota de lluvia
class Raindrop {
  double x; // Posición horizontal (0.0 a 1.0)
  double y; // Posición vertical (0.0 a 1.0)
  double speed; // Velocidad de caída
  double length; // Longitud de la estela

  Raindrop({
    required this.x,
    required this.y,
    required this.speed,
    required this.length,
  });
}

/// Painter para dibujar la lluvia
class RainPainter extends CustomPainter {
  final List<Raindrop> raindrops;
  final Random random;

  RainPainter({required this.raindrops, required this.random});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15) // Blanco semitransparente
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final drop in raindrops) {
      // Actualizar posición (simulación simple en el paint loop)
      drop.y += drop.speed;

      // Resetear si sale de la pantalla
      if (drop.y > 1.0) {
        drop.y = -drop.length;
        drop.x = random.nextDouble();
      }

      // Dibujar línea
      final start = Offset(drop.x * size.width, drop.y * size.height);
      final end = Offset(
        drop.x * size.width - (drop.length * size.width * 0.1), // Leve inclinación
        (drop.y + drop.length) * size.height
      );

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RainPainter oldDelegate) {
    return true; // Repintar siempre para animar
  }
}

/// Widget de botón del menú (Estilizado)
class _MenuButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isDisabled;

  const _MenuButton({
    required this.text,
    required this.onPressed,
    this.isDisabled = false,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _isHovered = false;
  bool _isPressed = false; // Estado de presionado

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isDisabled;

    // Determinar color base
    Color borderColor = Colors.grey[800]!;
    Color textColor = Colors.grey[700]!;
    Color backgroundColor = Colors.transparent;

    if (isEnabled) {
      if (_isPressed) {
        // ROJO al presionar
        borderColor = Colors.redAccent;
        textColor = Colors.redAccent;
        backgroundColor = Colors.redAccent.withOpacity(0.2);
      } else if (_isHovered) {
        // AMARILLO al pasar el mouse
        borderColor = Colors.yellow;
        textColor = Colors.yellow;
        backgroundColor = Colors.yellow.withOpacity(0.1);
      } else {
        // BLANCO normal
        borderColor = Colors.white.withOpacity(0.5);
        textColor = Colors.white;
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100), // Más rápido para feedback táctil
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: borderColor,
              width: 1.0,
            ),
          ),
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: GoogleFonts.robotoMono( // Fuente técnica para botones
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }
}
