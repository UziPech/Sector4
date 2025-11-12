import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pantalla de Login con Efectos Visuales - Expediente Kōrin
class LoginScreenEnhanced extends StatefulWidget {
  const LoginScreenEnhanced({super.key});

  @override
  State<LoginScreenEnhanced> createState() => _LoginScreenEnhancedState();
}

class _LoginScreenEnhancedState extends State<LoginScreenEnhanced>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _showGlitch = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Efecto glitch sutil cada 4-6 segundos
    _startGlitchEffect();
  }

  void _startGlitchEffect() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showGlitch = !_showGlitch;
        });
        _startGlitchEffect(); // Repetir
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Imagen de Fondo
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login_screen.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Efecto de Viñeta
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.7),
                ],
                stops: const [0.4, 0.7, 1.0],
              ),
            ),
          ),

          // 3. Efecto de Lluvia Sutil (animado)
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: RainPainter(_animationController.value),
              );
            },
          ),

          // 4. Capa de Oscurecimiento
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),

          // 5. Contenido Principal
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Título Principal con Google Fonts
                Text(
                  'EXPEDIENTE KŌRIN',
                  style: GoogleFonts.specialElite(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: Colors.red.withValues(alpha: 0.8),
                        offset: const Offset(3, 3),
                        blurRadius: 15,
                      ),
                      Shadow(
                        color: Colors.black,
                        offset: const Offset(1, 1),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 3),

                // Botones de login mejorados
                Column(
                  children: [
                    _EnhancedLoginButton(
                      text: 'INICIAR SESIÓN',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Login - Próximamente'),
                            duration: Duration(seconds: 2),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _EnhancedLoginButton(
                      text: 'REGISTRARSE',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Registro - Próximamente'),
                            duration: Duration(seconds: 2),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const Spacer(flex: 1),

                // Versión con efecto glitch sutil
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    'v0.1.0 - Login System',
                    key: ValueKey(_showGlitch),
                    style: _showGlitch
                        ? GoogleFonts.cinzel(
                            color: Colors.red.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          )
                        : GoogleFonts.yujiSyuku(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de botón de login mejorado con efectos de terror
class _EnhancedLoginButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;

  const _EnhancedLoginButton({
    required this.text,
    required this.onPressed,
  });

  @override
  State<_EnhancedLoginButton> createState() => _EnhancedLoginButtonState();
}

class _EnhancedLoginButtonState extends State<_EnhancedLoginButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _glitchController;

  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _glitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _glitchController.forward().then((_) => _glitchController.reverse());
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 300,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.red.withValues(alpha: 0.2)
                : Colors.transparent,
            border: Border.all(
              color: _isHovered ? Colors.red : Colors.white,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: AnimatedBuilder(
            animation: _glitchController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  _glitchController.value * 2,
                  _glitchController.value * -1,
                ),
                child: Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.specialElite(
                    color: _isHovered ? Colors.red : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: _isHovered ? Colors.red : Colors.black,
                        offset: const Offset(1, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Custom Painter para efecto de lluvia
class RainPainter extends CustomPainter {
  final double animationValue;
  final List<Raindrop> raindrops = List.generate(50, (index) => Raindrop());

  RainPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    for (final raindrop in raindrops) {
      raindrop.update(animationValue, size.height);
      raindrop.draw(canvas, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Clase para gota de lluvia
class Raindrop {
  double x;
  double y;
  final double length;
  final double speed;

  Raindrop()
      : x = _randomOffset(),
        y = _randomOffset(),
        length = 10 + _randomOffset() * 20,
        speed = 100 + _randomOffset() * 200;

  static double _randomOffset() => (DateTime.now().millisecondsSinceEpoch % 100) / 100.0;

  void update(double animationValue, double screenHeight) {
    y += speed * 0.016; // ~60fps
    if (y > screenHeight) {
      y = -length;
      x = _randomOffset() * 400; // Ancho de pantalla simulado
    }
  }

  void draw(Canvas canvas, Paint paint) {
    canvas.drawLine(
      Offset(x, y),
      Offset(x, y + length),
      paint,
    );
  }
}
