import 'package:flame/components.dart';
import '../models/player_role.dart';

/// Sistema de gestión de resurrecciones para Mel
class ResurrectionManager extends Component {
  int resurrectionsUsed = 0;
  int maxResurrections = 2;
  
  /// Verifica si aún se pueden hacer resurrecciones
  bool canResurrect() => resurrectionsUsed < maxResurrections;
  
  /// Obtiene el número de resurrecciones restantes
  int get resurrectionsRemaining => maxResurrections - resurrectionsUsed;
  
  /// Consume una resurrección
  void useResurrection() {
    if (canResurrect()) {
      resurrectionsUsed++;
    }
  }
  
  /// Reinicia el contador (para nuevo capítulo)
  void reset() {
    resurrectionsUsed = 0;
  }
  
  /// Configura el máximo de resurrecciones según el rol
  void configure(PlayerRole role) {
    final stats = RoleSelection.getStats(role);
    maxResurrections = stats.maxResurrections;
    resurrectionsUsed = 0;
  }
}
