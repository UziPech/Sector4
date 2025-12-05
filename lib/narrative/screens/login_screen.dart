import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'house_scene.dart';
import '../../game/audio_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    
    // Inicializar Video
    _controller = VideoPlayerController.asset('assets/images/Fondo.mp4')
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
    // AudioManager().stopMusic(); // Opcional, según lógica del remoto
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

          // 3. CONTENIDO CENTRADO
          Center(
            child: Container(
              width: 700,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // FONDO DE MADERA (Escalado para eliminar bordes transparentes)
                  Positioned.fill(
                    child: Transform.scale(
                      scale: 1.3, // Aumentar escala para que la madera cubra todo
                      child: Image.asset(
                        'assets/images/wood_card_bg.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  
                  // CONTENIDO
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 80), // Más padding horizontal para evitar bordes metálicos
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'INICIAR SESIÓN',
                          style: GoogleFonts.rye(
                            color: const Color(0xFFFFECB3),
                            fontSize: 38, // Ligeramente más grande
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
                          'Selecciona el método de inicio de sesión',
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
                        const SizedBox(height: 50),

                        // BOTÓN INVITADO
                        _LoginButton(
                          text: 'Iniciar sesión como invitado',
                          icon: Icons.person_outline,
                          iconColor: Colors.black,
                          onPressed: () {
                            // Navegar al juego (Capítulo 1)
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const HouseScene(),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 20),

                        // BOTÓN GOOGLE
                        _LoginButton(
                          text: 'Iniciar sesión con Google',
                          icon: FontAwesomeIcons.google,
                          iconColor: Colors.red,
                          onPressed: () {
                            _showComingSoonSnackBar(context, 'Google Login');
                          },
                        ),

                        const SizedBox(height: 20),

                        // BOTÓN FACEBOOK
                        _LoginButton(
                          text: 'Iniciar sesión con Facebook',
                          icon: FontAwesomeIcons.facebookF,
                          iconColor: Colors.blue[800]!,
                          onPressed: () {
                            _showComingSoonSnackBar(context, 'Facebook Login');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
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

  void _showComingSoonSnackBar(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Requiere configuración de Backend (Firebase)'),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
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
        color: Colors.black.withOpacity(0.4), // Fondo oscuro semitransparente para contrastar con la madera
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8D6E63).withOpacity(0.5)), // Borde sutil
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
                Icon(icon, color: Colors.white, size: 24), // Icono blanco para uniformidad
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
