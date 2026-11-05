import '../../products/models/product.dart';

/// Proyección de consulta, no otro almacén de stock. Se recalcula desde lotes.
class InventorySummary {
  const InventorySummary({
    required this.product,
    required this.totalQuantity,
    required this.availableQuantity,
    required this.lotCount,
    required this.nextExpiry,
    required this.hasExpiringLots,
    required this.hasExpiredLots,
  });

  final Product product;
  final int totalQuantity;
  final int availableQuantity;
  final int lotCount;
  final DateTime? nextExpiry;
  final bool hasExpiringLots;
  final bool hasExpiredLots;

  /// Reposición considera únicamente las unidades que se pueden vender.
  bool get isLow => availableQuantity <= product.minimum;
}
