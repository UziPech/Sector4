import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/audio_service.dart';

class LoginFormScreen extends StatefulWidget {
  final bool isRegister;
  
  const LoginFormScreen({
    super.key,
    this.isRegister = false,
  });

  @override
  State<LoginFormScreen> createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends State<LoginFormScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final AudioService _audioService = AudioService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = !kIsWeb && size.width < 600;
    
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con imagen
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
          
          // Capa oscura
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
          
          // Contenido
          SafeArea(
            child: Column(
              children: [
                // Botón volver
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.red.withValues(alpha: 0.9),
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
                
                // Formulario centrado
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24 : 40,
                      ),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        padding: EdgeInsets.all(isMobile ? 24 : 40),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo o título
                            Text(
                              'EXPEDIENTE KŌRIN',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.specialElite(
                                color: Colors.red.withValues(alpha: 0.9),
                                fontSize: isMobile ? 20 : 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Subtítulo
                            Text(
                              widget.isRegister 
                                  ? 'CREAR NUEVA CUENTA'
                                  : 'ACCESO AL SISTEMA',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: isMobile ? 12 : 14,
                                fontFamily: 'monospace',
                                letterSpacing: 2,
                              ),
                            ),
                            
                            SizedBox(height: isMobile ? 32 : 40),
                            
                            // Campo Username (solo registro)
                            if (widget.isRegister) ...[
                              _buildTextField(
                                controller: _usernameController,
                                label: 'NOMBRE DE USUARIO',
                                hint: 'tu_usuario',
                                icon: Icons.person_outline,
                                isMobile: isMobile,
                              ),
                              const SizedBox(height: 20),
                            ],
                            
                            // Campo Email
                            _buildTextField(
                              controller: _emailController,
                              label: 'CORREO ELECTRÓNICO',
                              hint: 'tu@email.com',
                              icon: Icons.email_outlined,
                              isMobile: isMobile,
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Campo Password
                            _buildTextField(
                              controller: _passwordController,
                              label: 'CONTRASEÑA',
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                              isPassword: true,
                              isPasswordVisible: _isPasswordVisible,
                              isMobile: isMobile,
                              onTogglePassword: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Campo Confirmar Password (solo registro)
                            if (widget.isRegister) ...[
                              _buildTextField(
                                controller: _confirmPasswordController,
                                label: 'CONFIRMAR CONTRASEÑA',
                                hint: '••••••••',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                isPasswordVisible: _isConfirmPasswordVisible,
                                isMobile: isMobile,
                                onTogglePassword: () {
                                  setState(() {
                                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                            
                            // Olvidaste contraseña (solo login)
                            if (!widget.isRegister)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // TODO: Recuperar contraseña
                                  },
                                  child: Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: TextStyle(
                                      color: Colors.red.withValues(alpha: 0.8),
                                      fontSize: isMobile ? 12 : 13,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                            
                            SizedBox(height: isMobile ? 24 : 32),
                            
                            // Botón principal
                            _buildMainButton(
                              text: widget.isRegister ? 'CREAR CUENTA' : 'INICIAR SESIÓN',
                              isMobile: isMobile,
                              onPressed: () {
                                // TODO: Implementar autenticación
                                Navigator.of(context).pop();
                              },
                            ),
                            
                            // Divider y redes sociales (solo login)
                            if (!widget.isRegister) ...[
                              SizedBox(height: isMobile ? 24 : 32),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'O CONTINÚA CON',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: isMobile ? 10 : 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: isMobile ? 20 : 24),
                              
                              // Botones sociales
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSocialButton(
                                      icon: Icons.g_mobiledata,
                                      label: 'Google',
                                      isMobile: isMobile,
                                      onPressed: () {
                                        // TODO: Google login
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildSocialButton(
                                      icon: Icons.facebook,
                                      label: 'Facebook',
                                      isMobile: isMobile,
                                      onPressed: () {
                                        // TODO: Facebook login
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            
                            SizedBox(height: isMobile ? 24 : 32),
                            
                            // Link a registro/login
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.isRegister 
                                      ? '¿Ya tienes cuenta? '
                                      : '¿No tienes cuenta? ',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: isMobile ? 13 : 14,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => LoginFormScreen(
                                          isRegister: !widget.isRegister,
                                        ),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    widget.isRegister ? 'Inicia sesión' : 'Regístrate',
                                    style: TextStyle(
                                      color: Colors.red.withValues(alpha: 0.9),
                                      fontSize: isMobile ? 13 : 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isMobile,
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
            fontSize: isMobile ? 11 : 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && !isPasswordVisible,
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 14 : 15,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: isMobile ? 14 : 15,
              fontFamily: 'monospace',
            ),
            prefixIcon: Icon(
              icon,
              color: Colors.red.withValues(alpha: 0.6),
              size: isMobile ? 20 : 22,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: isMobile ? 20 : 22,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: Colors.red.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: Colors.red.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: Colors.red.withValues(alpha: 0.8),
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 14 : 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton({
    required String text,
    required bool isMobile,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.withValues(alpha: 0.2),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: Colors.red.withValues(alpha: 0.8),
            width: 2,
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isMobile ? 14 : 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required bool isMobile,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: Colors.white,
        size: isMobile ? 20 : 22,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: isMobile ? 12 : 13,
          fontFamily: 'monospace',
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
