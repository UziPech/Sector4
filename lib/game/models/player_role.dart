/// Roles disponibles para el jugador
enum PlayerRole {
  dan,
  mel,
}

/// Servicio singleton para gestionar la selección de rol
class RoleSelection {
  static PlayerRole? _selectedRole;
  
  /// Obtiene el rol actualmente seleccionado
  static PlayerRole get currentRole => _selectedRole ?? PlayerRole.dan;
  
  /// Verifica si hay un rol seleccionado
  static bool get hasSelection => _selectedRole != null;
  
  /// Selecciona un rol
  static void selectRole(PlayerRole role) {
    _selectedRole = role;
  }
  
  /// Reinicia la selección (útil para testing o new game)
  static void reset() {
    _selectedRole = null;
  }
  
  /// Obtiene las estadísticas base según el rol
  static RoleStats getStats(PlayerRole role) {
    switch (role) {
      case PlayerRole.dan:
        return RoleStats(
          maxHealth: 100.0,
          speed: 200.0,
          hasRegeneration: false,
          regenerationAmount: 0.0,
          regenerationInterval: 0.0,
          maxResurrections: 0,
          hasWeapons: true,
          hasMutantHand: false,
        );
      case PlayerRole.mel:
        return RoleStats(
          maxHealth: 200.0,
          speed: 200.0,
          hasRegeneration: true,
          regenerationAmount: 2.0,
          regenerationInterval: 2.0,
          maxResurrections: 2,
          hasWeapons: false,
          hasMutantHand: true,
        );
    }
  }
}

/// Estadísticas de un rol
class RoleStats {
  final double maxHealth;
  final double speed;
  final bool hasRegeneration;
  final double regenerationAmount;
  final double regenerationInterval;
  final int maxResurrections;
  final bool hasWeapons;
  final bool hasMutantHand;
  
  const RoleStats({
    required this.maxHealth,
    required this.speed,
    required this.hasRegeneration,
    required this.regenerationAmount,
    required this.regenerationInterval,
    required this.maxResurrections,
    required this.hasWeapons,
    required this.hasMutantHand,
  });
}
