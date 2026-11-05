/// Lectura estricta de respaldos locales: falla antes de reemplazar datos.
typedef JsonMap = Map<String, dynamic>;
JsonMap jsonObject(Object? value) {
  if (value is! JsonMap) throw const FormatException('Se esperaba un objeto.');
  return value;
}

String jsonText(JsonMap json, String key, {String? fallback}) {
  final value = json[key] ?? fallback;
  if (value is! String) throw FormatException('Texto inválido: $key');
  return value;
}

double jsonNumber(JsonMap json, String key, {double? fallback}) {
  final value = json[key] ?? fallback;
  if (value is! num || !value.isFinite) {
    throw FormatException('Número inválido: $key');
  }
  return value.toDouble();
}

int jsonInteger(JsonMap json, String key, {int? fallback}) {
  final value = json[key] ?? fallback;
  if (value is! int) throw FormatException('Entero inválido: $key');
  return value;
}

bool jsonBool(JsonMap json, String key, {bool? fallback}) {
  final value = json[key] ?? fallback;
  if (value is! bool) throw FormatException('Estado inválido: $key');
  return value;
}

DateTime jsonDate(JsonMap json, String key) {
  final raw = jsonText(json, key);
  final calendar = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})',
  ).firstMatch(raw);
  if (calendar == null) {
    throw FormatException('Formato de fecha inválido: $key');
  }
  final parts = [for (var i = 1; i <= 6; i++) int.parse(calendar[i]!)];
  final day = DateTime(parts[0], parts[1], parts[2]);
  if (day.year != parts[0] ||
      day.month != parts[1] ||
      day.day != parts[2] ||
      parts[3] > 23 ||
      parts[4] > 59 ||
      parts[5] > 59) {
    throw FormatException('Fecha imposible: $key');
  }
  final result = DateTime.tryParse(raw);
  if (result == null) throw FormatException('Fecha inválida: $key');
  return result;
}

List<T> jsonList<T>(JsonMap json, String key, T Function(JsonMap) parse) {
  final value = json[key];
  if (value is! List || value.length > 50000) {
    throw FormatException('Lista inválida: $key');
  }
  return value.map((item) => parse(jsonObject(item))).toList();
}

T jsonEnum<T extends Enum>(JsonMap json, String key, List<T> values) =>
    values.firstWhere(
      (value) => value.name == jsonText(json, key),
      orElse: () => throw FormatException('Opción inválida: $key'),
    );

/// Todos los importes se redondean a centavos en los límites del dominio.
double money(double value) => (value * 100).round() / 100;
