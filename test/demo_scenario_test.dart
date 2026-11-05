import 'dart:convert';
import 'package:farmacia_sae/models/contacts/models/contact.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';
import 'package:farmacia_sae/core/services/local_administration_store.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/models/purchases/models/purchase_order.dart';
import 'package:farmacia_sae/models/reports/models/local_report.dart';
import 'package:farmacia_sae/models/reports/models/report_visuals.dart';
import 'package:farmacia_sae/models/sales/models/sale_receipt.dart';

void main() {
  final now = DateTime(2026, 10, 27, 18);
  PharmacyController dataAt(DateTime date) {
    final data = PharmacyController(seedDemoHistory: true, clock: () => date);
    addTearDown(data.dispose);
    return data;
  }

  test(
    'historial de seis meses enlaza cada venta, cliente, operador, caja y lote',
    () {
      final data = dataAt(now);
      expect(data.hasDemoHistory, isTrue);
      expect(data.sales.length, greaterThan(400));
      expect(data.branches.length, 3);
      expect(data.staff.length, 6);
      expect(data.registers.length, 6);
      expect(
        data.contacts.where((c) => c.kind == ContactKind.customer).length,
        greaterThanOrEqualTo(16),
      );
      expect(
        data.contacts.where((c) => c.kind == ContactKind.supplier).length,
        greaterThanOrEqualTo(4),
      );
      expect(
        data.sales
            .map((s) => '${s.createdAt.year}-${s.createdAt.month}')
            .toSet()
            .length,
        6,
      );
      expect(
        data.sales.map((s) => s.method).toSet(),
        PaymentMethod.values.toSet(),
      );
      expect(data.sales.any((s) => s.cancelled), isTrue);
      for (final sale in data.sales) {
        expect(sale.createdAt.isAfter(now), isFalse);
        expect(
          data.contacts
              .where((c) => c.kind == ContactKind.customer)
              .any(
                (c) => c.id == sale.customerId && c.name == sale.customerName,
              ),
          isTrue,
        );
        expect(data.staffById(sale.actorId)?.name, sale.actorName);
        expect(data.registerById(sale.registerId)?.branchId, sale.branchId);
        for (final line in sale.lines) {
          expect(data.productById(line.productId)?.name, line.name);
          expect(
            line.allocations.fold<int>(0, (n, a) => n + a.quantity),
            line.quantity,
          );
          for (final allocation in line.allocations) {
            final lot = data.lotById(allocation.lotId)!;
            expect(lot.productId, line.productId);
            expect(lot.branchId, sale.branchId);
            expect(lot.receivedAt.isAfter(sale.createdAt), isFalse);
            expect(lot.isExpired(sale.createdAt), isFalse);
          }
        }
      }
      // El respaldo completo valida otra vez todas las relaciones.
      final clone = PharmacyController(seedDemo: false);
      addTearDown(clone.dispose);
      expect(clone.restoreBackup(data.createBackup()), isNull);
      expect(clone.sales.length, data.sales.length);
    },
  );
  test(
    'recepciones menos ventas y anulaciones reconstruyen todos los saldos ficticios',
    () {
      final data = dataAt(now);
      for (final branch in data.branches) {
        data.selectBranch(branch.id);
        for (final lot in data.lots.where(
          (l) => l.id.startsWith('demo-history-'),
        )) {
          final events = data.movements.where((m) => m.lotId == lot.id).toList()
            ..sort((a, b) => a.at.compareTo(b.at));
          var balance = 0;
          for (final event in events) {
            balance += event.delta;
            expect(event.balance, balance);
            expect(balance, greaterThanOrEqualTo(0));
          }
          expect(balance, lot.quantity);
          final receipt = events.singleWhere(
            (m) => m.reason.startsWith('Recepción de compra'),
          );
          final orderId = receipt.reason
              .split(' · ')
              .first
              .substring('Recepción de compra '.length);
          final order = data.purchases.singleWhere((p) => p.id == orderId);
          expect(order.status, PurchaseStatus.received);
          final line = order.lines.singleWhere(
            (l) => l.productId == lot.productId,
          );
          expect(line.quantity, receipt.delta);
          expect(line.unitCost, lot.unitCost);
          expect(
            data.contacts
                .where((c) => c.kind == ContactKind.supplier)
                .any((s) => s.id == order.supplierId),
            isTrue,
          );
        }
        final v = ReportVisuals.build(
          data,
          LocalReportKind.inventory,
          now,
          now,
        );
        expect(v.charts.first.total, data.stockTotal);
      }
    },
  );
  test(
    'actualizar un navegador existente conserva ediciones y no duplica al recargar',
    () async {
      final old = PharmacyController(clock: () => now);
      addTearDown(old.dispose);
      old.addToCart(old.products.first);
      old.checkoutSale(method: PaymentMethod.cash, tendered: 100);
      final previousSale = old.sales.single.toJson(),
          initialLot = old.lots.first.toJson();
      final store = MemoryAdministrationStore(old.createBackup());
      final current = PharmacyController(
        store: store,
        seedDemoHistory: true,
        clock: () => now,
      );
      addTearDown(current.dispose);
      await current.initialize();
      await current.flush();
      expect(current.loadFailed, isFalse);
      expect(current.hasDemoHistory, isTrue);
      expect(
        current.sales.singleWhere((s) => s.id == previousSale['id']).toJson(),
        previousSale,
      );
      expect(current.lotById(initialLot['id'] as String)!.toJson(), initialLot);
      final count = current.sales.length, lots = current.lots.length;
      final reopened = PharmacyController(
        store: store,
        seedDemoHistory: true,
        clock: () => now.add(const Duration(days: 10)),
      );
      addTearDown(reopened.dispose);
      await reopened.initialize();
      expect(reopened.sales.length, count);
      expect(reopened.lots.length, lots);
      expect(reopened.hasDemoHistory, isTrue);
      expect(jsonDecode(store.data!)['demoScenarioVersion'], 1);
    },
  );
  test(
    'empleado conserva acceso solo a sus ventas y su sucursal después de la carga',
    () async {
      final source = dataAt(now), employee = AuthController.demoUsers.last;
      final data = PharmacyController(
        store: MemoryAdministrationStore(source.createBackup()),
        userProvider: () => employee,
        seedDemoHistory: true,
      );
      addTearDown(data.dispose);
      await data.initialize();
      expect(data.sales, isNotEmpty);
      expect(
        data.sales.every(
          (s) => s.actorId == employee.id && s.branchId == data.workingBranchId,
        ),
        isTrue,
      );
      expect(data.addDemoHistory(), isNotNull);
      expect(data.branches.length, 1);
    },
  );
  test(
    'generador cubre cambios de año y no crea operaciones futuras de madrugada',
    () {
      for (final date in [
        DateTime(2027, 1, 1, 2),
        DateTime(2026, 3, 1, 8, 2),
      ]) {
        final data = dataAt(date);
        expect(data.hasDemoHistory, isTrue);
        expect(
          data.sales.every(
            (s) =>
                !s.createdAt.isAfter(date) &&
                (s.cancelledAt == null || !s.cancelledAt!.isAfter(date)),
          ),
          isTrue,
        );
        for (final branch in data.branches) {
          data.selectBranch(branch.id);
          expect(
            data.purchases.every(
              (p) =>
                  !p.createdAt.isAfter(date) &&
                  (p.paidAt == null || !p.paidAt!.isAfter(date)),
            ),
            isTrue,
          );
        }
      }
    },
  );
  test('un conflicto no reemplaza parcialmente los datos existentes', () {
    final data = PharmacyController();
    addTearDown(data.dispose);
    data.saveBranch(name: 'Sucursal Norte');
    final before = jsonDecode(data.createBackup()) as Map<String, dynamic>;
    expect(data.addDemoHistory(), isNotNull);
    expect(data.hasDemoHistory, isFalse);
    expect(data.sales, isEmpty);
    expect(data.branches.length, (before['branches'] as List).length);
    expect(
      data.contacts.where((c) => c.kind == ContactKind.customer).length,
      1,
    );
    expect(
      data.contacts.where((c) => c.kind == ContactKind.supplier).length,
      1,
    );
  });
}
