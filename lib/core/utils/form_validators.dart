/// Reglas compartidas entre ficha maestra y recepción de lotes.
String? requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'Este campo es obligatorio.' : null;

String? positiveInteger(String? value) {
  final number = int.tryParse(value?.trim() ?? '');
  return number == null || number <= 0
      ? 'Indica un entero mayor que cero.'
      : null;
}

String? nonNegativeInteger(String? value) {
  final number = int.tryParse(value?.trim() ?? '');
  return number == null || number < 0 ? 'Indica un entero desde cero.' : null;
}

double? parseAmount(String value) =>
    double.tryParse(value.trim().replaceAll(',', '.'));

String? positiveAmount(String? value) {
  final number = parseAmount(value ?? '');
  return number == null || !number.isFinite || number <= 0
      ? 'Indica un precio mayor que cero.'
      : null;
}

/// Rechaza fechas imposibles: DateTime.parse normaliza 2027-02-31 a marzo.
DateTime? parseCalendarDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;
  final year = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final day = int.parse(match[3]!);
  final date = DateTime(year, month, day);
  return date.year == year && date.month == month && date.day == day
      ? date
      : null;
}
