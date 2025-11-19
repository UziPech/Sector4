import 'package:flutter/material.dart';
import 'house_scene.dart';
import 'bunker_scene.dart';
import 'story_screen.dart';

/// Pantalla del menú principal
class MenuScreen extends StatelessWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.grey[900]!,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Efecto de viñeta
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
              // Contenido principal centrado
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: size.width * 0.8,
                    maxHeight: size.height * 0.85,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 1000,
                      height: 600,
                      child: Row(
                        children: [
                      // Lado izquierdo: Título y descripción
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EXPEDIENTE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                letterSpacing: 6,
                                height: 1.0,
                              ),
                            ),
                            const Text(
                              'KŌRIN',
                              style: TextStyle(
                                color: Colors.yellow,
                                fontSize: 52,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                letterSpacing: 8,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: 200,
                              height: 2,
                              color: Colors.yellow,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Una Caída a los\ndeseos Humanos',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'monospace',
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'v0.1.0 - Capítulo 1',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                      // Lado derecho: Botones del menú
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _MenuButton(
                              text: 'NUEVO JUEGO',
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => const HouseScene(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 12),
                            _MenuButton(
                              text: 'CONTINUAR',
                              onPressed: null,
                              isDisabled: true,
                            ),
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 12),
                            _MenuButton(
                              text: 'SALIR',
                              onPressed: () {
                                // En producción, cerrar la app
                                // SystemNavigator.pop();
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget de botón del menú
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

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isDisabled;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: _isHovered && isEnabled
                ? Colors.yellow.withOpacity(0.15)
                : Colors.transparent,
            border: Border.all(
              color: isEnabled
                  ? (_isHovered ? Colors.yellow : Colors.white.withOpacity(0.6))
                  : Colors.grey[800]!,
              width: 1.5,
            ),
          ),
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isEnabled
                  ? (_isHovered ? Colors.yellow : Colors.white)
                  : Colors.grey[700],
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
