import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isGlitching = false;
  Timer? _glitchTimer;

  @override
  void initState() {
    super.initState();
    
    // Iniciar el efecto de glitch
    _startGlitchEffect();

    // Navegar al menú después de 4 segundos
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MenuScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    });
  }

  void _startGlitchEffect() {
    _glitchTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (mounted) {
        setState(() {
          _isGlitching = !_isGlitching;
        });
      }
    });
  }

  @override
  void dispose() {
    _glitchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO / NOMBRE DEL ESTUDIO
            VHSGlitchTitle(
              text: 'UZIEL GAMES',
              fontSize: 48,
              isGlitching: _isGlitching,
            ),
            
            const SizedBox(height: 20),
            
            // SUBTÍTULO TECH
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              curve: Curves.easeIn,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Text(
                    'POWERED BY FLUTTER',
                    style: GoogleFonts.robotoMono(
                      color: Colors.blueGrey,
                      fontSize: 12,
                      letterSpacing: 4.0,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
