import '../../../core/utils/json_value.dart';

class InventoryMovement {
  const InventoryMovement({
    required this.id,
    required this.lotId,
    required this.productId,
    required this.at,
    required this.delta,
    required this.balance,
    required this.reason,
  });
  final String id, lotId, productId, reason;
  final DateTime at;
  final int delta, balance;
  Map<String, Object> toJson() => {
    'id': id,
    'lotId': lotId,
    'productId': productId,
    'at': at.toIso8601String(),
    'delta': delta,
    'balance': balance,
    'reason': reason,
  };
  factory InventoryMovement.fromJson(JsonMap j) => InventoryMovement(
    id: jsonText(j, 'id'),
    lotId: jsonText(j, 'lotId'),
    productId: jsonText(j, 'productId'),
    at: jsonDate(j, 'at'),
    delta: jsonInteger(j, 'delta'),
    balance: jsonInteger(j, 'balance'),
    reason: jsonText(j, 'reason'),
  );
}
