import 'dart:math' as math;
import '../utils/json_value.dart';
import '../../models/audit/models/audit_entry.dart';
import '../../models/contacts/models/contact.dart';
import '../../models/inventory/models/inventory_lot.dart';
import '../../models/inventory/models/inventory_movement.dart';
import '../../models/organization/models/organization.dart';
import '../../models/products/models/product.dart';
import '../../models/purchases/models/purchase_order.dart';
import '../../models/sales/models/sale_receipt.dart';

/// Escenario reproducible y ficticio. Construye recepciones antes de vender,
/// descuenta por FEFO y devuelve al mismo lote las ventas anuladas.
/// Sus IDs propios permiten añadirlo una vez sin reemplazar registros editados.
class PharmacyDemoScenario {
  PharmacyDemoScenario._();
  static const version = 1;
  final branches = <PharmacyBranch>[];
  final registers = <BillingRegister>[];
  final staff = <StaffMember>[];
  final branchProducts = <BranchProduct>[];
  final contacts = <Contact>[];
  final purchases = <PurchaseOrder>[];
  final sales = <SaleReceipt>[];
  final movements = <InventoryMovement>[];
  final audit = <AuditEntry>[];
  final _lots = <String, InventoryLot>{};
  List<InventoryLot> get lots => _lots.values.toList();
  int _serial = 0;
  String _id(String kind) => 'demo-history-$kind-${++_serial}';

  /// Recibe el catálogo existente: no clona fichas ni cambia precios o imágenes.
  /// Si faltan las asignaciones originales, usa una sede demo independiente.
  static PharmacyDemoScenario build({
    required DateTime now,
    required List<Product> products,
    required List<PharmacyBranch> existingBranches,
    required List<BillingRegister> existingRegisters,
    required List<StaffMember> existingStaff,
  }) {
    if (products.isEmpty) {
      throw const FormatException('Se necesita al menos un producto activo.');
    }
    final result = PharmacyDemoScenario._();
    final customers = [
      'María Elena Vargas',
      'Carlos Alberto Ríos',
      'Lucía Mendoza',
      'José Manuel Reyes',
      'Rosa Isabel Torres',
      'Luis Fernando Castro',
      'Patricia Gómez',
      'Miguel Ángel Ruiz',
      'Andrea Sofía Pérez',
      'Jorge Luis Morales',
      'Carmen Cecilia Flores',
      'Pedro Antonio Salinas',
      'Valeria Sánchez',
      'Ricardo Hernández',
      'Gabriela Espinoza',
      'Ernesto Aguilar',
    ];
    for (var i = 0; i < customers.length; i++) {
      result.contacts.add(
        Contact(
          id: 'demo-history-customer-$i',
          kind: ContactKind.customer,
          name: customers[i],
          email: 'cliente${i + 1}@farmacia-demo.example',
          address: 'Dirección ficticia ${i + 1}, La Paz Centro',
        ),
      );
    }
    for (final (index, name) in [
      'Distribuidora Salud del Pacífico',
      'VitaCentro Suministros',
      'Botiquín del Norte',
      'Bienestar y Cuidado Mayorista',
    ].indexed) {
      result.contacts.add(
        Contact(
          id: 'demo-history-supplier-$index',
          kind: ContactKind.supplier,
          name: name,
          email: 'proveedor${index + 1}@farmacia-demo.example',
          address: 'Dirección comercial ficticia ${index + 1}, León',
        ),
      );
    }
    final main = existingBranches
        .where((b) => b.id == mainBranchId && b.active)
        .firstOrNull;
    final originalOperators = existingStaff
        .where((s) => s.id == 'demo-admin' || s.id == 'demo-employee')
        .toList();
    final originalBoxes = existingRegisters
        .where((r) => r.id == 'register-main-1' || r.id == 'register-main-2')
        .toList();
    final useMain =
        main != null &&
        originalOperators.length == 2 &&
        originalBoxes.length == 2 &&
        originalBoxes.every((r) => r.branchId == mainBranchId);
    for (var b = 0; b < 3; b++) {
      final branch = b == 0 && useMain
          ? main
          : PharmacyBranch(
              id: 'demo-history-branch-$b',
              name: [
                'Sucursal Centro',
                'Sucursal Norte',
                'Sucursal Mercado',
              ][b],
              address: 'Ubicación ficticia, La Paz Centro',
            );
      if (!(b == 0 && useMain)) result.branches.add(branch);
      final operators = <(StaffMember, BillingRegister)>[];
      for (var operator = 0; operator < 2; operator++) {
        if (b == 0 && useMain) {
          final member = originalOperators[operator];
          final box = originalBoxes.firstWhere(
            (r) =>
                r.id ==
                (member.id == 'demo-admin'
                    ? 'register-main-2'
                    : 'register-main-1'),
          );
          operators.add((member, box));
        } else {
          final box = BillingRegister(
            id: 'demo-history-register-$b-$operator',
            branchId: branch.id,
            name: 'Caja ${operator + 1}',
          );
          final member = StaffMember(
            id: 'demo-history-staff-$b-$operator',
            name: [
              ['Elena Suárez', 'Óscar Benítez'],
              ['Sofía Hernández', 'Manuel Duarte'],
              ['Isabel Romero', 'Andrés Castillo'],
            ][b][operator],
            username: 'demo.sucursal$b.${operator + 1}',
            branchId: branch.id,
            registerId: box.id,
          );
          result.registers.add(box);
          result.staff.add(member);
          operators.add((member, box));
        }
      }
      for (final p in products) {
        result.branchProducts.add(BranchProduct(branch.id, p.id));
      }
      result._branch(now, branch, operators, products, b);
    }
    result.movements.sort((a, b) => a.at.compareTo(b.at));
    result.audit.sort((a, b) => a.at.compareTo(b.at));
    return result;
  }

  void _movement(InventoryLot lot, int delta, DateTime at, String reason) {
    final updated = lot.withQuantity(lot.quantity + delta);
    if (updated.quantity < 0) {
      throw StateError('No se puede vender sin existencias.');
    }
    _lots[lot.id] = updated;
    movements.add(
      InventoryMovement(
        id: _id('movement'),
        lotId: lot.id,
        productId: lot.productId,
        at: at,
        delta: delta,
        balance: updated.quantity,
        reason: reason,
      ),
    );
  }

  void _event(DateTime at, StaffMember actor, String action, String detail) =>
      audit.add(
        AuditEntry(
          id: _id('audit'),
          at: at,
          actorId: actor.id,
          actorName: actor.name,
          action: action,
          detail: detail,
        ),
      );

  void _branch(
    DateTime now,
    PharmacyBranch branch,
    List<(StaffMember, BillingRegister)> operators,
    List<Product> products,
    int branchIndex,
  ) {
    final today = InventoryLot.dayOnly(now);
    for (var monthIndex = 0; monthIndex < 6; monthIndex++) {
      final first = DateTime(today.year, today.month - 5 + monthIndex, 1);
      final last = DateTime(first.year, first.month + 1, 0);
      final requests = <_DemoSaleRequest>[];
      for (var day = 1; day <= last.day; day++) {
        final date = DateTime(first.year, first.month, day);
        if (date.isAfter(today)) break;
        // El último mes tiene actividad diaria; el histórico alterna días.
        if (monthIndex < 5 && (day + branchIndex).isOdd) continue;
        final random = math.Random(
          9107 + monthIndex * 211 + branchIndex * 37 + day * 13,
        );
        final count = 1 + random.nextInt(3);
        for (var n = 0; n < count; n++) {
          final at = DateTime(
            date.year,
            date.month,
            date.day,
            9 + n * 2,
            (day * 3 + branchIndex * 7) % 50,
          );
          if (at.isAfter(now)) continue;
          final indices = List.generate(products.length, (i) => i)
            ..shuffle(random);
          final lines = {
            for (final index in indices.take(
              1 + random.nextInt(math.min(3, products.length)),
            ))
              products[index]: 1 + random.nextInt(3),
          };
          requests.add(
            _DemoSaleRequest(
              at,
              lines,
              operators[(day + n) % operators.length],
              random.nextInt(16),
              PaymentMethod.values[(day + n + branchIndex) % 3],
              (day + n * 3 + branchIndex) % 17 == 0 &&
                  !at.add(const Duration(minutes: 5)).isAfter(now),
            ),
          );
        }
      }
      final receiptAt = DateTime(first.year, first.month, 1, 8);
      if (receiptAt.isAfter(now)) continue;
      // Dos proveedores por mes y sucursal. El pedido cubre la demanda generada
      // y una reserva física; cada línea crea un lote propio y su movimiento.
      for (var group = 0; group < 2; group++) {
        final selected = products.indexed
            .where((p) => p.$1 % 2 == group)
            .map((p) => p.$2)
            .toList();
        if (selected.isEmpty) continue;
        final supplier = contacts.firstWhere(
          (c) =>
              c.id ==
              'demo-history-supplier-${(monthIndex + branchIndex + group) % 4}',
        );
        final orderId = _id('purchase');
        final lines = <PurchaseLine>[];
        for (final product in selected) {
          final quantity =
              requests.fold<int>(
                0,
                (n, request) => n + (request.lines[product] ?? 0),
              ) +
              12 +
              (monthIndex + branchIndex) % 13;
          final unitCost = money(
            product.price * (.54 + (monthIndex % 3) * .035),
          );
          lines.add(
            PurchaseLine(
              productId: product.id,
              productName: product.name,
              dosage: product.dosage,
              presentation: product.presentation,
              unit: product.unit,
              packageUnits: product.packageUnits,
              quantity: quantity,
              unitCost: unitCost,
            ),
          );
          final id = _id('lot');
          final lot = InventoryLot(
            id: id,
            productId: product.id,
            branchId: branch.id,
            code:
                'DEMO-${first.year}${first.month.toString().padLeft(2, '0')}-${product.code}-$branchIndex',
            quantity: 0,
            supplierId: supplier.id,
            manufacturedAt: receiptAt.subtract(const Duration(days: 120)),
            location:
                'Estante ${products.indexOf(product) ~/ 3 + 1} · Nivel ${products.indexOf(product) % 3 + 1}',
            receivedAt: receiptAt,
            expiry: today.add(
              Duration(
                days: 30 + monthIndex * 45 + products.indexOf(product) * 6,
              ),
            ),
            unitCost: unitCost,
          );
          _lots[id] = lot;
          _movement(lot, quantity, receiptAt, 'Recepción de compra $orderId');
        }
        final paid = (monthIndex + group + branchIndex) % 3 != 0;
        purchases.add(
          PurchaseOrder(
            id: orderId,
            branchId: branch.id,
            supplierId: supplier.id,
            supplierName: supplier.name,
            createdAt: receiptAt.subtract(const Duration(hours: 1)),
            receivedAt: receiptAt,
            status: PurchaseStatus.received,
            paidAt: paid ? receiptAt : null,
            paymentMethod: paid ? 'Transferencia' : '',
            lines: lines,
          ),
        );
        _event(
          receiptAt,
          operators.first.$1,
          'Compra recibida',
          '$orderId · ${supplier.name}',
        );
      }
      for (final request in requests) {
        final id = _id('sale'), lines = <SaleLine>[];
        for (final entry in request.lines.entries) {
          var remaining = entry.value;
          final candidates =
              _lots.values
                  .where(
                    (l) =>
                        l.branchId == branch.id &&
                        l.productId == entry.key.id &&
                        l.quantity > 0 &&
                        !l.receivedAt.isAfter(request.at) &&
                        !l.isExpired(request.at),
                  )
                  .toList()
                ..sort((a, b) {
                  final expiry = a.expiry.compareTo(b.expiry);
                  return expiry == 0
                      ? a.receivedAt.compareTo(b.receivedAt)
                      : expiry;
                });
          final allocations = <LotAllocation>[];
          for (final lot in candidates) {
            final quantity = math.min(remaining, lot.quantity);
            allocations.add(LotAllocation(lotId: lot.id, quantity: quantity));
            _movement(lot, -quantity, request.at, 'Venta $id');
            remaining -= quantity;
            if (remaining == 0) break;
          }
          if (remaining != 0) {
            throw StateError('Compra insuficiente para la venta ficticia.');
          }
          lines.add(
            SaleLine(
              productId: entry.key.id,
              name: entry.key.name,
              unit: entry.key.unit,
              quantity: entry.value,
              unitPrice: entry.key.price,
              allocations: allocations,
            ),
          );
        }
        final total = money(lines.fold<double>(0, (n, l) => n + l.total));
        final customer = contacts.firstWhere(
          (c) => c.id == 'demo-history-customer-${request.customer}',
        );
        final actor = request.operator.$1, box = request.operator.$2;
        var sale = SaleReceipt(
          id: id,
          createdAt: request.at,
          customerId: customer.id,
          customerName: customer.name,
          actorId: actor.id,
          actorName: actor.name,
          branchId: branch.id,
          branchName: branch.name,
          registerId: box.id,
          registerName: box.name,
          lines: lines,
          method: request.method,
          cashReceived: request.method == PaymentMethod.cash
              ? (total / 10).ceil() * 10.0
              : total,
        );
        _event(request.at, actor, 'Venta registrada', '$id · ${customer.name}');
        if (request.cancelled) {
          final at = request.at.add(const Duration(minutes: 5));
          sale = sale.cancel(at, 'Corrección de captura');
          for (final line in lines) {
            for (final allocation in line.allocations) {
              _movement(
                _lots[allocation.lotId]!,
                allocation.quantity,
                at,
                'Anulación $id',
              );
            }
          }
          _event(at, actor, 'Venta anulada', id);
        }
        sales.add(sale);
      }
    }
    // Pendiente y cancelada son pedidos, nunca recepciones ni existencias.
    for (var i = 0; i < 2; i++) {
      final supplier = contacts.firstWhere(
        (c) => c.id == 'demo-history-supplier-${(branchIndex + i) % 4}',
      );
      final product = products[(branchIndex + i) % products.length];
      purchases.add(
        PurchaseOrder(
          id: _id('purchase'),
          branchId: branch.id,
          supplierId: supplier.id,
          supplierName: supplier.name,
          createdAt: today
              .subtract(Duration(days: i + 1))
              .add(const Duration(hours: 10)),
          status: i == 0 ? PurchaseStatus.pending : PurchaseStatus.cancelled,
          reason: i == 1 ? 'Pedido sustituido' : '',
          lines: [
            PurchaseLine(
              productId: product.id,
              productName: product.name,
              quantity: 24,
              unitCost: money(product.price * .6),
            ),
          ],
        ),
      );
    }
  }
}

/// Intención de venta previa al suministro. Permite dimensionar compras antes
/// de aplicar el historial, sin saldos negativos ni lotes inventados al vender.
class _DemoSaleRequest {
  const _DemoSaleRequest(
    this.at,
    this.lines,
    this.operator,
    this.customer,
    this.method,
    this.cancelled,
  );
  final DateTime at;
  final Map<Product, int> lines;
  final (StaffMember, BillingRegister) operator;
  final int customer;
  final PaymentMethod method;
  final bool cancelled;
}
