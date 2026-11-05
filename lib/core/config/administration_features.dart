/// Interruptores temporales del prototipo, separados de los permisos del usuario.
abstract final class AdministrationFeatures {
  // Las cajas de facturación por sucursal son otro dominio y están disponibles
  // independientemente de este interruptor del antiguo control de efectivo.
  /// Caja queda suspendida: facturación registra comprobantes y descuenta lotes
  /// sin apertura, arqueos o movimientos de efectivo. Conservar false no borra
  /// el historial. Reactivar exige revisar primero los turnos antiguos.
  static const cashEnabled = false;
}
