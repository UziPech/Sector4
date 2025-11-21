import 'package:flutter/material.dart';
import '../expediente_game.dart';
import '../models/player_role.dart';

/// Overlay de Game Over con consejos personalizados de Mel
class GameOverWithAdvice extends StatefulWidget {
  final ExpedienteKorinGame game;

  const GameOverWithAdvice({
    Key? key,
    required this.game,
  }) : super(key: key);

  @override
  State<GameOverWithAdvice> createState() => _GameOverWithAdviceState();
}

class _GameOverWithAdviceState extends State<GameOverWithAdvice> {
  late String melQuote;
  late String melAdvice;
  
  // Mensajes de Mel con consejos según situaciones comunes
  final List<Map<String, String>> adviceList = [
    // Consejos del Stalker (boss original)
    {
      'quote': '"El Stalker es invencible hasta que destruyas su objeto obsesivo."',
      'tip': 'Busca los 7 objetos rojos en el bunker. Solo UNO de ellos es el real.'
    },
    {
      'quote': '"La embestida del Stalker es letal pero predecible."',
      'tip': 'Cuando veas que tiembla y se pone rojo, ¡ESQUIVA! Te hará 60 de daño.'
    },
    {
      'quote': '"El Stalker tiene una barra de estabilidad, no de vida."',
      'tip': 'Dispárale hasta que se canse y duerma. Usa ese tiempo para buscar objetos.'
    },
    // Consejos de Yurei Kohaa (nuevo boss Kijin)
    {
      'quote': '"Yurei Kohaa es un Kijin. Su dolor la hace peligrosa."',
      'tip': 'Tiene 3000 HP y es RÁPIDA (velocidad 150). Mantén la distancia y dispara.'
    },
    {
      'quote': '"Cuando Kohaa se vuelve amarilla, va a embestir."',
      'tip': '¡ESQUIVA SU DASH! Tiene cooldown de 4 segundos. Úsalo para atacar.'
    },
    {
      'quote': '"Kohaa invoca enfermeros cuando está herida."',
      'tip': 'Al 60% HP, spawnea 2 enfermeros. Mátalos rápido o te flanquearán.'
    },
    {
      'quote': '"¡CUIDADO! Kohaa usa explosión defensiva al 30% HP."',
      'tip': 'Cuando esté baja, hace EXPLOSIÓN (40 daño, te empuja) y se cura 100 HP. ¡Aléjate!'
    },
    {
      'quote': '"Los Kijin pueden ser redimidos después de morir."',
      'tip': 'Si eres Mel, puedes resucitar su tumba ROJA (cuesta 2 slots). Será aliada.'
    },
    {
      'quote': '"Kohaa hace 25 de daño por golpe, no te rodees."',
      'tip': 'Usa el cuchillo en cuerpo a cuerpo (100 daño) o pistola a distancia (20 daño).'
    },
    // Consejos generales
    {
      'quote': '"Recuerda: tienes dos armas a tu disposición."',
      'tip': 'Presiona Q para cambiar entre Cuchillo (∞) y Pistola (20 balas). Recarga con R.'
    },
    {
      'quote': '"El cuchillo es devastador en cuerpo a cuerpo."',
      'tip': 'El cuchillo hace 100 de daño. Úsalo contra enemigos lentos o debilitados.'
    },
  ];
  
  @override
  void initState() {
    super.initState();
    // Seleccionar consejo aleatorio
    final random = adviceList[DateTime.now().millisecond % adviceList.length];
    melQuote = random['quote']!;
    melAdvice = random['tip']!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.95),
      child: Column(
        children: [
          // Título Game Over en la parte superior
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'GAME OVER',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'La Caída fue inevitable',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 24,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Diálogo de Mel en la parte inferior (estilo juego)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.90),
              border: Border.all(
                color: Colors.yellow.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar de Mel (imagen)
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRect(
                    child: Builder(
                      builder: (context) {
                        // Mostrar el COMPAÑERO (no el jugador)
                        // Si jugador es Dan, mostrar Mel. Si es Mel, mostrar Dan.
                        final isDan = widget.game.player.role == PlayerRole.dan;
                        final companionAvatar = isDan
                            ? 'assets/avatars/dialogue_icons/Mel_Dialogue.png'
                            : 'assets/avatars/dialogue_icons/Dan_Dialogue.png';
                        return Image.asset(
                          companionAvatar,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                
                // Contenido del diálogo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nombre
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Builder(
                          builder: (context) {
                            // Mostrar el COMPAÑERO (no el jugador)
                            final isDan = widget.game.player.role == PlayerRole.dan;
                            final companionName = isDan ? 'Mel' : 'Dan';
                            return Text(
                              companionName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Quote
                      Text(
                        melQuote,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'monospace',
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 12),
                      
                      // Consejo con icono
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.yellow, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              melAdvice,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Botones
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[700],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'MENÚ PRINCIPAL',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              widget.game.restart();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 36,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'REINTENTAR',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
