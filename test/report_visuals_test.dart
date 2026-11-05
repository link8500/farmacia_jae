import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/models/reports/models/local_report.dart';
import 'package:farmacia_sae/models/reports/models/report_visuals.dart';
import 'package:farmacia_sae/models/reports/models/sales_analytics.dart';
import 'package:farmacia_sae/models/sales/models/sale_receipt.dart';

void main() {
  final today = DateTime(2026, 10, 27);
  test('ticket promedio redondea mitades desde centavos enteros', () {
    final data = PharmacyController(clock: () => today);
    addTearDown(data.dispose);
    data.addToCart(data.products.firstWhere((p) => p.id == 'prd-001'));
    data.addToCart(data.products.firstWhere((p) => p.id == 'prd-006'));
    expect(
      data.checkoutSale(method: PaymentMethod.cash, tendered: 100),
      isNull,
    );
    data.addToCart(data.products.firstWhere((p) => p.id == 'prd-003'));
    expect(
      data.checkoutSale(method: PaymentMethod.card, tendered: 100),
      isNull,
    );
    final totals = SalesTotals(data.sales);
    expect(totals.net, 9.95);
    expect(totals.count, 2);
    expect(totals.average, 4.98);
  });
  ReportChartSpec chart(ReportVisuals v, String id) =>
      v.charts.singleWhere((s) => s.id == id);
  test(
    'ventas, pagos y rankings excluyen anulaciones y respetan los mismos filtros',
    () {
      final data = PharmacyController(clock: () => today);
      addTearDown(data.dispose);
      final product = data.products.first;
      void sell(PaymentMethod method) {
        expect(data.addToCart(product), isTrue);
        expect(data.checkoutSale(method: method, tendered: 100), isNull);
      }

      sell(PaymentMethod.cash);
      sell(PaymentMethod.card);
      sell(PaymentMethod.transfer);
      expect(
        data.cancelSale(data.sales.last.id, 'Prueba de anulación'),
        isNull,
      );
      final v = ReportVisuals.build(data, LocalReportKind.sales, today, today);
      final valid = data.sales.where((s) => !s.cancelled).toList();
      final total = valid.fold<double>(0, (n, s) => n + s.total);
      expect(v.charts.length, 7);
      expect(chart(v, 'sales-trend').total, total);
      expect(chart(v, 'sales-payments').total, total);
      expect(chart(v, 'sales-branches').total, total);
      expect(chart(v, 'sales-registers').total, total);
      expect(chart(v, 'sales-operators').total, total);
      expect(chart(v, 'sales-products').total, 2);
      expect(chart(v, 'sales-products').values.single.unit, product.unit);
      expect(chart(v, 'sales-state').values.map((p) => p.value), [2, 1]);
      final filtered = ReportVisuals.build(
        data,
        LocalReportKind.salesDetails,
        today,
        today,
        filter: const SalesReportFilter(state: SaleReportState.cancelled),
      );
      expect(chart(filtered, 'sales-trend').hasData, isFalse);
      expect(chart(filtered, 'sales-state').values.map((p) => p.value), [0, 1]);
      final payment = ReportVisuals.build(
        data,
        LocalReportKind.salesByOperator,
        today,
        today,
        filter: SalesReportFilter(
          method: valid.first.method,
          branchId: valid.first.branchId,
          registerId: valid.first.registerId,
          actorId: valid.first.actorId,
        ),
      );
      expect(chart(payment, 'sales-payments').total, valid.first.total);
    },
  );
  test(
    'inventario distribuye cada unidad una sola vez e ignora fechas históricas',
    () {
      final data = PharmacyController(clock: () => today);
      addTearDown(data.dispose);
      final v = ReportVisuals.build(
        data,
        LocalReportKind.inventory,
        DateTime(2000),
        DateTime(2001),
      );
      final stock = chart(v, 'stock-state');
      expect(stock.total, data.stockTotal);
      expect(stock.values.every((p) => p.value >= 0), isTrue);
      expect(
        stock.values
            .where((p) => p.key == 'fresh' || p.key == 'soon')
            .fold<double>(0, (n, p) => n + p.value),
        data.availableTotal,
      );
      final comparison = chart(v, 'stock-minimum');
      expect(comparison.values.length, lessThanOrEqualTo(6));
      expect(
        comparison.values.every(
          (p) => p.reference != null && p.unit.isNotEmpty,
        ),
        isTrue,
      );
    },
  );
  test(
    'intervalos incluyen límites y ceros sin perder sumas en períodos largos',
    () {
      for (final end in [
        DateTime(2026, 1, 31),
        DateTime(2026, 4, 15),
        DateTime(2027, 12, 31),
        DateTime(2030, 12, 31),
      ]) {
        final start = DateTime(2026);
        final series = ReportVisuals.timeline(
          [
            (start, 2.5),
            (end.add(const Duration(hours: 23)), 3.75),
            (end.add(const Duration(days: 1)), 100),
          ],
          start,
          end,
        );
        expect(series.length, lessThanOrEqualTo(36));
        expect(series.fold<double>(0, (n, v) => n + v.value), 6.25);
        expect(series.any((p) => p.value == 0), isTrue);
      }
      expect(
        ReportVisuals.timeline([], today, DateTime(2026, 10, 26)),
        isEmpty,
      );
    },
  );
  test('nombres repetidos mantienen identidades diferentes en rankings', () {
    final grouped = ReportVisuals.grouped([
      ('a', 'Mismo nombre', 2.0, 'Caja'),
      ('b', 'Mismo nombre', 3.0, 'Frasco'),
      ('a', 'Nombre antiguo', 4.0, 'Caja'),
    ]);
    expect(grouped.map((p) => p.key), ['a', 'b']);
    expect(grouped.map((p) => p.value), [6, 3]);
    expect(grouped.first.label, 'Mismo nombre');
  });
  test('sin operaciones no se inventan ventas, compras ni eventos', () {
    final data = PharmacyController(seedDemo: false, clock: () => today);
    addTearDown(data.dispose);
    for (final kind in LocalReportKind.values) {
      final v = ReportVisuals.build(data, kind, today, today);
      expect(v.charts.every((s) => !s.hasData), isTrue, reason: kind.name);
    }
  });
}
