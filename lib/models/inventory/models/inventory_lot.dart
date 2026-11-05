import '../../../core/utils/json_value.dart';
import '../../organization/models/organization.dart';

/// Existencias de un producto registrado, identificadas por lote y vencimiento.
///
/// El código viene del fabricante: nunca se genera ni se deducen fechas de él.
/// quantity usa la unidad mínima de venta del producto; no
/// mezcla cajas y tabletas. No se duplica la ficha maestra en cada recepción.
class InventoryLot {
  const InventoryLot({
    required this.id,
    required this.productId,
    required this.code,
    required this.quantity,
    required this.expiry,
    required this.receivedAt,
    this.supplierId = '',
    this.manufacturedAt,
    this.location = '',
    this.unitCost = 0,
    this.branchId = mainBranchId,
  });

  final String id;
  final String productId;
  final String branchId;
  final String code;
  final String supplierId, location;
  final DateTime? manufacturedAt;
  final int quantity;
  final DateTime expiry;
  final DateTime receivedAt;
  final double unitCost;

  /// Corrige la documentación física sin cambiar identidad, saldo, fechas de
  /// recepción/vencimiento ni costo. La validación corresponde al controlador.
  InventoryLot withMetadata({
    required String supplierId,
    required DateTime manufacturedAt,
    required String location,
  }) => InventoryLot(
    id: id,
    productId: productId,
    branchId: branchId,
    code: code,
    quantity: quantity,
    expiry: expiry,
    receivedAt: receivedAt,
    unitCost: unitCost,
    supplierId: supplierId,
    manufacturedAt: manufacturedAt,
    location: location,
  );

  /// Se compara por día: el lote vence al terminar la fecha indicada.
  bool isExpired(DateTime today) => dayOnly(expiry).isBefore(dayOnly(today));

  /// Solo lotes con saldo, no vencidos, generan la alerta de próximos 90 días.
  bool isExpiring(DateTime today) =>
      quantity > 0 &&
      !isExpired(today) &&
      !dayOnly(expiry).isAfter(dayOnly(today).add(const Duration(days: 90)));

  /// Mantiene los demás datos inmutables al descontar unidades de una venta.
  InventoryLot withQuantity(int value) => InventoryLot(
    id: id,
    productId: productId,
    branchId: branchId,
    code: code,
    quantity: value,
    expiry: expiry,
    receivedAt: receivedAt,
    unitCost: unitCost,
    supplierId: supplierId,
    manufacturedAt: manufacturedAt,
    location: location,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'productId': productId,
    'branchId': branchId,
    'code': code,
    'quantity': quantity,
    'expiry': expiry.toIso8601String(),
    'receivedAt': receivedAt.toIso8601String(),
    'unitCost': unitCost,
    'supplierId': supplierId,
    'manufacturedAt': manufacturedAt?.toIso8601String(),
    'location': location,
  };
  factory InventoryLot.fromJson(JsonMap j) => InventoryLot(
    id: jsonText(j, 'id'),
    productId: jsonText(j, 'productId'),
    branchId: jsonText(j, 'branchId', fallback: mainBranchId),
    code: jsonText(j, 'code'),
    quantity: jsonInteger(j, 'quantity'),
    expiry: jsonDate(j, 'expiry'),
    receivedAt: jsonDate(j, 'receivedAt'),
    unitCost: jsonNumber(j, 'unitCost'),
    supplierId: jsonText(j, 'supplierId', fallback: ''),
    manufacturedAt: j['manufacturedAt'] == null
        ? null
        : jsonDate(j, 'manufacturedAt'),
    location: jsonText(j, 'location', fallback: ''),
  );

  static DateTime dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
