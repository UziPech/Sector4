import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'house_scene.dart';
import '../../game/audio_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    // Iniciar música de login
    AudioManager().init().then((_) {
      AudioManager().playLoginMusic();
    });
  }

  @override
  void dispose() {
    // Detener música al salir del login (opcional, o dejar que la siguiente escena maneje el audio)
    // AudioManager().stopMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. FONDO (Mismo que el menú para consistencia)
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_screen_new.jpg',
              fit: BoxFit.cover,
            ),
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
              width: 600,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(
                  0.6,
                ), // Fondo semitransparente para el cuadro
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'INICIAR SESIÓN',
                    style: GoogleFonts.robotoMono(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona el método de inicio de sesión',
                    style: GoogleFonts.robotoMono(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 40),

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

                  const SizedBox(height: 16),

                  // BOTÓN GOOGLE
                  _LoginButton(
                    text: 'Iniciar sesión con Google',
                    icon: FontAwesomeIcons.google,
                    iconColor: Colors.red,
                    onPressed: () {
                      _showComingSoonSnackBar(context, 'Google Login');
                    },
                  ),

                  const SizedBox(height: 16),

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
        content: Text(
          '$feature - Requiere configuración de Backend (Firebase)',
        ),
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
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black, // Color del texto y efecto ripple
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(icon, color: iconColor, size: 24),
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 40), // Para equilibrar el icono visualmente
          ],
        ),
      ),
    );
  }
}
