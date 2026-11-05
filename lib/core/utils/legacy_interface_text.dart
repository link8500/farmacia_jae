import 'json_value.dart';

/// Compatibilidad de textos de interfaz guardados por versiones anteriores.
/// Solo transforma campos de lectura: no toca IDs, códigos, imágenes, correos
/// ni relaciones entre facturas, compras, lotes y personas.
String cleanLegacyInterfaceText(String value) {
  if (value == 'Proveedor de demostración') return 'Proveedor general';
  if (value == 'Cliente de demostración') return 'Cliente general';
  final cleaned = value
      .replaceAll(
        RegExp(r'\s*[·|—]\s*(?:demostraci[oó]n|demo)\b', caseSensitive: false),
        '',
      )
      .replaceAll(
        RegExp(r'\b(?:de\s+)?demostraci[oó]n\b', caseSensitive: false),
        '',
      )
      .replaceAllMapped(RegExp(r' +([.,;:])'), (m) => m[1]!)
      .replaceAll(RegExp(r' {2,}'), ' ')
      .trim();
  return cleaned.isEmpty && value.trim().isNotEmpty ? 'Sin detalle' : cleaned;
}

JsonMap cleanLegacyInterfaceDocument(JsonMap document) {
  const fields = {
    'name',
    'title',
    'description',
    'badge',
    'conditions',
    'reason',
    'detail',
    'action',
    'address',
    'supplierName',
    'customerName',
    'actorName',
    'branchName',
    'registerName',
    'jobTitle',
  };
  Object? visit(Object? value) {
    if (value is Map<String, dynamic>) {
      return value.map(
        (key, item) => MapEntry(
          key,
          item is String && fields.contains(key)
              ? cleanLegacyInterfaceText(item)
              : visit(item),
        ),
      );
    }
    if (value is List) return value.map(visit).toList();
    return value;
  }

  return visit(document) as JsonMap;
}
