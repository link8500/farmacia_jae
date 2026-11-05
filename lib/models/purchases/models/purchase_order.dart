import '../../../core/utils/json_value.dart';
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
  const PurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.createdAt,
    required this.lines,
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
  final PurchaseStatus status;
  double get total => money(lines.fold<double>(0, (n, line) => n + line.total));
  PurchaseOrder received(DateTime date) => PurchaseOrder(
    branchId: branchId,
    id: id,
    supplierId: supplierId,
    supplierName: supplierName,
    createdAt: createdAt,
    lines: lines,
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
    status: jsonEnum(j, 'status', PurchaseStatus.values),
    receivedAt: j['receivedAt'] == null ? null : jsonDate(j, 'receivedAt'),
    paidAt: j['paidAt'] == null ? null : jsonDate(j, 'paidAt'),
    paymentMethod: jsonText(j, 'paymentMethod'),
    reason: jsonText(j, 'reason'),
  );
}

/// Datos de recepción aún no aplicados. El controlador valida TODAS las líneas.
class LotReceipt {
  const LotReceipt({
    required this.productId,
    required this.code,
    required this.expiry,
    this.manufacturedAt,
    this.location = '',
    this.salePrice,
  });
  final String productId, code;
  final DateTime expiry;
  final DateTime? manufacturedAt;
  final String location;

  /// Precio unitario nuevo, aplicado solamente si se confirma toda la recepción.
  final double? salePrice;
}
