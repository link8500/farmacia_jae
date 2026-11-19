import '../../../core/utils/json_value.dart';

/// Cantidad de un documento asignada a un lote de inventario.
class LotAllocation {
  const LotAllocation({required this.lotId, required this.quantity});

  final String lotId;
  final int quantity;

  Map<String, Object> toJson() => {'lotId': lotId, 'quantity': quantity};

  factory LotAllocation.fromJson(JsonMap json) => LotAllocation(
    lotId: jsonText(json, 'lotId'),
    quantity: jsonInteger(json, 'quantity'),
  );
}
