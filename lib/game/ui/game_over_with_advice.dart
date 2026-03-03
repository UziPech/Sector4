import 'package:flutter/material.dart';
import '../expediente_game.dart';
import '../models/player_role.dart';

/// Overlay de Game Over con consejos personalizados de Mel
class GameOverWithAdvice extends StatefulWidget {
  final ExpedienteKorinGame game;

  const GameOverWithAdvice({
    super.key,
    required this.game,
  });

  @override
  State<GameOverWithAdvice> createState() => _GameOverWithAdviceState();
}

class _GameOverWithAdviceState extends State<GameOverWithAdvice> {
  late String melQuote;
  late String melAdvice;
  
  // Mensajes de Mel con consejos segÃºn situaciones comunes
  final List<Map<String, String>> adviceList = [
    // Consejos del Stalker (boss original)
    {
      'quote': '"El Stalker es invencible hasta que destruyas su objeto obsesivo."',
      'tip': 'Busca los 7 objetos rojos en el bunker. Solo UNO de ellos es el real.'
    },
    {
      'quote': '"La embestida del Stalker es letal pero predecible."',
      'tip': 'Cuando veas que tiembla y se pone rojo, Â¡ESQUIVA! Te harÃ¡ 60 de daÃ±o.'
    },
    {
      'quote': '"El Stalker tiene una barra de estabilidad, no de vida."',
      'tip': 'DispÃ¡rale hasta que se canse y duerma. Usa ese tiempo para buscar objetos.'
    },
    // Consejos de Yurei Kohaa (nuevo boss Kijin)
    {
      'quote': '"Yurei Kohaa es un Kijin. Su dolor la hace peligrosa."',
      'tip': 'Tiene 3000 HP y es RÃPIDA (velocidad 150). MantÃ©n la distancia y dispara.'
    },
    {
      'quote': '"Cuando Kohaa se vuelve amarilla, va a embestir."',
      'tip': 'Â¡ESQUIVA SU DASH! Tiene cooldown de 4 segundos. Ãšsalo para atacar.'
    },
    {
      'quote': '"Kohaa invoca enfermeros cuando estÃ¡ herida."',
      'tip': 'Al 60% HP, spawnea 2 enfermeros. MÃ¡talos rÃ¡pido o te flanquearÃ¡n.'
    },
    {
      'quote': '"Â¡CUIDADO! Kohaa usa explosiÃ³n defensiva al 30% HP."',
      'tip': 'Cuando estÃ© baja, hace EXPLOSIÃ“N (40 daÃ±o, te empuja) y se cura 100 HP. Â¡AlÃ©jate!'
    },
    {
      'quote': '"Los Kijin pueden ser redimidos despuÃ©s de morir."',
      'tip': 'Si eres Mel, puedes resucitar su tumba ROJA (cuesta 2 slots). SerÃ¡ aliada.'
    },
    {
      'quote': '"Kohaa hace 25 de daÃ±o por golpe, no te rodees."',
      'tip': 'Usa el cuchillo en cuerpo a cuerpo (100 daÃ±o) o pistola a distancia (20 daÃ±o).'
    },
    // Consejos generales
    {
      'quote': '"Recuerda: tienes dos armas a tu disposiciÃ³n."',
      'tip': 'Presiona Q para cambiar entre Cuchillo (âˆž) y Pistola (20 balas). Recarga con R.'
    },
    {
      'quote': '"El cuchillo es devastador en cuerpo a cuerpo."',
      'tip': 'El cuchillo hace 100 de daÃ±o. Ãšsalo contra enemigos lentos o debilitados.'
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
      color: Colors.black.withValues(alpha: 0.95),
      child: Column(
        children: [
          // TÃ­tulo Game Over en la parte superior
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
                    'La CaÃ­da fue inevitable',
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
          
          // DiÃ¡logo de Mel en la parte inferior (estilo juego)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.90),
              border: Border.all(
                color: Colors.yellow.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
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
                    color: Colors.black.withValues(alpha: 0.3),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRect(
                    child: Builder(
                      builder: (context) {
                        // Mostrar el COMPAÃ‘ERO (no el jugador)
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
                
                // Contenido del diÃ¡logo
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
                            // Mostrar el COMPAÃ‘ERO (no el jugador)
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
                              'MENÃš PRINCIPAL',
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

