import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame_audio/flame_audio.dart';
import '../expediente_game.dart';
import '../../game/audio_manager.dart';
import '../../narrative/screens/menu_screen.dart';
import '../models/player_role.dart';
import '../../combat/weapon_system.dart';

// Vector2
import 'dynamic_joystick_overlay.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Paleta de colores oscuros / cafÃ© (horror UX)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const _brown900 = Color(0xFF1A0F08);
const _brown700 = Color(0xFF3B1F10);
const _brown400 = Color(0xFF7B4A2A);
const _amber = Color(0xFFD4A96A);
const _greenDim = Color(0xFF4A7A5A);
const _redDim = Color(0xFF8B2020);
const _white60 = Color(0x99FFFFFF);

class GameUI extends StatefulWidget {
  final ExpedienteKorinGame game;
  const GameUI({super.key, required this.game});

  @override
  State<GameUI> createState() => _GameUIState();
}

class _GameUIState extends State<GameUI> with SingleTickerProviderStateMixin {
  bool _isConfigOpen = false;
  double _volume = 1.0;

  // Panel narrativo auto-ocultable
  bool _isNarrativeVisible = true;
  Timer? _narrativeTimer;

  // Hint de controles transitorio
  bool _isHintVisible = true;
  late AnimationController _hintFadeCtrl;
  late Animation<double> _hintFadeAnim;

  // Polling del HUD (salud, vidas, Mel)
  Timer? _hudPollTimer;

  @override
  void initState() {
    super.initState();

    widget.game.objectiveNotifier.addListener(_onObjectiveChanged);
    _scheduleNarrativeHide();

    _hintFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _hintFadeAnim =
        CurvedAnimation(parent: _hintFadeCtrl, curve: Curves.easeOut);
    _hintFadeCtrl.value = 1.0;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _hintFadeCtrl.reverse().then((_) {
          if (mounted) setState(() => _isHintVisible = false);
        });
      }
    });

    // Polling cada 100ms para actualizar HUD de salud/vidas
    _hudPollTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) widget.game.updateHUDNotifiers();
    });
  }

  void _onObjectiveChanged() {
    if (!mounted) return;
    setState(() => _isNarrativeVisible = true);
    _scheduleNarrativeHide();
  }

  void _scheduleNarrativeHide() {
    _narrativeTimer?.cancel();
    _narrativeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _isNarrativeVisible = false);
    });
  }

  @override
  void dispose() {
    _narrativeTimer?.cancel();
    _hudPollTimer?.cancel();
    _hintFadeCtrl.dispose();
    widget.game.objectiveNotifier.removeListener(_onObjectiveChanged);
    super.dispose();
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // â”€â”€ 1. JOYSTICK DINÃMICO â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        DynamicJoystickOverlay(
          onInput: (input) => widget.game.updateJoystickInput(input),
        ),

        // â”€â”€ 2. HUD SALUD + VIDAS (top-left) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Positioned(
          top: 12,
          left: 12,
          child: SafeArea(child: _buildHealthHUD()),
        ),

        // â”€â”€ 3. BOTÃ“N CONFIG (top-right) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Positioned(
          top: 12,
          right: 12,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => setState(() {
                _isConfigOpen = !_isConfigOpen;
                _isConfigOpen
                    ? widget.game.pauseEngine()
                    : widget.game.resumeEngine();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isConfigOpen ? 260 : 44,
                height: _isConfigOpen ? 320 : 44,
                padding: _isConfigOpen
                    ? const EdgeInsets.all(12)
                    : const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _brown900.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _brown400.withValues(alpha: 0.5), width: 1),
                ),
                child: _isConfigOpen
                    ? OverflowBox(
                        minWidth: 236,
                        maxWidth: 236,
                        minHeight: 296,
                        maxHeight: 296,
                        child: Material(
                          type: MaterialType.transparency,
                          child: _buildConfigPanel(),
                        ),
                      )
                    : const Icon(Icons.settings, color: _white60, size: 24),
              ),
            ),
          ),
        ),

        // â”€â”€ 4. PANEL NARRATIVO AUTO-OCULTABLE (top-right) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          top: 12,
          right: _isNarrativeVisible ? 68 : -280,
          child: SafeArea(
            child: GestureDetector(
              onTap: () {
                setState(() => _isNarrativeVisible = !_isNarrativeVisible);
                if (_isNarrativeVisible) _scheduleNarrativeHide();
              },
              child: Container(
                constraints: const BoxConstraints(maxWidth: 220),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _brown900.withValues(alpha: 0.7),
                  border: Border(
                    left: BorderSide(color: _greenDim.withValues(alpha: 0.8), width: 2),
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    bottomLeft: Radius.circular(5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<String>(
                      valueListenable: widget.game.chapterNameNotifier,
                      builder: (_, v, __) => Text(v.toUpperCase(),
                          style: const TextStyle(
                              color: _greenDim,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 1.1)),
                    ),
                    const SizedBox(height: 3),
                    ValueListenableBuilder<String>(
                      valueListenable: widget.game.locationNotifier,
                      builder: (_, v, __) => Text(v,
                          style: TextStyle(
                              color: _amber.withValues(alpha: 0.8),
                              fontSize: 10,
                              fontFamily: 'monospace')),
                    ),
                    const SizedBox(height: 2),
                    ValueListenableBuilder<String>(
                      valueListenable: widget.game.objectiveNotifier,
                      builder: (_, v, __) => Text('â–¸ $v',
                          style: TextStyle(
                              color: _white60.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontFamily: 'monospace')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Tab para re-abrir panel narrativo
        if (!_isNarrativeVisible)
          Positioned(
            top: 56,
            right: 0,
            child: SafeArea(
              child: GestureDetector(
                onTap: () {
                  setState(() => _isNarrativeVisible = true);
                  _scheduleNarrativeHide();
                },
                child: Container(
                  width: 20,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _brown900.withValues(alpha: 0.75),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      bottomLeft: Radius.circular(5),
                    ),
                    border: Border(
                      left: BorderSide(color: _greenDim.withValues(alpha: 0.5), width: 1),
                    ),
                  ),
                  child: const Icon(Icons.chevron_left, color: _greenDim, size: 14),
                ),
              ),
            ),
          ),

        // â”€â”€ 5. BOTONES DE ACCIÃ“N MÃ“VIL (bottom-right) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        _buildActionButtons(),

        // â”€â”€ 6. HINT DE CONTROLES TRANSITORIO â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (_isHintVisible &&
            Theme.of(context).platform != TargetPlatform.android &&
            Theme.of(context).platform != TargetPlatform.iOS)
          Positioned(
            bottom: 12,
            left: 12,
            child: SafeArea(
              child: FadeTransition(
                opacity: _hintFadeAnim,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: _brown900.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _brown400.withValues(alpha: 0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('WASD / Flechas: Mover',
                          style: TextStyle(
                              color: _white60, fontSize: 10, fontFamily: 'monospace')),
                      SizedBox(height: 2),
                      Text('E: Interactuar',
                          style: TextStyle(
                              color: _white60, fontSize: 10, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // â”€â”€ HUD: SALUD + VIDAS + MEL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildHealthHUD() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _brown900.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _brown400.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nombre del jugador
          ValueListenableBuilder<double>(
            valueListenable: widget.game.playerHealthNotifier,
            builder: (_, hp, __) {
              final maxHp = widget.game.playerMaxHealthNotifier.value;
              final pct = maxHp > 0 ? (hp / maxHp).clamp(0.0, 1.0) : 0.0;
              final barColor = pct > 0.5
                  ? _greenDim
                  : pct > 0.25
                      ? _amber
                      : _redDim;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DAN',
                      style: TextStyle(
                          color: _white60,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace')),
                  const SizedBox(height: 3),
                  _buildBar(pct, barColor, 160, 10),
                  const SizedBox(height: 2),
                  Text('${hp.toInt()} / ${maxHp.toInt()}',
                      style: const TextStyle(
                          color: _white60, fontSize: 9, fontFamily: 'monospace')),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          // Mel cooldown
          ValueListenableBuilder<bool>(
            valueListenable: widget.game.melReadyNotifier,
            builder: (_, ready, __) {
              return ValueListenableBuilder<double>(
                valueListenable: widget.game.melCooldownNotifier,
                builder: (_, progress, __) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        ready ? 'MEL â€” LISTO (E)' : 'MEL â€” RECARGANDO ${(progress * 100).toInt()}%',
                        style: TextStyle(
                            color: ready ? _greenDim : _amber,
                            fontSize: 9,
                            fontFamily: 'monospace')),
                    if (!ready) ...[
                      const SizedBox(height: 2),
                      _buildBar(progress, _amber, 160, 6),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          // Vidas
          ValueListenableBuilder<int>(
            valueListenable: widget.game.livesNotifier,
            builder: (_, lives, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('â™¥ ',
                    style: TextStyle(
                        color: _redDim, fontSize: 12, fontFamily: 'monospace')),
                ...List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Icon(
                      i < lives ? Icons.favorite : Icons.favorite_border,
                      color: i < lives ? _redDim : _brown400,
                      size: 14,
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

  Widget _buildBar(double pct, Color color, double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _brown700,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
          FractionallySizedBox(
            widthFactor: pct,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ BOTONES DE ACCIÃ“N (Flutter, encima del flashlight) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildActionButtons() {
    final game = widget.game;
    final isDan = game.player.playerRole == PlayerRole.dan;

    return Positioned(
      bottom: 20,
      right: 20,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Fila 1: Acciones secundarias
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // [Dan] Cambiar arma Q  |  [Mel] Resurrect E
                if (isDan)
                  _actionBtn(
                    label: 'Q',
                    color: _brown700,
                    onTap: () => game.player.weaponInventory.nextWeapon(),
                  )
                else
                  _actionBtn(
                    label: 'E',
                    color: const Color(0xFF2A1A3A),
                    onTap: () => game.player.tryResurrect(),
                  ),
                const SizedBox(width: 8),
                // BotÃ³n de curaciÃ³n de Mel (dinÃ¡mico segÃºn cooldown)
                _buildMelHealButton(game, isDan),
                const SizedBox(width: 8),
                // [Dan] Recarga R (solo con pistola)  |  [Mel] Dash â€ºâ€º
                isDan
                    ? ValueListenableBuilder<bool>(
                        valueListenable: game.isRangedWeaponNotifier,
                        builder: (_, isRanged, __) {
                          return isRanged
                              ? _actionBtn(
                                  label: 'R',
                                  color: const Color(0xFF2A1A0A),
                                  onTap: () {
                                    final ww = game.player.weaponInventory.currentWeapon;
                                    if (ww is RangedWeapon) ww.reload();
                                  },
                                )
                              : const SizedBox(width: 52);
                        },
                      )
                    : _actionBtn(
                        label: 'â€ºâ€º',
                        color: const Color(0xFF0A1A2A),
                        onTap: () => game.player.tryDash(),
                      ),
              ],
            ),
            const SizedBox(height: 10),
            // Fila 2: Ataque principal
            _actionBtn(
              label: 'âš¡',
              color: _redDim,
              size: 72,
              onTap: () => game.player.attack(),
            ),
          ],
        ),
      ),
    );
  }

  /// BotÃ³n de curaciÃ³n de Mel â€” cambia de color segÃºn disponibilidad
  Widget _buildMelHealButton(ExpedienteKorinGame game, bool isDan) {
    return ValueListenableBuilder<bool>(
      valueListenable: game.melReadyNotifier,
      builder: (_, ready, __) {
        return ValueListenableBuilder<double>(
          valueListenable: game.melCooldownNotifier,
          builder: (_, progress, __) {
            final btnColor = ready ? _greenDim : _brown700;
            final label = isDan ? 'MEL\nâ™¥' : 'CURAR\nâ™¥';

            return GestureDetector(
              onTapDown: (_) => game.mel.activateHeal(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Fondo con cooldown visual (arco)
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      value: ready ? 1.0 : progress,
                      strokeWidth: 3,
                      backgroundColor: _brown700,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ready ? _greenDim : _amber,
                      ),
                    ),
                  ),
                  // BotÃ³n principal
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: btnColor.withValues(alpha: ready ? 0.75 : 0.45),
                      border: Border.all(
                        color: ready
                            ? _greenDim.withValues(alpha: 0.8)
                            : _white60.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                      boxShadow: ready
                          ? [
                              BoxShadow(
                                color: _greenDim.withValues(alpha: 0.35),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ready ? _white60 : _white60.withValues(alpha: 0.4),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _actionBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
    double size = 52,
  }) {
    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.55),
          border: Border.all(color: _white60.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: _white60,
              fontSize: size * 0.3,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  // â”€â”€ PANEL DE CONFIGURACIÃ“N â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildConfigPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('SISTEMA',
                style: TextStyle(
                    color: _amber,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1.4)),
            GestureDetector(
              onTap: () => setState(() {
                _isConfigOpen = false;
                widget.game.resumeEngine();
              }),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _brown400.withValues(alpha: 0.5))),
                child: const Icon(Icons.close, color: _white60, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Divider(color: _brown400.withValues(alpha: 0.4), height: 1),
        const SizedBox(height: 16),
        _configSlider('MÃšSICA', _volume, (v) {
          setState(() {
            _volume = v;
            AudioManager().musicVolume = v;
            FlameAudio.bgm.audioPlayer.setVolume(v);
          });
        }),
        const SizedBox(height: 12),
        _configSlider('EFECTOS', AudioManager().sfxVolume, (v) {
          setState(() => AudioManager().sfxVolume = v);
        }),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: ElevatedButton(
            onPressed: _confirmExit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _redDim.withValues(alpha: 0.3),
              foregroundColor: const Color(0xFFE07070),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: _redDim),
              ),
              elevation: 0,
            ),
            child: const Text('SALIR AL MENÃš',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          ),
        ),
      ],
    );
  }

  Widget _configSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: _white60, fontSize: 11, fontFamily: 'monospace')),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _amber,
            inactiveTrackColor: _brown700,
            thumbColor: _amber,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: SizedBox(
            height: 28,
            child: Slider(value: value, onChanged: onChanged),
          ),
        ),
      ],
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _brown900.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _brown400.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Â¿ABORTAR MISIÃ“N?',
                  style: TextStyle(
                      color: Color(0xFFE07070),
                      fontSize: 16,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('El progreso no guardado se perderÃ¡.',
                  style: TextStyle(
                      color: _white60, fontSize: 12, fontFamily: 'monospace'),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('CANCELAR',
                        style: TextStyle(color: _white60, fontSize: 11)),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const MenuScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _redDim,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('CONFIRMAR', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

