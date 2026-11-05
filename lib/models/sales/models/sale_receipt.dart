import '../../../core/utils/json_value.dart';

enum PaymentMethod {
  cash('Efectivo'),
  card('Tarjeta'),
  transfer('Transferencia');

  const PaymentMethod(this.label);
  final String label;
}

class LotAllocation {
  const LotAllocation({required this.lotId, required this.quantity});
  final String lotId;
  final int quantity;
  Map<String, Object> toJson() => {'lotId': lotId, 'quantity': quantity};
  factory LotAllocation.fromJson(JsonMap j) => LotAllocation(
    lotId: jsonText(j, 'lotId'),
    quantity: jsonInteger(j, 'quantity'),
  );
}

/// Captura nombre, precio y unidad al vender: editar la ficha no altera facturas.
class SaleLine {
  const SaleLine({
    required this.productId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.allocations,
  });
  final String productId, name, unit;
  final int quantity;
  final double unitPrice;
  final List<LotAllocation> allocations;
  double get total => money(quantity * unitPrice);
  Map<String, Object> toJson() => {
    'productId': productId,
    'name': name,
    'unit': unit,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'allocations': allocations.map((a) => a.toJson()).toList(),
  };
  factory SaleLine.fromJson(JsonMap j) => SaleLine(
    productId: jsonText(j, 'productId'),
    name: jsonText(j, 'name'),
    unit: jsonText(j, 'unit'),
    quantity: jsonInteger(j, 'quantity'),
    unitPrice: jsonNumber(j, 'unitPrice'),
    allocations: List.unmodifiable(
      jsonList(j, 'allocations', LotAllocation.fromJson),
    ),
  );
}

/// Comprobante INTERNO de demostración. No constituye facturación fiscal.
class SaleReceipt {
  const SaleReceipt({
    required this.id,
    required this.createdAt,
    required this.customerName,
    required this.actorName,
    required this.lines,
    required this.method,
    required this.cashReceived,
    this.customerId = '',
    this.cancelledAt,
    this.reason = '',
    this.actorId = '',
    this.branchId = '',
    this.branchName = '',
    this.registerId = '',
    this.registerName = '',
  });
  final String id, customerId, customerName, actorName, reason;

  /// Fotografía al facturar: reasignar/renombrar no reescribe el historial.
  /// Vacío significa venta anterior sin trazabilidad, nunca una atribución supuesta.
  final String actorId, branchId, branchName, registerId, registerName;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final List<SaleLine> lines;
  final PaymentMethod method;
  final double cashReceived;
  double get total => money(lines.fold<double>(0, (n, l) => n + l.total));
  double get change =>
      method == PaymentMethod.cash ? money(cashReceived - total) : 0;
  bool get cancelled => cancelledAt != null;
  SaleReceipt cancel(DateTime date, String note) => SaleReceipt(
    id: id,
    createdAt: createdAt,
    customerId: customerId,
    customerName: customerName,
    actorName: actorName,
    actorId: actorId,
    branchId: branchId,
    branchName: branchName,
    registerId: registerId,
    registerName: registerName,
    lines: lines,
    method: method,
    cashReceived: cashReceived,
    cancelledAt: date,
    reason: note,
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'customerId': customerId,
    'customerName': customerName,
    'actorName': actorName,
    'actorId': actorId,
    'branchId': branchId,
    'branchName': branchName,
    'registerId': registerId,
    'registerName': registerName,
    'lines': lines.map((l) => l.toJson()).toList(),
    'method': method.name,
    'cashReceived': cashReceived,
    'cancelledAt': cancelledAt?.toIso8601String(),
    'reason': reason,
  };
  factory SaleReceipt.fromJson(JsonMap j) => SaleReceipt(
    id: jsonText(j, 'id'),
    createdAt: jsonDate(j, 'createdAt'),
    customerId: jsonText(j, 'customerId'),
    customerName: jsonText(j, 'customerName'),
    actorName: jsonText(j, 'actorName'),
    actorId: jsonText(j, 'actorId', fallback: ''),
    branchId: jsonText(j, 'branchId', fallback: ''),
    branchName: jsonText(j, 'branchName', fallback: ''),
    registerId: jsonText(j, 'registerId', fallback: ''),
    registerName: jsonText(j, 'registerName', fallback: ''),
    lines: List.unmodifiable(jsonList(j, 'lines', SaleLine.fromJson)),
    method: jsonEnum(j, 'method', PaymentMethod.values),
    cashReceived: jsonNumber(j, 'cashReceived'),
    cancelledAt: j['cancelledAt'] == null ? null : jsonDate(j, 'cancelledAt'),
    reason: jsonText(j, 'reason'),
  );
}
