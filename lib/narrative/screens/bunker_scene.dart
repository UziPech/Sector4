import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dialogue_data.dart';
import '../components/dialogue_system.dart';
import '../components/skip_button.dart';
import '../services/save_system.dart';
import '../../main.dart';

/// Capítulo 2: La Semilla y el Sector 4
/// Ubicación: Búnker subterráneo, Osaka, Japón
class BunkerScene extends StatefulWidget {
  const BunkerScene({Key? key}) : super(key: key);

  @override
  State<BunkerScene> createState() => _BunkerSceneState();
}

class _BunkerSceneState extends State<BunkerScene> {
  bool _monologueCompleted = false;
  bool _melDialogueCompleted = false;
  bool _isDialogueActive = false;

  @override
  void initState() {
    super.initState();
    _showTransitMonologue();
  }

  void _showTransitMonologue() {
    // Mostrar monólogo de Dan en tránsito
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isDialogueActive = true;
      });

      DialogueOverlay.show(
        context,
        DialogueSequence(
          id: 'transit_monologue',
          dialogues: const [
            DialogueData(
              speakerName: 'Dan',
              text: 'Marcus me lanzó a esto como un misil teledirigido.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'La universidad de Emma. Epicentro. Amenazas de Sector 4.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Si esta jerarquía me da la excusa para cruzar la zona de exclusión, la acepto.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Mi Caída ya no es mental; es literal. Un descenso a la podredumbre.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'Necesito ver a Mel. "Soporte Vital". Suena a kit de primeros auxilios con pulso.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'No hay espacio para sentimentalismos. Es mi seguro contra la corrupción.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'La misión es simple: infiltración, extracción, exfiltración.',
              type: DialogueType.internal,
            ),
            DialogueData(
              speakerName: 'Dan',
              text: 'El resto es ruido.',
              type: DialogueType.internal,
            ),
          ],
        ),
        onComplete: () {
          setState(() {
            _monologueCompleted = true;
            _isDialogueActive = false;
          });
        },
      );
    });
  }

  void _startMelDialogue() {
    setState(() {
      _isDialogueActive = true;
    });

    DialogueOverlay.show(
      context,
      DialogueSequence(
        id: 'mel_encounter',
        dialogues: const [
          DialogueData(
            speakerName: 'Dan',
            text: '¿Mel? Keller.',
            avatarPath: 'assets/avatars/dan.png',
          ),
          DialogueData(
            speakerName: 'Mel',
            text: 'Lo sé. El ex-investigador que voló doce horas para convertirse en un padre desesperado.',
            avatarPath: 'assets/avatars/mel.png',
          ),
          DialogueData(
            speakerName: 'Mel',
            text: 'Un perfil que el Sector 4 ama.',
            avatarPath: 'assets/avatars/mel.png',
          ),
          DialogueData(
            speakerName: 'Dan',
            text: 'Marcus dijo que eres Soporte Vital. ¿Qué significa en campo?',
            avatarPath: 'assets/avatars/dan.png',
          ),
          DialogueData(
            speakerName: 'Mel',
            text: 'Significa que soy el ancla.',
            avatarPath: 'assets/avatars/mel.png',
          ),
          DialogueData(
            speakerName: 'Mel',
            text: 'Aquí no cazamos básicos de Sector 2, los que atacan por puro instinto.',
            avatarPath: 'assets/avatars/mel.png',
          ),
          DialogueData(
            speakerName: 'Mel',
            text: 'Aquí enfrentamos Amenazas de Sector 4. Kijin. Cazadores tácticos.',
            avatarPath: 'assets/avatars/mel.png',
          ),
          DialogueData(
            speakerName: 'Mel',
            text: 'Piensan. Priorizan objetivos. Flanquean. Se alimentan de la ira.',
            avatarPath: 'assets/avatars/mel.png',
          ),
          DialogueData(
            speakerName: 'Dan',
            text: 'Lo sé. Marcus me lo explicó.',
            avatarPath: 'assets/avatars/dan.png',
          ),
          DialogueData(
            speakerName: 'Mel',
            text: 'No todo.',
            avatarPath: 'assets/avatars/mel.png',
          ),
          DialogueData(
            speakerName: 'Mel',
            text: 'Si te superan, si la desesperación te rompe, no solo detengo sangrados.',
            avatarPath: 'assets/avatars/mel.png',
          ),
          DialogueData(
            speakerName: 'Mel',
            text: 'Te afirmo a la vida. Te devuelvo al foco cuando el cuerpo cede.',
            avatarPath: 'assets/avatars/mel.png',
          ),
          DialogueData(
            speakerName: 'Dan',
            text: 'Recuperación. Lo entiendo.',
            avatarPath: 'assets/avatars/dan.png',
          ),
          DialogueData(
            speakerName: 'Mel',
            text: 'Es más que eso. Y no es infinito.',
            avatarPath: 'assets/avatars/mel.png',
          ),
          DialogueData(
            speakerName: 'Dan',
            text: '¿Recurso?',
            avatarPath: 'assets/avatars/dan.png',
          ),
          DialogueData(
            speakerName: 'Mel',
            text: 'Tengo una ventana de recarga. Si me fuerzas sin cabeza, me pedirás cuando aún no esté lista.',
            avatarPath: 'assets/avatars/mel.png',
          ),
          DialogueData(
            speakerName: 'Mel',
            text: 'Y entonces mueres.',
            avatarPath: 'assets/avatars/mel.png',
          ),
          DialogueData(
            speakerName: 'Dan',
            text: 'Gestión de recursos. Sinergia. Entendido.',
            avatarPath: 'assets/avatars/dan.png',
          ),
          DialogueData(
            speakerName: 'Dan',
            text: '¿Protocolo de inserción?',
            avatarPath: 'assets/avatars/dan.png',
          ),
          DialogueData(
            speakerName: 'Mel',
            text: 'Entramos por túneles de mantenimiento, periferia de la universidad.',
            avatarPath: 'assets/avatars/mel.png',
          ),
          DialogueData(
            speakerName: 'Mel',
            text: 'Evitamos Resonantes de Sector 3. No son nuestro objetivo.',
            avatarPath: 'assets/avatars/mel.png',
          ),
          DialogueData(
            speakerName: 'Dan',
            text: 'Los rompecabezas. Los obsesivos.',
            avatarPath: 'assets/avatars/dan.png',
          ),
          DialogueData(
            speakerName: 'Mel',
            text: 'Exacto. Hoy no hay tiempo para su pena ni sus cultos.',
            avatarPath: 'assets/avatars/mel.png',
          ),
          DialogueData(
            speakerName: 'Mel',
            text: 'Solo hay una prioridad: tu hija.',
            avatarPath: 'assets/avatars/mel.png',
          ),
          DialogueData(
            speakerName: 'Mel',
            text: 'El Sector 4 sostiene la línea contra los cazadores; salimos con vida.',
            avatarPath: 'assets/avatars/mel.png',
          ),
          DialogueData(
            speakerName: 'Dan',
            text: 'Perfecto. Dame las coordenadas.',
            avatarPath: 'assets/avatars/dan.png',
          ),
          DialogueData(
            speakerName: 'Mel',
            text: 'Canal activo. El Expediente Kōrin está abierto, Dan.',
            avatarPath: 'assets/avatars/mel.png',
          ),
          DialogueData(
            speakerName: 'Mel',
            text: 'Desde ahora, seremos tú, tu caída… y yo evitando que toques fondo.',
            avatarPath: 'assets/avatars/mel.png',
          ),
        ],
      ),
      onComplete: () {
        setState(() {
          _melDialogueCompleted = true;
          _isDialogueActive = false;
        });
        // Transición al juego de combate después de un delay
        Future.delayed(const Duration(seconds: 2), () {
          _transitionToCombat();
        });
      },
    );
  }

  void _transitionToCombat() async {
    // Marcar capítulo 2 como completado
    await SaveSystem.markChapterCompleted(2);
    
    // Transición a la escena de combate
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MyApp(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      body: Stack(
        children: [
          // Fondo del búnker
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2a2a2a),
                  const Color(0xFF1a1a1a),
                ],
              ),
            ),
          ),
          // Layout del búnker
          CustomPaint(
            painter: _BunkerLayoutPainter(),
            size: Size.infinite,
          ),
          // Personajes
          if (_monologueCompleted && !_isDialogueActive)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Dan
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.7),
                      border: Border.all(color: Colors.white, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Mel - Área clickeable completa
                  GestureDetector(
                    onTap: !_melDialogueCompleted ? _startMelDialogue : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.7),
                            border: Border.all(
                              color: !_melDialogueCompleted
                                  ? Colors.yellow
                                  : Colors.white,
                              width: !_melDialogueCompleted ? 3 : 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        if (!_melDialogueCompleted)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.yellow, width: 2),
                              ),
                              child: const Text(
                                'Click para hablar',
                                style: TextStyle(
                                  color: Colors.yellow,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // HUD
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CAPÍTULO 2: LA SEMILLA Y EL SECTOR 4',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _melDialogueCompleted
                        ? 'Objetivo: Prepararse para la inserción'
                        : _monologueCompleted
                            ? 'Objetivo: Hablar con Mel'
                            : 'Llegando al búnker...',
                    style: TextStyle(
                      color: Colors.yellow[700],
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Botón de skip
          const SkipButton(chapterNumber: 2),
          // Ubicación
          Positioned(
            top: 60,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Text(
                'BÚNKER SUBTERRÁNEO\nOSAKA, JAPÓN',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter para el layout del búnker (placeholder visual)
class _BunkerLayoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 2;

    // Sala principal (centro)
    final mainRoom = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 400,
      height: 300,
    );
    canvas.drawRect(mainRoom, paint);

    // Pasillo superior
    final corridor = Rect.fromLTWH(
      size.width / 2 - 50,
      size.height / 2 - 300,
      100,
      150,
    );
    canvas.drawRect(corridor, paint);

    // Etiqueta "SALA DE EQUIPOS"
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'SALA DE EQUIPOS',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textPainter.width / 2,
        size.height / 2 - 170,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
