import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'house_scene.dart';
import '../../game/audio_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late VideoPlayerController _controller;

  // Controladores de texto
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Estado
  bool _isLoginMode = true;

  // Base de datos simulada en memoria (Email -> Password)
  // static final Map<String, String> _mockUsers = {}; // Ya no se usa, usamos SharedPreferences

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Por favor completa todos los campos', isError: true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userKey = 'user:$email';

    if (_isLoginMode) {
      // Lógica de Login
      final storedPassword = prefs.getString(userKey);

      if (storedPassword != null && storedPassword == password) {
        // Login exitoso
        _showSnackBar('¡Bienvenido de nuevo!', isError: false);
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HouseScene()),
          );
        });
      } else {
        _showSnackBar('Credenciales inválidas', isError: true);
      }
    } else {
      // Lógica de Registro
      if (prefs.containsKey(userKey)) {
        _showSnackBar('El usuario ya existe', isError: true);
      } else {
        await prefs.setString(userKey, password);
        _showSnackBar(
          '¡Cuenta creada exitosamente! Ahora inicia sesión.',
          isError: false,
        );
        setState(() {
          _isLoginMode = true; // Cambiar a login
          _passwordController.clear();
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.robotoMono(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8D6E63).withOpacity(0.5)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: GoogleFonts.robotoMono(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.robotoMono(color: Colors.white70),
          prefixIcon: Icon(icon, color: const Color(0xFFFFECB3)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Inicializar Video
    _controller =
        VideoPlayerController.asset(
            'assets/images/Fondo.mp4',
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          )
          ..initialize().then((_) {
            _controller.setLooping(true);
            _controller.setVolume(0.0); // Mute video
            _controller.play();
            setState(() {}); // Refresh to show video
          });

    // Inicializar Audio (Integrado del remoto)
    AudioManager().init().then((_) {
      AudioManager().playLoginMusic();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    // AudioManager().stopMusic(); // Opcional, según lógica del remoto
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Ancho responsivo: 700 o 90% del ancho de pantalla, lo que sea menor
    final containerWidth = size.width > 700 ? 700.0 : size.width * 0.9;

    return Scaffold(
      body: Stack(
        children: [
          // 1. FONDO DE VIDEO
          Positioned.fill(
            child: _controller.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  )
                : Container(color: Colors.black), // Fallback mientras carga
          ),

          // 2. CAPA OSCURA (Vignette)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),

          // 3. CONTENIDO CENTRADO (Con Scroll)
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: containerWidth,
                margin: const EdgeInsets.symmetric(
                  vertical: 20,
                ), // Margen vertical para scroll
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // FONDO DE MADERA (Escalado para eliminar bordes transparentes)
                    Positioned.fill(
                      child: Transform.scale(
                        scale:
                            1.3, // Aumentar escala para que la madera cubra todo
                        child: Image.asset(
                          'assets/images/wood_card_bg.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),

                    // CONTENIDO
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40, // Reducido para móviles
                        vertical: 60,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isLoginMode ? 'INICIAR SESIÓN' : 'REGISTRARSE',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.rye(
                              color: const Color(0xFFFFECB3),
                              fontSize: size.width < 600
                                  ? 28
                                  : 38, // Fuente responsiva
                              fontWeight: FontWeight.bold,
                              shadows: [
                                const Shadow(
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isLoginMode
                                ? 'Ingresa tus credenciales para continuar'
                                : 'Crea una cuenta nueva',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.robotoMono(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                const Shadow(
                                  color: Colors.black,
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),

                          // --- FORMULARIO ---
                          _buildTextField(
                            controller: _emailController,
                            label: 'Correo Electrónico',
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Contraseña',
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 24),

                          // BOTÓN DE ACCIÓN PRINCIPAL
                          _LoginButton(
                            text: _isLoginMode ? 'ENTRAR' : 'REGISTRARSE',
                            icon: _isLoginMode ? Icons.login : Icons.person_add,
                            iconColor: Colors.white,
                            onPressed: _handleAuth,
                          ),

                          const SizedBox(height: 16),

                          // CAMBIAR MODO
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLoginMode = !_isLoginMode;
                                _emailController.clear();
                                _passwordController.clear();
                              });
                            },
                            child: Text(
                              _isLoginMode
                                  ? '¿No tienes cuenta? Regístrate'
                                  : '¿Ya tienes cuenta? Inicia Sesión',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.robotoMono(
                                color: Colors.white70,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 20),

                          // BOTÓN INVITADO
                          _LoginButton(
                            text: 'Entrar como Invitado',
                            icon: Icons.person_outline,
                            iconColor: Colors.grey,
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const HouseScene(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. BOTÓN CERRAR (X)
          Positioned(
            top: 40,
            right: 40,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () {
                Navigator.of(context).pop(); // Volver al menú
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  const _LoginButton({
    required this.text,
    required this.icon,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50, // Más pequeños (antes 60)
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(
          0.4,
        ), // Fondo oscuro semitransparente para contrastar con la madera
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF8D6E63).withOpacity(0.5),
        ), // Borde sutil
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ), // Icono blanco para uniformidad
                Expanded(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.robotoMono(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFECB3), // Color crema claro
                      shadows: [
                        const Shadow(
                          color: Colors.black,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24), // Equilibrio
              ],
            ),
          ),
        ),
      ),
    );
  }
}
