/// CSV compatible con hojas de cálculo. Las cadenas que podrían convertirse
/// en fórmulas se neutralizan; los números permanecen números.
String buildCsv(List<String> headers, List<List<Object?>> rows) {
  String cell(Object? value) {
    var text = value?.toString() ?? '';
    if (value is! num && RegExp(r'^[\s]*[=+@-]').hasMatch(text)) {
      text = "'$text";
    }
    return '"${text.replaceAll('"', '""')}"';
  }

  return '\uFEFF${[headers, ...rows].map((row) => row.map(cell).join(',')).join('\r\n')}';
}
