/// Convierte una fecha a un formato corto para tablas y alertas.
String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

/// Formatea un importe en córdobas nicaragüenses.
String formatCordobas(double amount) {
  return 'C\$ ${amount.toStringAsFixed(2)}';
}
