// Método de explosión táctica para Kohaa aliada
// Este código debe ser insertado en redeemed_kijin_ally.dart después del método _tryAttack()

/// Explosión táctica - Habilidad especial de Kohaa aliada
void _tryTacticalExplosion() {
  // Buscar al boss
  final bosses = game.world.children.query<OnOyabunBoss>();
  
  for (final boss in bosses) {
    if (boss.isDead) continue;
    
    final distanceToBoss = position.distanceTo(boss.position);
    
    // Solo explotar si el boss está cerca
    if (distanceToBoss <= _tacticalExplosionRadius) {
      _executeTacticalExplosion(boss);
      break;
    }
  }
}

/// Ejecuta la explosión táctica
void _executeTacticalExplosion(OnOyabunBoss boss) {
  print('💥🔥 ¡KOHAA ALIADA USA EXPLOSIÓN TÁCTICA!');
  
  // Daño al boss
  boss.takeDamage(_tacticalExplosionDamage);
  print('   💥 Boss recibe ${_tacticalExplosionDamage.toInt()} daño de la explosión!');
  
  // Empujar al boss ligeramente
  final pushDirection = (boss.position - position).normalized();
  boss.position += pushDirection * 50; // Pequeño empuje
  
  // Cooldown
  _tacticalExplosionTimer = _tacticalExplosionCooldown;
  
  // Efecto visual (círculo de explosión)
  _createExplosionEffect();
}

/// Crea efecto visual de la explosión
void _createExplosionEffect() {
  // Aquí puedes agregar un componente visual si lo deseas
  // Por ahora solo el mensaje de debug
  print('   🌟 Onda expansiva de ${_tacticalExplosionRadius.toInt()} unidades');
}
