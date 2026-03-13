import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Paleta del juego ─────────────────────────────────────────────────────────
const _dark = Color(0xFF0D0D0D);
const _cardBg = Color(0xFF111111);
const _border = Color(0xFF2A2A2A);
const _danColor = Color(0xFF4A8FBB); // Azul acero
const _melColor = Color(0xFF9B59B6); // Púrpura
const _attackColor = Color(0xFF8B2020); // Rojo

class ControlsOverlay extends StatefulWidget {
  const ControlsOverlay({super.key});

  @override
  State<ControlsOverlay> createState() => _ControlsOverlayState();
}

class _ControlsOverlayState extends State<ControlsOverlay> {
  // 0 = General, 1 = Dan, 2 = Mel
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width > 700 ? 40 : 12,
        vertical: size.height > 600 ? 30 : 12,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 620),
        decoration: BoxDecoration(
          color: _dark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.9), blurRadius: 30),
          ],
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _buildHeader(context),

            // ── Tabs ────────────────────────────────────────────────────────
            _buildTabs(),

            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildTabContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Text('', style: TextStyle(color: _danColor, fontSize: 18)),
          const SizedBox(width: 10),
          Text(
            'INFORME DE SISTEMA  //  MANUAL DE OPERARIO',
            style: GoogleFonts.specialElite(
              color: Colors.white70,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.close, color: Colors.white38, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TABS ─────────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    final tabs = [
      ('GENERAL', Colors.white70),
      ('DAN', _danColor),
      ('MEL', _melColor),
    ];
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final i = e.key;
          final (label, color) = e.value;
          final active = _selectedTab == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? color : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.robotoMono(
                  color: active ? color : Colors.white24,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── TAB CONTENT ─────────────────────────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildGeneralTab();
      case 1:
        return _buildDanTab();
      case 2:
        return _buildMelTab();
      default:
        return const SizedBox();
    }
  }

  // ─── GENERAL TAB ─────────────────────────────────────────────────────────────
  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      key: const ValueKey('general'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('ESQUEMA DE CONTROLES — VISTA MÓVIL'),
          const SizedBox(height: 20),

          // Diagrama de pantalla
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Izquierda: Joystick ──────────────────────────────────────
              Expanded(child: _buildJoystickDiagram()),
              const SizedBox(width: 16),

              // ── Centro: Descripción ──────────────────────────────────────
              Column(
                children: [
                  Text(
                    '◄  TOQUE IZQUIERDO\n   MOVER PERSONAJE\n\n   TOQUE DERECHO  ►\n   ACCIONES / ATAQUE',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.robotoMono(
                      color: Colors.white30,
                      fontSize: 11,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // ── Derecha: Botones de acción ───────────────────────────────
              Expanded(child: _buildActionButtonsDiagram()),
            ],
          ),

          const SizedBox(height: 28),
          const Divider(color: _border),
          const SizedBox(height: 20),

          _sectionLabel('CONTROLES DE TECLADO (PC)'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _pcKey('W A S D', 'Mover'),
              _pcKey('FLECHAS', 'Mover (alt.)'),
              _pcKey('ESPACIO', 'Atacar'),
              _pcKey('Q', 'Cambiar arma'),
              _pcKey('R', 'Recargar'),
              _pcKey('E', 'Acción especial *'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '* La acción de [E] cambia según el rol activo (ver pestañas DAN / MEL)',
            style: GoogleFonts.robotoMono(color: Colors.white24, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ─── DAN TAB ──────────────────────────────────────────────────────────────────
  Widget _buildDanTab() {
    return SingleChildScrollView(
      key: const ValueKey('dan'),
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Botones mobile ────────────────────────────────────────────────
          Column(
            children: [
              _sectionLabel('CONTROLES MÓVIL', color: _danColor),
              const SizedBox(height: 16),
              _buildDanMobileLayout(),
            ],
          ),

          const SizedBox(width: 28),
          Container(width: 1, height: 320, color: _border),
          const SizedBox(width: 28),

          // ── Descripción y teclado ─────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('PERFIL: DAN', color: _danColor),
                const SizedBox(height: 12),
                Text(
                  'Unidad de Combate Principal.\nDependiente del arsenal. Supervivencia a través de la fuerza bruta y la precisión. Mel le da cobertura de curación.',
                  style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 12, height: 1.6),
                ),
                const SizedBox(height: 20),
                _sectionLabel('ARSENAL', color: _danColor),
                const SizedBox(height: 12),
                _weaponCard(
                  ' Cuchillo',
                  'Cuerpo a cuerpo. Sin límite de uso.\nDaño alto en rango cercano.',
                  Colors.white70,
                ),
                const SizedBox(height: 10),
                _weaponCard(
                  ' Pistola',
                  'A distancia. Requiere munición.\nRecargar con [R] o botón ♻.',
                  const Color(0xFF4A8FBB),
                ),
                const SizedBox(height: 20),
                _sectionLabel('TECLAS POR ACCIÓN', color: _danColor),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _pcKey('ESPACIO / ⚡', 'Atacar'),
                    _pcKey('Q', 'Cambiar arma'),
                    _pcKey('R / ♻', 'Recargar'),
                    _pcKey('E / MEL ♥', 'Pedir curación'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── MEL TAB ──────────────────────────────────────────────────────────────────
  Widget _buildMelTab() {
    return SingleChildScrollView(
      key: const ValueKey('mel'),
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Botones mobile ────────────────────────────────────────────────
          Column(
            children: [
              _sectionLabel('CONTROLES MÓVIL', color: _melColor),
              const SizedBox(height: 16),
              _buildMelMobileLayout(),
            ],
          ),

          const SizedBox(width: 28),
          Container(width: 1, height: 320, color: _border),
          const SizedBox(width: 28),

          // ── Descripción y habilidades ─────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('PERFIL: MEL', color: _melColor),
                const SizedBox(height: 12),
                Text(
                  'Ancla del Mundo. Soporte Vital.\nConexión mística con los caídos. Regeneración pasiva, curación activa y capaz de resucitar enemigos como aliados.',
                  style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 12, height: 1.6),
                ),
                const SizedBox(height: 20),
                _sectionLabel('HABILIDADES ESPECIALES', color: _melColor),
                const SizedBox(height: 12),
                _abilityCard(
                  '♥ CURACIÓN PROPIA',
                  '[F] / Botón MEL ♥ — Canaliza energía para restaurar su propia salud. Tiene cooldown.',
                  _melColor,
                ),
                const SizedBox(height: 10),
                _abilityCard(
                  '✦ RESURRECCIÓN',
                  '[E] — Cerca de una tumba enemiga transforma al caído en aliado temporal (45s) o Kijin Redimido (permanente).',
                  Colors.green,
                ),
                const SizedBox(height: 10),
                _abilityCard(
                  '>> DASH OSCURO',
                  '[SHIFT] — Velocidad extrema compartida con el Kijin. Solo disponible si hay un Kijin aliado vivo.',
                  Colors.cyan,
                ),
                const SizedBox(height: 20),
                _sectionLabel('TECLAS POR ACCIÓN', color: _melColor),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _pcKey('ESPACIO / ⚡', 'Atacar'),
                    _pcKey('F / MEL ♥', 'Curación propia'),
                    _pcKey('E', 'Resurrect enemigo'),
                    _pcKey('SHIFT / >>', 'Dash del Kijin'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── DIAGRAMA JOYSTICK ────────────────────────────────────────────────────────
  Widget _buildJoystickDiagram() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Base exterior
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
              ),
            ),
            // Knob interior
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.7),
                boxShadow: [
                  BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 10),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'JOYSTICK DINÁMICO\nToca y arrastra',
          textAlign: TextAlign.center,
          style: GoogleFonts.robotoMono(color: Colors.white30, fontSize: 10, height: 1.5),
        ),
      ],
    );
  }

  // ─── BOTONES ACCIÓN: DAN ──────────────────────────────────────────────────────
  Widget _buildDanMobileLayout() {
    return Column(
      children: [
        // Fila superior: Q, MEL♥, R
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _mobileBtn('Q', 'Arma', const Color(0xFF3B1F10)),
            const SizedBox(width: 10),
            _mobileBtn('MEL\n♥', 'Curar', const Color(0xFF2A4A2A), circular: true, ringReady: true),
            const SizedBox(width: 10),
            _mobileBtn('♻', 'Recargar', const Color(0xFF2A1A0A)),
          ],
        ),
        const SizedBox(height: 10),
        // Ataque grande
        _mobileBtn('⚡', 'ATACAR', _attackColor, size: 72),
      ],
    );
  }

  // ─── BOTONES ACCIÓN: MEL ──────────────────────────────────────────────────────
  Widget _buildMelMobileLayout() {
    return Column(
      children: [
        // Fila superior: E (resurrect), MEL♥, >> (dash)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _mobileBtn('E', 'Resurrect', const Color(0xFF1A2A1A)),
            const SizedBox(width: 10),
            _mobileBtn('MEL\n♥', 'Curar', const Color(0xFF2A1A3A), circular: true, ringReady: true),
            const SizedBox(width: 10),
            _mobileBtn('>>', 'Dash', const Color(0xFF0A1A2A)),
          ],
        ),
        const SizedBox(height: 10),
        // Ataque grande
        _mobileBtn('⚡', 'ATACAR', _attackColor, size: 72),
      ],
    );
  }

  // ─── DIAGRAMA BOTÓN DE ACCIÓN GENERAL ─────────────────────────────────────────
  Widget _buildActionButtonsDiagram() {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _mobileBtn('?', 'Acción 1', const Color(0xFF3B1F10)),
            const SizedBox(width: 8),
            _mobileBtn('♥', 'Curar', const Color(0xFF2A4A2A), circular: true),
            const SizedBox(width: 8),
            _mobileBtn('?', 'Acción 2', const Color(0xFF0A1A2A)),
          ],
        ),
        const SizedBox(height: 8),
        _mobileBtn('⚡', 'ATACAR', _attackColor, size: 64),
        const SizedBox(height: 10),
        Text(
          'BOTONES DERECHA\n(Según Rol)',
          textAlign: TextAlign.center,
          style: GoogleFonts.robotoMono(color: Colors.white30, fontSize: 10, height: 1.5),
        ),
      ],
    );
  }

  // ─── MOBILE BUTTON WIDGET ────────────────────────────────────────────────────
  Widget _mobileBtn(String label, String hint, Color color, {double size = 52, bool circular = false, bool ringReady = false}) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (circular) ...[
              SizedBox(
                width: size + 6,
                height: size + 6,
                child: CircularProgressIndicator(
                  value: ringReady ? 1.0 : 0.6,
                  strokeWidth: 3,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ringReady ? const Color(0xFF4A7A5A) : const Color(0xFFD4A96A),
                  ),
                ),
              ),
            ],
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.6),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8),
                ],
              ),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: size * 0.28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(hint, style: GoogleFonts.robotoMono(color: Colors.white24, fontSize: 10)),
      ],
    );
  }

  // ─── PC KEY CHIP ──────────────────────────────────────────────────────────────
  Widget _pcKey(String key, String desc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[ $key ]',
            style: GoogleFonts.robotoMono(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Text(
            desc,
            style: GoogleFonts.robotoMono(color: Colors.white30, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ─── WEAPON CARD ──────────────────────────────────────────────────────────────
  Widget _weaponCard(String name, String desc, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border(left: BorderSide(color: accent, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: GoogleFonts.robotoMono(color: accent, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(desc, style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 11, height: 1.5)),
        ],
      ),
    );
  }

  // ─── ABILITY CARD ─────────────────────────────────────────────────────────────
  Widget _abilityCard(String name, String desc, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border(left: BorderSide(color: accent, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: GoogleFonts.robotoMono(color: accent, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(desc, style: GoogleFonts.robotoMono(color: Colors.white38, fontSize: 11, height: 1.5)),
        ],
      ),
    );
  }

  // ─── SECTION LABEL ────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, {Color color = Colors.white60}) {
    return Text(
      text,
      style: GoogleFonts.specialElite(
        color: color,
        fontSize: 13,
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
