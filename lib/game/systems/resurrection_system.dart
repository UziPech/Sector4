import 'package:flame/components.dart';
import '../models/player_role.dart';

/// Sistema de gestión de resurrecciones para Mel
class ResurrectionManager extends Component {
  int activeAllies = 0;
  int maxActiveAllies = 2;
  
  /// Verifica si aún se pueden hacer resurrecciones (regulares, 1 slot)
  bool canResurrect() => activeAllies < maxActiveAllies;
  
  /// Verifica si se pueden hacer resurrecciones de Kijin (requiere 2 slots)
  bool canResurrectKijin() => (maxActiveAllies - activeAllies) >= 2;
  
  /// Obtiene el número de resurrecciones restantes
  int get resurrectionsRemaining => maxActiveAllies - activeAllies;
  
  /// Registra un nuevo aliado activo (1 slot)
  void registerAlly() {
    if (activeAllies < maxActiveAllies) {
      activeAllies++;
      print('ResurrectionManager: Aliado registrado. Slots usados: $activeAllies/$maxActiveAllies');
    }
  }
  
  /// Registra un aliado Kijin (2 slots)
  void registerKijinAlly() {
    if ((maxActiveAllies - activeAllies) >= 2) {
      activeAllies += 2;
      print('ResurrectionManager: Kijin registrado. Slots usados: $activeAllies/$maxActiveAllies');
    }
  }
  
  /// Libera un slot cuando un aliado muere o expira
  void unregisterAlly() {
    if (activeAllies > 0) {
      activeAllies--;
      print('ResurrectionManager: Aliado liberado. Slots usados: $activeAllies/$maxActiveAllies');
    }
  }
  
  /// Libera 2 slots cuando un Kijin muere
  void unregisterKijinAlly() {
    if (activeAllies >= 2) {
      activeAllies -= 2;
    } else {
      activeAllies = 0;
    }
    print('ResurrectionManager: Kijin liberado. Slots usados: $activeAllies/$maxActiveAllies');
  }
  
  /// Reinicia el contador (para nuevo capítulo)
  void reset() {
    activeAllies = 0;
  }
  
  /// Configura el máximo de aliados activos según el rol
  void configure(PlayerRole role) {
    final stats = RoleSelection.getStats(role);
    maxActiveAllies = stats.maxResurrections;
    activeAllies = 0 ;
  }
}

