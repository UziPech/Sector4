import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_service.dart';
import '../widgets/login_dialog.dart';
import 'login_form_screen.dart';

/// Pantalla de Login - Expediente Kōrin
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  // Estados de expansión
  bool _isLoginExpanded = false;
  bool _isRegisterExpanded = false;
  
  // Controladores de formulario
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  late AnimationController _rainController;
  late AnimationController _bloodController;
  late Timer _glitchTimer;
  bool _showGlitch = false;
  double _glitchOffset = 0;
  double _glitchOpacity = 1.0;
  Color _glitchColor = const Color(0xFFFFFFFF); // Empieza en blanco
  final Random _random = Random();
  final AudioService _audioService = AudioService();
  
  // Colores terroríficos para el glitch (sin blanco)
  final List<Color> _glitchColors = [
    const Color(0xFFFF0000), // Rojo sangre
    const Color(0xFFDC143C), // Crimson
    const Color(0xFF8B0000), // Rojo oscuro
    const Color(0xFFFF6B6B), // Rojo claro
    const Color(0xFFFF4444), // Rojo brillante
    const Color(0xFFFF1744), // Rojo intenso
  ];

  @override
  void initState() {
    super.initState();
    
    // Inicializar servicio de audio y reproducir música de fondo
    _audioService.initialize().then((_) {
      _audioService.playLoginMusic();
    });
    
    // Controlador para la animación de lluvia
    _rainController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Controlador para la animación de sangre
    _bloodController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Timer para efecto glitch VHS/TV (cada 8 segundos, más espaciado)
    _glitchTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_random.nextDouble() < 0.25) { // 25% probabilidad (más ocasional)
        // Reproducir sonido de glitch
        _audioService.playGlitchEffect();
        
        // Efecto glitch corto con cambio de color
        setState(() {
          _showGlitch = true;
          _glitchOffset = _random.nextDouble() * 10 - 5; // Desplazamiento aleatorio
          _glitchOpacity = 0.5 + _random.nextDouble() * 0.5; // Opacidad variable
          _glitchColor = _glitchColors[_random.nextInt(_glitchColors.length)]; // Color aleatorio
        });
        
        // Duración del glitch (100-300ms)
        final glitchDuration = 100 + _random.nextInt(200);
        Future.delayed(Duration(milliseconds: glitchDuration), () {
          if (mounted) {
            setState(() {
              _showGlitch = false;
              _glitchOffset = 0;
              _glitchOpacity = 1.0;
              _glitchColor = Colors.white; // Volver a blanco
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _rainController.dispose();
    _bloodController.dispose();
    _glitchTimer.cancel();
    _audioService.stopLoginMusic();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Solo aplicar responsive en móviles (no en web)
    final isMobile = !kIsWeb && size.width < 600;
    final titleFontSize = isMobile ? 9.0 : 52.0;
    final buttonFontSize = isMobile ? 12.0 : 18.0;
    final buttonWidth = isMobile ? size.width * 0.55 : 300.0;
    final padding = isMobile ? 38.0 : 40.0;
    
    return Scaffold(
      body: Stack(
        children: [
          // 1. Imagen de Fondo (Nueva versión con más terror)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login_screen_new.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Efecto de Viñeta (oscurecer bordes)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.6),
                ],
                stops: const [0.4, 0.7, 1.0],
              ),
            ),
          ),

          // 3. Efecto de Lluvia
          AnimatedBuilder(
            animation: _rainController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: RainPainter(_rainController.value),
              );
            },
          ),

          // 4. Capa de oscurecimiento general
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),

          // 5. Contenido Principal
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: size.width - (padding * 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    // Título del juego con efecto de sangre (arriba a la izquierda)
                    SizedBox(
                      height: isMobile ? 10 : 150,
                      width: isMobile ? size.width * 0.85 : 600,
                    child: Stack(
                      children: [
                        // Efecto de sangre goteando
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _bloodController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: BloodDripPainter(_bloodController.value),
                              );
                            },
                          ),
                        ),
                        
                        // Título con efecto VHS/TV glitch
                        Positioned(
                          top: 0,
                          left: _glitchOffset, // Desplazamiento horizontal durante glitch
                          child: Opacity(
                            opacity: _glitchOpacity, // Opacidad variable durante glitch
                            child: Stack(
                              children: [
                                // Capa de glitch rojo (canal R)
                                if (_showGlitch)
                                  Transform.translate(
                                    offset: Offset(-2, 0),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(
                                        'EXPEDIENTE KŌRIN',
                                        style: GoogleFonts.specialElite(
                                          color: Colors.red.withValues(alpha: 0.7),
                                          fontSize: titleFontSize,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 4,
                                        ),
                                      ),
                                    ),
                                  ),
                                
                                // Capa de glitch cyan (canal B)
                                if (_showGlitch)
                                  Transform.translate(
                                    offset: Offset(2, 0),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(
                                        'EXPEDIENTE KŌRIN',
                                        style: GoogleFonts.specialElite(
                                          color: Colors.cyan.withValues(alpha: 0.7),
                                          fontSize: titleFontSize,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 4,
                                        ),
                                      ),
                                    ),
                                  ),
                                
                                // Título principal con color dinámico
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: _showGlitch 
                                              ? _glitchColor.withValues(alpha: 0.5)
                                              : Colors.red.withValues(alpha: 0.3),
                                        blurRadius: _showGlitch ? 40 : 30,
                                        spreadRadius: _showGlitch ? 8 : 5,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'EXPEDIENTE KŌRIN',
                                    style: GoogleFonts.specialElite(
                                      color: _glitchColor, // Color dinámico durante glitch
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 4,
                                      shadows: [
                                        Shadow(
                                          color: _showGlitch ? _glitchColor : Colors.red,
                                          offset: const Offset(3, 3),
                                          blurRadius: _showGlitch ? 20 : 15,
                                        ),
                                        const Shadow(
                                          color: Colors.black,
                                          offset: Offset(1, 1),
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Botones expandibles de login
                  _buildExpandableLoginButton(
                    isMobile: isMobile,
                    buttonWidth: buttonWidth,
                    buttonFontSize: buttonFontSize,
                  ),
                  const SizedBox(height: 8),
                  _buildExpandableRegisterButton(
                    isMobile: isMobile,
                    buttonWidth: buttonWidth,
                    buttonFontSize: buttonFontSize,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Versión (abajo a la izquierda)
                  Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 20,
                    vertical: isMobile ? 2 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'v0.1.0 - Login System',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 10 : 12,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                ),
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

  // Botón expandible de Login
  Widget _buildExpandableLoginButton({
    required bool isMobile,
    required double buttonWidth,
    required double buttonFontSize,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: buttonWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón principal
          GestureDetector(
            onTap: () {
              // Siempre usar BottomSheet en móvil
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const LoginDialog(isRegister: false),
              );
            },
            child: Container(
              width: buttonWidth,
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 6 : 16,
                horizontal: isMobile ? 10 : 24,
              ),
              decoration: BoxDecoration(
                color: _isLoginExpanded 
                    ? Colors.red.withValues(alpha: 0.3)
                    : Colors.transparent,
                border: Border.all(
                  color: _isLoginExpanded ? Colors.red : Colors.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'INICIAR SESIÓN',
                    style: TextStyle(
                      color: _isLoginExpanded ? Colors.red : Colors.white,
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                  Icon(
                    _isLoginExpanded ? Icons.expand_less : Icons.expand_more,
                    color: _isLoginExpanded ? Colors.red : Colors.white,
                    size: isMobile ? 20 : 24,
                  ),
                ],
              ),
            ),
          ),
          
          // Formulario expandible
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCompactTextField(
                    controller: _emailController,
                    label: 'EMAIL',
                    hint: 'tu@email.com',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildCompactTextField(
                    controller: _passwordController,
                    label: 'CONTRASEÑA',
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    onTogglePassword: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implementar login
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'ENTRAR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _isLoginExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  // Botón expandible de Registro
  Widget _buildExpandableRegisterButton({
    required bool isMobile,
    required double buttonWidth,
    required double buttonFontSize,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: buttonWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón principal
          GestureDetector(
            onTap: () {
              // Siempre usar BottomSheet en móvil
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const LoginDialog(isRegister: true),
              );
            },
            child: Container(
              width: buttonWidth,
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 6 : 16,
                horizontal: isMobile ? 10 : 24,
              ),
              decoration: BoxDecoration(
                color: _isRegisterExpanded 
                    ? Colors.red.withValues(alpha: 0.3)
                    : Colors.transparent,
                border: Border.all(
                  color: _isRegisterExpanded ? Colors.red : Colors.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'REGISTRARSE',
                    style: TextStyle(
                      color: _isRegisterExpanded ? Colors.red : Colors.white,
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                  Icon(
                    _isRegisterExpanded ? Icons.expand_less : Icons.expand_more,
                    color: _isRegisterExpanded ? Colors.red : Colors.white,
                    size: isMobile ? 20 : 24,
                  ),
                ],
              ),
            ),
          ),
          
          // Formulario expandible
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCompactTextField(
                    controller: _usernameController,
                    label: 'USUARIO',
                    hint: 'tu_usuario',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  _buildCompactTextField(
                    controller: _emailController,
                    label: 'EMAIL',
                    hint: 'tu@email.com',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildCompactTextField(
                    controller: _passwordController,
                    label: 'CONTRASEÑA',
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    onTogglePassword: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildCompactTextField(
                    controller: _confirmPasswordController,
                    label: 'CONFIRMAR',
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isPasswordVisible: _isConfirmPasswordVisible,
                    onTogglePassword: () {
                      setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implementar registro
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'CREAR CUENTA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _isRegisterExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  // Campo de texto compacto
  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.red.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: isPassword && !isPasswordVisible,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
            ),
            prefixIcon: Icon(icon, color: Colors.red.withValues(alpha: 0.6), size: 16),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 16,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.8), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

/// Widget de botón de login estilo terror mejorado
class _LoginButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final double width;
  final bool isMobile;
  final double fontSize;

  const _LoginButton({
    required this.text,
    required this.onPressed,
    this.width = 300,
    this.isMobile = false,
    this.fontSize = 18,
  });

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _isHovered = false;
  final AudioService _audioService = AudioService();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        // Solo reproducir sonido en web, no en Android
        if (kIsWeb) {
          _audioService.playButtonHover();
        }
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          // Solo reproducir sonido en web, no en Android
          if (kIsWeb) {
            _audioService.playButtonClick();
          }
          widget.onPressed?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: widget.width,
          padding: EdgeInsets.symmetric(
            vertical: widget.isMobile ? 5 : 16,
            horizontal: widget.isMobile ? 8 : 24,
          ),
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
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isHovered ? Colors.red : Colors.white,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black,
                  offset: const Offset(1, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Painter para efecto de lluvia
class RainPainter extends CustomPainter {
  final double animationValue;
  static final List<Raindrop> _raindrops = List.generate(
    80,
    (index) => Raindrop(index),
  );

  RainPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    for (final raindrop in _raindrops) {
      raindrop.update(size);
      raindrop.draw(canvas, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Clase para gota de lluvia individual
class Raindrop {
  double x;
  double y;
  final double length;
  final double speed;
  static final Random _random = Random();

  Raindrop(int seed)
      : x = _random.nextDouble() * 2000,
        y = _random.nextDouble() * 2000,
        length = 10 + _random.nextDouble() * 20,
        speed = 200 + _random.nextDouble() * 300;

  void update(Size size) {
    y += speed * 0.016; // ~60fps
    if (y > size.height + length) {
      y = -length;
      x = _random.nextDouble() * size.width;
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

/// Custom Painter para efecto de sangre derritiéndose del título
class BloodDripPainter extends CustomPainter {
  final double animationValue;
  static final List<BloodDrip> _bloodDrips = List.generate(
    20, // Ajustado para que no sobrepase el título
    (index) => BloodDrip(index),
  );

  BloodDripPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Dibujar manchas de sangre sobre las letras
    _drawBloodStains(canvas, size);
    
    // Dibujar gotas cayendo
    for (final drip in _bloodDrips) {
      drip.update(size);
      drip.draw(canvas, paint);
    }
  }

  void _drawBloodStains(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Posiciones aproximadas de las letras principales (ajustadas al ancho real)
    final stainPositions = [
      {'x': 20.0, 'width': 35.0}, // E
      {'x': 65.0, 'width': 32.0}, // X
      {'x': 107.0, 'width': 32.0}, // P
      {'x': 149.0, 'width': 32.0}, // E
      {'x': 191.0, 'width': 32.0}, // D
      {'x': 233.0, 'width': 18.0}, // I
      {'x': 261.0, 'width': 32.0}, // E
      {'x': 303.0, 'width': 32.0}, // N
      {'x': 345.0, 'width': 28.0}, // T
      {'x': 383.0, 'width': 32.0}, // E
      {'x': 435.0, 'width': 32.0}, // K
      {'x': 477.0, 'width': 32.0}, // Ō
      {'x': 519.0, 'width': 32.0}, // R
      // Removidas las últimas letras que sobrepasan
    ];

    for (final pos in stainPositions) {
      final x = pos['x']!;
      final width = pos['width']!;
      
      // Mancha de sangre en la parte superior de cada letra
      final rect = Rect.fromLTWH(x, 45, width, 25);
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF8B0000).withValues(alpha: 0.7),
          const Color(0xFFDC143C).withValues(alpha: 0.5),
          const Color(0xFFFF0000).withValues(alpha: 0.0),
        ],
      ).createShader(rect);
      
      // Forma irregular de mancha
      final path = Path();
      path.moveTo(x + width * 0.2, 45);
      path.quadraticBezierTo(x + width * 0.5, 50, x + width * 0.8, 45);
      path.lineTo(x + width * 0.9, 60);
      path.quadraticBezierTo(x + width * 0.7, 65, x + width * 0.5, 70);
      path.quadraticBezierTo(x + width * 0.3, 65, x + width * 0.1, 60);
      path.close();
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Clase para gota de sangre individual
class BloodDrip {
  double x;
  double y;
  double length;
  final double speed;
  final double maxLength;
  final int startDelay;
  static final Random _random = Random();
  int frameCount = 0;

  BloodDrip(int index)
      : x = 20 + (index * 25.0) + (_random.nextDouble() * 15 - 7.5),
        y = 65 + (_random.nextDouble() * 10),
        length = 0,
        speed = 0.3 + _random.nextDouble() * 0.6,
        maxLength = 30 + _random.nextDouble() * 70,
        startDelay = (index * 10) + _random.nextInt(40) {
    // Asegurar que no sobrepase el ancho del título (~550px)
    if (x > 540) {
      x = 540 - _random.nextDouble() * 50;
    }
  }

  void update(Size size) {
    frameCount++;
    
    if (frameCount > startDelay) {
      // Crecer la gota
      if (length < maxLength) {
        length += speed;
      } else {
        // Caer
        y += speed * 2;
        
        // Reiniciar cuando sale de la pantalla
        if (y > size.height) {
          y = 60;
          length = 0;
          frameCount = startDelay - 20;
        }
      }
    }
  }

  void draw(Canvas canvas, Paint paint) {
    if (length <= 0) return;

    final width = 2.5 + (length / maxLength) * 1.5; // Ancho variable
    
    // Gradiente de sangre más realista
    final rect = Rect.fromLTWH(x - width, y, width * 2, length);
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF5A0000).withValues(alpha: 0.9), // Rojo muy oscuro
        const Color(0xFF8B0000).withValues(alpha: 0.95), // Rojo oscuro
        const Color(0xFFDC143C).withValues(alpha: 0.9), // Crimson
        const Color(0xFFFF0000).withValues(alpha: 0.7), // Rojo brillante
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    ).createShader(rect);

    // Forma de sangre derramándose (más irregular)
    final path = Path();
    path.moveTo(x, y);
    
    // Lado izquierdo con irregularidades
    path.quadraticBezierTo(
      x - width * 0.8, y + length * 0.2,
      x - width, y + length * 0.4,
    );
    path.quadraticBezierTo(
      x - width * 1.2, y + length * 0.6,
      x - width * 0.7, y + length * 0.8,
    );
    path.lineTo(x - width * 0.3, y + length * 0.95);
    
    // Punta de la gota
    path.quadraticBezierTo(
      x, y + length,
      x + width * 0.3, y + length * 0.95,
    );
    
    // Lado derecho con irregularidades
    path.lineTo(x + width * 0.7, y + length * 0.8);
    path.quadraticBezierTo(
      x + width * 1.2, y + length * 0.6,
      x + width, y + length * 0.4,
    );
    path.quadraticBezierTo(
      x + width * 0.8, y + length * 0.2,
      x, y,
    );
    path.close();

    canvas.drawPath(path, paint);

    // Gota acumulada en la punta (más grande y orgánica)
    if (length >= maxLength * 0.7) {
      paint.shader = null;
      paint.color = const Color(0xFF8B0000).withValues(alpha: 0.95);
      
      // Gota irregular en la punta
      final dropPath = Path();
      final dropY = y + length;
      dropPath.addOval(Rect.fromCenter(
        center: Offset(x, dropY),
        width: 4 + (length / maxLength) * 2,
        height: 5 + (length / maxLength) * 3,
      ));
      canvas.drawPath(dropPath, paint);
    }
  }
}

/// Custom Painter para efecto de niebla
class FogPainter extends CustomPainter {
  final double animationValue;
  static final List<FogLayer> _fogLayers = List.generate(
    5, // 5 capas de niebla
    (index) => FogLayer(index),
  );

  FogPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (final fog in _fogLayers) {
      fog.update(size, animationValue);
      fog.draw(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Clase para capa de niebla individual
class FogLayer {
  final int index;
  double offsetX;
  final double speed;
  final double opacity;
  final double height;
  static final Random _random = Random();

  FogLayer(this.index)
      : offsetX = _random.nextDouble() * 1000,
        speed = 20 + _random.nextDouble() * 30, // Velocidad lenta
        opacity = 0.05 + _random.nextDouble() * 0.1, // Muy sutil
        height = 100 + _random.nextDouble() * 200;

  void update(Size size, double animationValue) {
    // Movimiento horizontal lento
    offsetX = (offsetX + speed * 0.016) % (size.width + 500);
  }

  void draw(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Posición vertical (diferentes alturas)
    final y = (index * size.height / 5) + (size.height * 0.1);

    // Gradiente de niebla (teal/verde azulado para ambiente japonés)
    final rect = Rect.fromLTWH(offsetX - 250, y, 500, height);
    paint.shader = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        const Color(0xFF00CED1).withValues(alpha: opacity), // Teal claro
        const Color(0xFF008B8B).withValues(alpha: opacity * 0.7), // Teal oscuro
        const Color(0xFF00CED1).withValues(alpha: 0.0), // Transparente
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(rect);

    // Dibujar óvalo de niebla
    canvas.drawOval(rect, paint);
  }
}
