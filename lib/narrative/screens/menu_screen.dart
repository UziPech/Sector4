import 'package:flutter/material.dart';
import 'house_scene.dart';
import 'bunker_scene.dart';
import 'story_screen.dart';

/// Pantalla del menú principal
class MenuScreen extends StatelessWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Título del juego
                const Text(
                  'EXPEDIENTE KŌRIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'El Legado del Ángel Caído',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 80),
                // Opciones del menú
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
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                _MenuButton(
                  text: 'CONTINUAR',
                  onPressed: null, // TODO: Implementar sistema de guardado
                  isDisabled: true,
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  text: 'OPCIONES',
                  onPressed: () {
                    // TODO: Implementar pantalla de opciones
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opciones - Próximamente'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  text: 'SALIR',
                  onPressed: () {
                    // En producción, cerrar la app
                    // SystemNavigator.pop();
                  },
                ),
                const SizedBox(height: 60),
                // Versión
                Text(
                  'v0.1.0 - Capítulo 1',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
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
          width: 300,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: _isHovered && isEnabled
                ? Colors.white.withOpacity(0.1)
                : Colors.transparent,
            border: Border.all(
              color: isEnabled
                  ? (_isHovered ? Colors.yellow : Colors.white)
                  : Colors.grey[700]!,
              width: 2,
            ),
          ),
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isEnabled
                  ? (_isHovered ? Colors.yellow : Colors.white)
                  : Colors.grey[700],
              fontSize: 20,
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
