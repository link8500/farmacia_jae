import '../../../core/utils/json_value.dart';

class CashSession {
  const CashSession({
    required this.id,
    required this.openedAt,
    required this.openingBalance,
    required this.actorId,
    required this.actorName,
    this.closedAt,
    this.counted,
  });
  final String id, actorId, actorName;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double openingBalance;
  final double? counted;
  bool get isOpen => closedAt == null;
  CashSession close(DateTime date, double amount) => CashSession(
    id: id,
    openedAt: openedAt,
    openingBalance: openingBalance,
    actorId: actorId,
    actorName: actorName,
    closedAt: date,
    counted: amount,
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'actorId': actorId,
    'actorName': actorName,
    'openedAt': openedAt.toIso8601String(),
    'openingBalance': openingBalance,
    'closedAt': closedAt?.toIso8601String(),
    'counted': counted,
  };
  factory CashSession.fromJson(JsonMap j) => CashSession(
    id: jsonText(j, 'id'),
    actorId: jsonText(j, 'actorId'),
    actorName: jsonText(j, 'actorName'),
    openedAt: jsonDate(j, 'openedAt'),
    openingBalance: jsonNumber(j, 'openingBalance'),
    closedAt: j['closedAt'] == null ? null : jsonDate(j, 'closedAt'),
    counted: j['counted'] == null ? null : jsonNumber(j, 'counted'),
  );
}

/// Movimiento de efectivo: tarjetas y transferencias no suman billetes en caja.
class CashMovement {
  const CashMovement({
    required this.id,
    required this.sessionId,
    required this.createdAt,
    required this.amount,
    required this.concept,
    this.reference = '',
  });
  final String id, sessionId, concept, reference;
  final DateTime createdAt;
  final double amount;
  Map<String, Object> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'createdAt': createdAt.toIso8601String(),
    'amount': amount,
    'concept': concept,
    'reference': reference,
  };
  factory CashMovement.fromJson(JsonMap j) => CashMovement(
    id: jsonText(j, 'id'),
    sessionId: jsonText(j, 'sessionId'),
    createdAt: jsonDate(j, 'createdAt'),
    amount: jsonNumber(j, 'amount'),
    concept: jsonText(j, 'concept'),
    reference: jsonText(j, 'reference'),
  );
}
