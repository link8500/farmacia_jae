/// Recurso visual local, separado de precios, lotes y existencias.
/// Todas las entradas son envases ficticios generados para la demostración.
class ProductIllustration {
  const ProductIllustration({
    required this.key,
    required this.productId,
    required this.code,
    required this.name,
    required this.presentation,
  });

  final String key, productId, code, name, presentation;
  String get assetPath => 'images/products/$key.png';
}

/// Lista permitida de imágenes: sin URLs externas, claves API ni peticiones web.
abstract final class ProductIllustrations {
  static const values = <ProductIllustration>[
    ProductIllustration(
      key: 'paracetamol',
      productId: 'prd-001',
      code: 'MED-001',
      name: 'Paracetamol 500 mg',
      presentation: 'Caja de 10 tabletas',
    ),
    ProductIllustration(
      key: 'amoxicilina',
      productId: 'prd-002',
      code: 'MED-002',
      name: 'Amoxicilina 500 mg',
      presentation: 'Caja de 10 cápsulas',
    ),
    ProductIllustration(
      key: 'loratadina',
      productId: 'prd-003',
      code: 'MED-003',
      name: 'Loratadina 10 mg',
      presentation: 'Caja de 10 tabletas',
    ),
    ProductIllustration(
      key: 'ibuprofeno',
      productId: 'prd-004',
      code: 'MED-004',
      name: 'Ibuprofeno 400 mg',
      presentation: 'Caja de 10 tabletas',
    ),
    ProductIllustration(
      key: 'omeprazol',
      productId: 'prd-005',
      code: 'MED-005',
      name: 'Omeprazol 20 mg',
      presentation: 'Caja de 10 cápsulas',
    ),
    ProductIllustration(
      key: 'alcohol',
      productId: 'prd-006',
      code: 'MED-006',
      name: 'Alcohol medicinal 120 ml',
      presentation: 'Frasco de 120 ml',
    ),
    ProductIllustration(
      key: 'vitamina-c',
      productId: 'prd-007',
      code: 'MED-007',
      name: 'Vitamina C 1 g',
      presentation: 'Tubo de 10 tabletas',
    ),
    ProductIllustration(
      key: 'losartan',
      productId: 'prd-008',
      code: 'MED-008',
      name: 'Losartán 50 mg',
      presentation: 'Caja de 30 tabletas',
    ),
  ];

  static ProductIllustration? find(String key) {
    for (final image in values) {
      if (image.key == key) return image;
    }
    return null;
  }

  /// Compatibilidad con respaldos anteriores: reconoce únicamente las fichas
  /// demo originales, nunca asigna una foto por coincidencia parcial del nombre.
  /// Las primeras fichas usaban «Caja», «Frasco» o «Tubo» como presentación;
  /// exigir la descripción ampliada dejaba esos registros antiguos sin imagen.
  static String legacyKey({
    required String id,
    required String code,
    required String name,
    required String presentation,
  }) {
    final package = presentation.trim().toLowerCase();
    for (final image in values) {
      if (image.productId == id &&
          image.code == code &&
          image.name == name &&
          (image.presentation.toLowerCase() == package ||
              image.presentation.split(' ').first.toLowerCase() == package)) {
        return image.key;
      }
    }
    return '';
  }
}
