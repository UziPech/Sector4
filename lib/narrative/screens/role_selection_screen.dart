import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../../game/models/player_role.dart';
import '../../game/expediente_game.dart';
import '../../game/ui/game_over_with_advice.dart';
import '../models/dialogue_data.dart';
import '../components/dialogue_system.dart';
import '../../game/ui/game_ui.dart';

/// Pantalla de selecciÃ³n de rol (Dan vs Mel)
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  PlayerRole? _selectedRole;
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Colors.black,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // TÃ­tulo
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'SELECCIÃ“N DE OPERADOR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: Colors.red.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Â¿QuiÃ©n toma el punto?',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tarjetas
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tarjeta Dan
                          Expanded(
                            child: _RoleCard(
                              role: PlayerRole.dan,
                              isSelected: _selectedRole == PlayerRole.dan,
                              onTap: () => _selectRole(PlayerRole.dan),
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Tarjeta Mel
                          Expanded(
                            child: _RoleCard(
                              role: PlayerRole.mel,
                              isSelected: _selectedRole == PlayerRole.mel,
                              onTap: () => _selectRole(PlayerRole.mel),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // BotÃ³n confirmar
              if (_selectedRole != null)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _isConfirming
                      ? const CircularProgressIndicator(color: Colors.white)
                      : ElevatedButton(
                          onPressed: _confirmSelection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[900],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: BorderSide(
                                color: Colors.red.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                          ),
                          child: const Text(
                            'CONFIRMAR SELECCIÃ“N',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 2,
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

  void _selectRole(PlayerRole role) {
    setState(() {
      _selectedRole = role;
    });
  }

  void _confirmSelection() {
    if (_selectedRole == null) return;

    setState(() {
      _isConfirming = true;
    });

    // Guardar selecciÃ³n
    RoleSelection.selectRole(_selectedRole!);

    // Mostrar diÃ¡logo post-selecciÃ³n
    _showPostSelectionDialogue();
  }

  void _showPostSelectionDialogue() {
    final dialogues = _selectedRole == PlayerRole.dan
        ? const [
            DialogueData(
              speakerName: 'Dan',
              text: 'Viejo y confiable. Las armas nunca me han fallado. Bueno... casi nunca.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Mel',
              text: 'Te cubro desde atrÃ¡s. No dejes que te rodeen.',
              avatarPath: 'assets/avatars/mel.png',
              type: DialogueType.normal,
            ),
          ]
        : const [
            DialogueData(
              speakerName: 'Mel',
              text: 'EstÃ¡ bien. Puedo hacer esto. Siento cada latido, cada movimiento. Estoy lista.',
              avatarPath: 'assets/avatars/mel.png',
              type: DialogueType.normal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Ella es mÃ¡s fuerte de lo que cree. MÃ¡s fuerte de lo que yo jamÃ¡s fui. QuizÃ¡s la CaÃ­da eligiÃ³ a la persona correcta.',
              type: DialogueType.internal,
            ),
          ];

    DialogueOverlay.show(
      context,
      DialogueSequence(
        id: 'post_selection',
        dialogues: dialogues,
        onComplete: () {
          // Transicionar al mapa exterior
          _transitionToExteriorMap();
        },
      ),
    );
  }

  void _transitionToExteriorMap() {
    // Navegar al mapa exterior con el rol seleccionado
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GameWidget(
          game: ExpedienteKorinGame(
            selectedRole: _selectedRole,
            startInExteriorMap: true,
          ),
          overlayBuilderMap: {
            'GameOver': (context, game) => GameOverWithAdvice(
              game: game as ExpedienteKorinGame,
            ),
            'DialogueOverlay': (context, game) {
              final korinGame = game as ExpedienteKorinGame;
              if (korinGame.currentDialogue == null) return const SizedBox.shrink();
              
              return DialogueSystem(
                sequence: korinGame.currentDialogue!,
                onSequenceComplete: korinGame.onDialogueComplete,
              );
            },
            'GameUI': (context, game) => GameUI(game: game as ExpedienteKorinGame),
          },
          initialActiveOverlays: const ['GameUI'],
        ),
      ),
    );
  }
}

/// Widget de tarjeta de rol
class _RoleCard extends StatelessWidget {
  final PlayerRole role;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stats = RoleSelection.getStats(role);
    final isDan = role == PlayerRole.dan;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            border: Border.all(
              color: isSelected
                  ? (isDan ? Colors.green : Colors.cyan)
                  : Colors.white.withValues(alpha: 0.3),
              width: isSelected ? 3 : 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (isDan ? Colors.green : Colors.cyan)
                          .withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TÃ­tulo
              Text(
                isDan ? 'DAN' : 'MEL',
                style: TextStyle(
                  color: isDan ? Colors.green : Colors.cyan,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isDan ? 'OPERADOR TÃCTICO' : 'PORTADORA DE LA CAÃDA',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontFamily: 'monospace',
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),
              
              // DescripciÃ³n
              Text(
                isDan
                    ? 'Entrenamiento militar. Armas convencionales. Sin margen de error.'
                    : 'MutaciÃ³n controlada. RegeneraciÃ³n. Dominio sobre la vida y la muerte.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatRow(
                      label: 'HP',
                      value: stats.maxHealth.toInt().toString(),
                    ),
                    if (stats.hasRegeneration) ...[
                      const SizedBox(height: 8),
                      _StatRow(
                        label: 'REGEN',
                        value: '+${stats.regenerationAmount.toInt()}/s',
                      ),
                    ],
                    const SizedBox(height: 8),
                    _StatRow(
                      label: 'VELOCIDAD',
                      value: stats.speed.toInt().toString(),
                    ),
                    if (stats.hasWeapons) ...[
                      const SizedBox(height: 8),
                      _StatRow(
                        label: 'ARMAS',
                        value: 'Cuchillo, Pistola',
                      ),
                    ],
                    if (stats.hasMutantHand) ...[
                      const SizedBox(height: 8),
                      _StatRow(
                        label: 'ARMA',
                        value: 'Mano Mutante',
                      ),
                    ],
                    if (stats.maxResurrections > 0) ...[
                      const SizedBox(height: 8),
                      _StatRow(
                        label: 'REVIVIR',
                        value: '${stats.maxResurrections}x',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Texto narrativo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  border: Border.all(
                    color: (isDan ? Colors.green : Colors.cyan)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  isDan
                      ? '"El peso del metal. El olor de la pÃ³lvora. Esto es lo que conozco. Esto es lo que soy. Un soldado sin guerra, un fantasma con un propÃ³sito."'
                      : '"Siento el pulso de la CaÃ­da en mis venas. No es una maldiciÃ³n. Es una herramienta. Y voy a usarla para proteger lo que queda."',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'monospace',
                    height: 1.4,
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

/// Widget para mostrar una fila de estadÃ­stica
class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

