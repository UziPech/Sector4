import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../../game/models/player_role.dart';
import '../../game/expediente_game.dart';
import '../../game/ui/game_over_with_advice.dart';
import '../models/dialogue_data.dart';
import '../components/dialogue_system.dart';
import '../../game/ui/game_ui.dart';

/// Pantalla de selección de rol (Dan vs Mel)
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

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
              // Título
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'SELECCIÓN DE OPERADOR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¿Quién toma el punto?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
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
              
              // Botón confirmar
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
                                color: Colors.red.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                          ),
                          child: const Text(
                            'CONFIRMAR SELECCIÓN',
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

    // Guardar selección
    RoleSelection.selectRole(_selectedRole!);

    // Mostrar diálogo post-selección
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
              text: 'Te cubro desde atrás. No dejes que te rodeen.',
              avatarPath: 'assets/avatars/mel.png',
              type: DialogueType.normal,
            ),
          ]
        : const [
            DialogueData(
              speakerName: 'Mel',
              text: 'Está bien. Puedo hacer esto. Siento cada latido, cada movimiento. Estoy lista.',
              avatarPath: 'assets/avatars/mel.png',
              type: DialogueType.normal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Ella es más fuerte de lo que cree. Más fuerte de lo que yo jamás fui. Quizás la Caída eligió a la persona correcta.',
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
            color: Colors.black.withOpacity(0.7),
            border: Border.all(
              color: isSelected
                  ? (isDan ? Colors.green : Colors.cyan)
                  : Colors.white.withOpacity(0.3),
              width: isSelected ? 3 : 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (isDan ? Colors.green : Colors.cyan)
                          .withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
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
                isDan ? 'OPERADOR TÁCTICO' : 'PORTADORA DE LA CAÍDA',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontFamily: 'monospace',
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),
              
              // Descripción
              Text(
                isDan
                    ? 'Entrenamiento militar. Armas convencionales. Sin margen de error.'
                    : 'Mutación controlada. Regeneración. Dominio sobre la vida y la muerte.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
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
                  color: Colors.black.withOpacity(0.5),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
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
                  color: Colors.black.withOpacity(0.3),
                  border: Border.all(
                    color: (isDan ? Colors.green : Colors.cyan)
                        .withOpacity(0.3),
                  ),
                ),
                child: Text(
                  isDan
                      ? '"El peso del metal. El olor de la pólvora. Esto es lo que conozco. Esto es lo que soy. Un soldado sin guerra, un fantasma con un propósito."'
                      : '"Siento el pulso de la Caída en mis venas. No es una maldición. Es una herramienta. Y voy a usarla para proteger lo que queda."',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
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

/// Widget para mostrar una fila de estadística
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
            color: Colors.white.withOpacity(0.6),
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
