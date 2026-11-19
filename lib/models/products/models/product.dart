import '../../../core/utils/json_value.dart';
import '../../../core/utils/local_image_data.dart';
import 'product_classification.dart';
import 'product_illustration.dart';

/// Ficha maestra del catálogo: define QUÉ se vende, no CUÁNTO existe.
///
/// La presentación describe el envase; precio y stock usan la unidad mínima de venta.
/// La ficha puede crearse sin precio (0) y valorarse después de recibir el lote. Cantidades,
/// fechas de recepción y vencimientos pertenecen a InventoryLot (relación 1:N).
class Product {
  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.presentation,
    required this.unit,
    required this.minimum,
    required this.price,
    this.dosage = '',
    this.measurementUnit = '',
    this.origin = '',
    this.manufacturer = '',
    this.description = '',
    this.indications = '',
    this.contraindications = '',
    this.requiresPrescription = false,
    this.packageUnits = 1,
    this.activeIngredient = '',
    this.barcode = '',
    this.illustrationKey = '',
    this.photoData = '',
    this.active = true,
  });

  /// Identidad estable para relacionar lotes sin depender del nombre.
  final String id;
  final String code;
  final String name;
  final String category;
  final String activeIngredient;
  final String dosage, measurementUnit, origin, manufacturer, description;

  /// Campo histórico de respaldos. La recepción guarda el prospecto en la compra.
  final String indications;
  final String contraindications;
  final bool requiresPrescription;

  /// Unidades mínimas vendibles por envase; el saldo y los precios usan unit.
  final int packageUnits;
  final String presentation;
  final String unit;
  final String barcode;
  final bool active;

  /// Selección visual independiente del stock. Vacío significa «sin imagen».
  /// Es una clave del catálogo local, no una foto real ni una URL de terceros.
  final String illustrationKey;
  final String photoData;

  /// Cantidad mínima que dispara una alerta de reposición.
  final int minimum;

  /// Precio de UNA unidad de venta; no es un costo de adquisición del lote.
  final double price;

  Product withActive(bool value) => _copyWith(active: value);

  /// Repara solo la asociación visual, sin modificar ningún dato operativo.
  Product withIllustrationKey(String value) =>
      _copyWith(illustrationKey: value);

  Product withPrice(double value) => _copyWith(price: value);

  String classification(ProductClassification type) => switch (type) {
    ProductClassification.category => category,
    ProductClassification.presentation => presentation,
  };

  Product withClassification(ProductClassification type, String value) =>
      switch (type) {
        ProductClassification.category => _copyWith(category: value),
        ProductClassification.presentation => _copyWith(presentation: value),
      };

  Product _copyWith({
    bool? active,
    String? illustrationKey,
    double? price,
    String? category,
    String? presentation,
  }) => Product(
    id: id,
    code: code,
    name: name,
    category: category ?? this.category,
    presentation: presentation ?? this.presentation,
    unit: unit,
    minimum: minimum,
    price: price ?? this.price,
    dosage: dosage,
    measurementUnit: measurementUnit,
    origin: origin,
    manufacturer: manufacturer,
    description: description,
    indications: indications,
    contraindications: contraindications,
    requiresPrescription: requiresPrescription,
    packageUnits: packageUnits,
    activeIngredient: activeIngredient,
    barcode: barcode,
    illustrationKey: illustrationKey ?? this.illustrationKey,
    photoData: photoData,
    active: active ?? this.active,
  );
  Map<String, Object> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'category': category,
    'presentation': presentation,
    'unit': unit,
    'minimum': minimum,
    'price': price,
    'dosage': dosage,
    'measurementUnit': measurementUnit,
    'origin': origin,
    'manufacturer': manufacturer,
    'description': description,
    'indications': indications,
    'contraindications': contraindications,
    'requiresPrescription': requiresPrescription,
    'packageUnits': packageUnits,
    'activeIngredient': activeIngredient,
    'barcode': barcode,
    'illustrationKey': illustrationKey,
    if (photoData.isNotEmpty) 'photoData': photoData,
    'active': active,
  };
  factory Product.fromJson(JsonMap j) {
    final photoData = jsonText(j, 'photoData', fallback: '');
    if (photoData.isNotEmpty &&
        LocalImageKind.product.decode(photoData) == null) {
      throw const FormatException('La foto de un producto no es válida.');
    }
    return Product(
      id: jsonText(j, 'id'),
      code: jsonText(j, 'code'),
      name: jsonText(j, 'name'),
      category: jsonText(j, 'category'),
      presentation: jsonText(j, 'presentation'),
      unit: jsonText(j, 'unit'),
      minimum: jsonInteger(j, 'minimum'),
      price: jsonNumber(j, 'price'),
      dosage: jsonText(j, 'dosage', fallback: ''),
      measurementUnit: jsonText(j, 'measurementUnit', fallback: ''),
      origin: jsonText(j, 'origin', fallback: ''),
      manufacturer: jsonText(j, 'manufacturer', fallback: ''),
      description: jsonText(j, 'description', fallback: ''),
      indications: jsonText(j, 'indications', fallback: ''),
      contraindications: jsonText(j, 'contraindications', fallback: ''),
      requiresPrescription: jsonBool(
        j,
        'requiresPrescription',
        fallback: false,
      ),
      packageUnits: jsonInteger(j, 'packageUnits', fallback: 1),
      activeIngredient: jsonText(j, 'activeIngredient'),
      barcode: jsonText(j, 'barcode'),
      active: jsonBool(j, 'active'),
      photoData: photoData,
      illustrationKey: j.containsKey('illustrationKey')
          ? jsonText(j, 'illustrationKey')
          : ProductIllustrations.legacyKey(
              id: jsonText(j, 'id'),
              code: jsonText(j, 'code'),
              name: jsonText(j, 'name'),
              presentation: jsonText(j, 'presentation'),
            ),
    );
  }
}
