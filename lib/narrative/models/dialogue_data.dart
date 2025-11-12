/// Modelo de datos para un diálogo individual
class DialogueData {
  final String speakerName;
  final String text;
  final String? avatarPath; // null = sin avatar (monólogo interno)
  final DialogueType type;
  final bool canSkip;
  final Duration? autoAdvanceDelay; // null = requiere input del jugador

  const DialogueData({
    required this.speakerName,
    required this.text,
    this.avatarPath,
    this.type = DialogueType.normal,
    this.canSkip = true,
    this.autoAdvanceDelay,
  });
}

/// Tipos de diálogo para diferentes estilos visuales
enum DialogueType {
  normal, // Diálogo estándar
  internal, // Monólogo interno (cursiva, sin avatar)
  phone, // Llamada telefónica (efecto especial)
  system, // Mensaje del sistema/radio
  thought, // Pensamiento rápido
}

/// Secuencia completa de diálogos
class DialogueSequence {
  final String id;
  final List<DialogueData> dialogues;
  final VoidCallback? onComplete;

  const DialogueSequence({
    required this.id,
    required this.dialogues,
    this.onComplete,
  });
}

/// Callback type para cuando termina un diálogo
typedef VoidCallback = void Function();
