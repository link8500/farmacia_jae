import '../../../core/utils/json_value.dart';
import '../../inventory/models/lot_allocation.dart';
import '../../organization/models/organization.dart';

enum PurchaseStatus { pending, received, cancelled }

/// El costo de compra pertenece a la operación, no al precio de venta maestro.
class PurchaseLine {
  const PurchaseLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
    this.dosage = '',
    this.presentation = '',
    this.unit = '',
    this.packageUnits = 1,
  });
  final String productId, productName;
  final String dosage, presentation, unit;
  final int packageUnits;
  final int quantity;
  final double unitCost;
  double get total => money(quantity * unitCost);
  Map<String, Object> toJson() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitCost': unitCost,
    'dosage': dosage,
    'presentation': presentation,
    'unit': unit,
    'packageUnits': packageUnits,
  };
  factory PurchaseLine.fromJson(JsonMap j) => PurchaseLine(
    productId: jsonText(j, 'productId'),
    productName: jsonText(j, 'productName'),
    quantity: jsonInteger(j, 'quantity'),
    unitCost: jsonNumber(j, 'unitCost'),
    dosage: jsonText(j, 'dosage', fallback: ''),
    presentation: jsonText(j, 'presentation', fallback: ''),
    unit: jsonText(j, 'unit', fallback: ''),
    packageUnits: jsonInteger(j, 'packageUnits', fallback: 1),
  );
}

class PurchaseOrder {
  static const maxManufacturerIndicationsLength = 2000;

  const PurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.createdAt,
    required this.lines,
    this.receivedLots = const [],
    this.manufacturerIndications = const {},
    this.status = PurchaseStatus.pending,
    this.receivedAt,
    this.paidAt,
    this.paymentMethod = '',
    this.reason = '',
    this.branchId = mainBranchId,
  });
  final String id, supplierId, supplierName, paymentMethod, reason;
  final String branchId;
  final DateTime createdAt;
  final DateTime? receivedAt, paidAt;
  final List<PurchaseLine> lines;
  final List<LotAllocation> receivedLots;

  /// Texto del prospecto entregado con esta compra, por ID de producto.
  final Map<String, String> manufacturerIndications;

  final PurchaseStatus status;
  double get total => money(lines.fold<double>(0, (n, line) => n + line.total));
  PurchaseOrder received(
    DateTime date, {
    List<LotAllocation> lots = const [],
    Map<String, String> manufacturerIndications = const {},
  }) => PurchaseOrder(
    branchId: branchId,
    id: id,
    supplierId: supplierId,
    supplierName: supplierName,
    createdAt: createdAt,
    lines: lines,
    receivedLots: List.unmodifiable(lots),
    manufacturerIndications: Map.unmodifiable(manufacturerIndications),
    status: PurchaseStatus.received,
    receivedAt: date,
  );
  PurchaseOrder cancelled(String note) => PurchaseOrder(
    branchId: branchId,
    id: id,
    supplierId: supplierId,
    supplierName: supplierName,
    createdAt: createdAt,
    lines: lines,
    status: PurchaseStatus.cancelled,
    reason: note,
  );
  PurchaseOrder paid(DateTime date, String method) => PurchaseOrder(
    branchId: branchId,
    id: id,
    supplierId: supplierId,
    supplierName: supplierName,
    createdAt: createdAt,
    lines: lines,
    status: status,
    receivedLots: receivedLots,
    manufacturerIndications: manufacturerIndications,
    receivedAt: receivedAt,
    paidAt: date,
    paymentMethod: method,
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'supplierId': supplierId,
    'branchId': branchId,
    'supplierName': supplierName,
    'createdAt': createdAt.toIso8601String(),
    'lines': lines.map((l) => l.toJson()).toList(),
    'receivedLots': receivedLots.map((l) => l.toJson()).toList(),
    if (manufacturerIndications.isNotEmpty)
      'manufacturerIndications': manufacturerIndications,
    'status': status.name,
    'receivedAt': receivedAt?.toIso8601String(),
    'paidAt': paidAt?.toIso8601String(),
    'paymentMethod': paymentMethod,
    'reason': reason,
  };
  factory PurchaseOrder.fromJson(JsonMap j) => PurchaseOrder(
    id: jsonText(j, 'id'),
    supplierId: jsonText(j, 'supplierId'),
    branchId: jsonText(j, 'branchId', fallback: mainBranchId),
    supplierName: jsonText(j, 'supplierName'),
    createdAt: jsonDate(j, 'createdAt'),
    lines: List.unmodifiable(jsonList(j, 'lines', PurchaseLine.fromJson)),
    receivedLots: j.containsKey('receivedLots')
        ? List.unmodifiable(jsonList(j, 'receivedLots', LotAllocation.fromJson))
        : const [],
    manufacturerIndications: j.containsKey('manufacturerIndications')
        ? Map.unmodifiable(_readManufacturerIndications(j))
        : const {},
    status: jsonEnum(j, 'status', PurchaseStatus.values),
    receivedAt: j['receivedAt'] == null ? null : jsonDate(j, 'receivedAt'),
    paidAt: j['paidAt'] == null ? null : jsonDate(j, 'paidAt'),
    paymentMethod: jsonText(j, 'paymentMethod'),
    reason: jsonText(j, 'reason'),
  );

  static Map<String, String> _readManufacturerIndications(JsonMap json) {
    final values = jsonObject(json['manufacturerIndications']);
    return {for (final id in values.keys) id: jsonText(values, id)};
  }
}

/// Datos de recepción aún no aplicados. El controlador valida TODAS las líneas.
class LotReceipt {
  const LotReceipt({
    required this.productId,
    required this.code,
    required this.expiry,
    this.quantity,
    this.manufacturedAt,
    this.location = '',
    this.salePrice,
  });
  final String productId, code;

  /// Si se omite, la única recepción del producto cubre toda su línea.
  final int? quantity;
  final DateTime expiry;
  final DateTime? manufacturedAt;
  final String location;

  /// Precio unitario nuevo, aplicado solamente si se confirma toda la recepción.
  final double? salePrice;
}
