import '../../../core/utils/json_value.dart';

/// Relación N:M: una ficha puede comprarse a varios proveedores. No contiene
/// existencias; el código comercial y el costo son referencias para la compra.
class ProductSupplier {
  const ProductSupplier({
    required this.productId,
    required this.supplierId,
    this.supplierCode = '',
    this.referenceCost = 0,
    this.leadDays = 0,
    this.active = true,
  });
  final String productId, supplierId, supplierCode;
  final double referenceCost;
  final int leadDays;
  final bool active;
  Map<String, Object> toJson() => {
    'productId': productId,
    'supplierId': supplierId,
    'supplierCode': supplierCode,
    'referenceCost': referenceCost,
    'leadDays': leadDays,
    'active': active,
  };
  factory ProductSupplier.fromJson(JsonMap j) => ProductSupplier(
    productId: jsonText(j, 'productId'),
    supplierId: jsonText(j, 'supplierId'),
    supplierCode: jsonText(j, 'supplierCode', fallback: ''),
    referenceCost: jsonNumber(j, 'referenceCost', fallback: 0),
    leadDays: jsonInteger(j, 'leadDays', fallback: 0),
    active: jsonBool(j, 'active', fallback: true),
  );
}
