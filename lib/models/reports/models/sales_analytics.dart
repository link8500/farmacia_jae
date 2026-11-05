import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/json_value.dart';
import '../../inventory/models/inventory_lot.dart';
import '../../sales/models/sale_receipt.dart';

enum SaleReportState { all, valid, cancelled }

/// Una consulta compartida por reportes, totales y estadísticas de cajas.
/// Fechas inclusivas por día de emisión. Las anulaciones se imputan a su
/// factura original: estos importes no son un flujo de caja por día de reembolso.
class SalesReportFilter {
  const SalesReportFilter({
    this.branchId,
    this.registerId,
    this.actorId,
    this.method,
    this.state = SaleReportState.all,
  });
  final String? branchId, registerId, actorId;
  final PaymentMethod? method;
  final SaleReportState state;
  List<SaleReceipt> apply(
    PharmacyController data,
    DateTime start,
    DateTime end,
  ) {
    final first = InventoryLot.dayOnly(start), last = InventoryLot.dayOnly(end);
    return data.sales.where((s) {
      final day = InventoryLot.dayOnly(s.createdAt);
      return !day.isBefore(first) &&
          !day.isAfter(last) &&
          (branchId == null || s.branchId == branchId) &&
          (registerId == null || s.registerId == registerId) &&
          (actorId == null || s.actorId == actorId) &&
          (method == null || s.method == method) &&
          (state == SaleReportState.all ||
              (state == SaleReportState.cancelled) == s.cancelled);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

/// Indicadores sin doble contabilización: anuladas visibles, pero excluidas de
/// ventas netas, unidades y ticket promedio. No se inventan márgenes de ganancia.
class SalesTotals {
  SalesTotals(Iterable<SaleReceipt> sales) : all = sales.toList();
  final List<SaleReceipt> all;
  Iterable<SaleReceipt> get valid => all.where((s) => !s.cancelled);
  int get count => valid.length;
  int get cancelledCount => all.length - count;
  double get net => money(valid.fold<double>(0, (n, s) => n + s.total));
  double get cancelled => money(
    all.where((s) => s.cancelled).fold<double>(0, (n, s) => n + s.total),
  );
  int get units => valid.fold(
    0,
    (n, s) => n + s.lines.fold<int>(0, (m, l) => m + l.quantity),
  );
  // Divide centavos enteros antes de redondear: 995 / 2 = 497.5 → 498.
  // Evita que la aproximación binaria de 4.975 produzca 4.97.
  double get average =>
      count == 0 ? 0 : ((net * 100).round() / count).round() / 100;
  double byMethod(PaymentMethod method) => money(
    valid
        .where((s) => s.method == method)
        .fold<double>(0, (n, s) => n + s.total),
  );
}
