import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/core/services/local_administration_store.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';
import 'package:farmacia_sae/core/services/preferences_store.dart';
import 'package:farmacia_sae/core/utils/csv.dart';
import 'package:farmacia_sae/models/contacts/models/contact.dart';
import 'package:farmacia_sae/models/purchases/models/purchase_order.dart';
import 'package:farmacia_sae/models/sales/models/sale_receipt.dart';
import 'package:farmacia_sae/models/incidents/models/support_case.dart';
import 'package:farmacia_sae/models/reports/models/local_report.dart';
import 'package:farmacia_sae/models/sales/widgets/receipt_dialog.dart';

class FailingStore implements AdministrationStore {
  FailingStore({this.failRead = false, this.failWrite = false});
  bool failRead, failWrite;
  String? data;
  @override
  Future<String?> read() async {
    if (failRead) throw StateError('read blocked');
    return data;
  }

  @override
  Future<void> write(String value) async {
    if (failWrite) throw StateError('quota exceeded');
    data = value;
  }
}

/// Contratos del prototipo: flujos completos, dinero y recuperaciones atómicas.
void main() {
  late PharmacyController data;
  late DateTime now;
  void order({int quantity = 12, double cost = 3}) {
    expect(
      data.createPurchase('supplier-demo', [
        PurchaseLine(
          productId: data.products.first.id,
          productName: '',
          quantity: quantity,
          unitCost: cost,
        ),
      ]),
      isNull,
    );
  }

  void receive({String code = 'QA-LOTE'}) {
    expect(
      data.receivePurchase(data.purchases.last.id, [
        LotReceipt(
          productId: data.products.first.id,
          code: code,
          expiry: now.add(const Duration(days: 365)),
        ),
      ]),
      isNull,
    );
  }

  void sale({PaymentMethod method = PaymentMethod.cash}) {
    data.addToCart(data.products.first);
    expect(data.checkoutSale(method: method, tendered: 100), isNull);
  }

  setUp(() {
    now = DateTime(2026, 10, 13, 10);
    // Conserva pruebas de Caja para cuando se reactive; el modo sin Caja
    // se verifica por separado sin debilitar estos contratos.
    data = PharmacyController(clock: () => now, cashEnabled: true);
  });
  tearDown(() => data.dispose());

  test('orden pendiente no suma stock; recepción suma lotes una sola vez', () {
    final before = data.stockTotal;
    order();
    expect(data.stockTotal, before);
    receive();
    expect(data.stockTotal, before + 12);
    expect(data.purchases.single.status, PurchaseStatus.received);
    final beforeRepeat = data.createBackup();
    expect(data.receivePurchase(data.purchases.single.id, []), isNotNull);
    expect(data.stockTotal, before + 12);
    expect(jsonDecode(beforeRepeat)['lots'].length, data.lots.length);
  });
  test('reponer mismo lote no duplica y conserva costo medio preciso', () {
    order(quantity: 2, cost: 3);
    receive();
    order(quantity: 1, cost: 4);
    receive();
    final lot = data.lots.singleWhere((l) => l.code == 'QA-LOTE');
    expect(lot.quantity, 3);
    expect(lot.unitCost * lot.quantity, closeTo(10, 0.00001));
  });
  test('recepción inválida no aplica ninguna línea', () {
    final stock = data.stockTotal;
    expect(
      data.createPurchase('supplier-demo', [
        for (final p in data.products.take(2))
          PurchaseLine(
            productId: p.id,
            productName: p.name,
            quantity: 12,
            unitCost: 2,
          ),
      ]),
      isNull,
    );
    expect(
      data.receivePurchase(data.purchases.last.id, [
        LotReceipt(
          productId: data.products[0].id,
          code: 'VALIDO',
          expiry: now.add(const Duration(days: 10)),
        ),
        LotReceipt(
          productId: data.products[1].id,
          code: 'INVALIDO',
          expiry: now.subtract(const Duration(days: 1)),
        ),
      ]),
      isNotNull,
    );
    expect(data.stockTotal, stock);
    expect(data.lots.where((l) => l.code == 'VALIDO'), isEmpty);
  });
  test('rechaza costos que se redondean a cero', () {
    expect(
      data.createPurchase('supplier-demo', [
        PurchaseLine(
          productId: data.products.first.id,
          productName: '',
          quantity: 1,
          unitCost: .001,
        ),
      ]),
      isNotNull,
    );
    data.openCashSession(10);
    expect(data.cashAdjustment(.001, 'No efectivo'), isNotNull);
    expect(data.cashMovements, isEmpty);
  });
  test('importes extremos se rechazan sin excepción ni modificación', () {
    data.openCashSession(10);
    expect(data.cashAdjustment(1e308, 'Extremo'), isNotNull);
    expect(data.cashAdjustment(-1e308, 'Extremo'), isNotNull);
    expect(
      data.createPurchase('supplier-demo', [
        PurchaseLine(
          productId: data.products.first.id,
          productName: '',
          quantity: 1,
          unitCost: 1e308,
        ),
      ]),
      isNotNull,
    );
    expect(data.expectedCash(data.openCash!), 10);
    expect(data.purchases, isEmpty);
  });
  test(
    'HTML del comprobante escapa datos, no ejecuta contenido del usuario',
    () {
      data.openCashSession(100);
      data.saveContact(
        kind: ContactKind.customer,
        name: '<script>alert(1)</script>',
      );
      data.addToCart(data.products.first);
      expect(
        data.checkoutSale(
          method: PaymentMethod.cash,
          tendered: 10,
          customerId: data.contacts.last.id,
        ),
        isNull,
      );
      final html = receiptHtml(data.sales.single);
      expect(html.contains('<script>'), isFalse);
      expect(html.contains('&lt;script&gt;'), isTrue);
      expect(html.contains('No es un documento fiscal'), isTrue);
    },
  );
  test(
    'venta necesita caja y efectivo suficiente; deja carrito intacto al fallar',
    () {
      data.addToCart(data.products.first);
      final stock = data.stockTotal;
      expect(
        data.checkoutSale(method: PaymentMethod.cash, tendered: 100),
        isNotNull,
      );
      data.openCashSession(100);
      expect(
        data.checkoutSale(method: PaymentMethod.cash, tendered: 0),
        isNotNull,
      );
      expect(data.stockTotal, stock);
      expect(data.cart, hasLength(1));
      sale();
      expect(data.sales, hasLength(1));
      expect(data.cart, isEmpty);
    },
  );
  test('cobro calcula cambio, FEFO, ingreso neto y comprobante histórico', () {
    data.openCashSession(100);
    final price = data.products.first.price;
    final stock = data.stockTotal;
    sale();
    expect(data.sales.single.change, 100 - price);
    expect(data.expectedCash(data.openCash!), 100 + price);
    expect(data.stockTotal, stock - 1);
    expect(data.revenueToday, price);
    final p = data.products.first;
    expect(
      data.registerProduct(
        id: p.id,
        code: p.code,
        name: 'Nombre cambiado',
        category: p.category,
        presentation: p.presentation,
        unit: p.unit,
        price: price + 5,
        minimum: p.minimum,
        barcode: p.barcode,
      ),
      isNull,
    );
    expect(data.sales.single.lines.single.name, p.name);
    expect(data.sales.single.total, price);
    expect(() => data.sales.single.lines.clear(), throwsUnsupportedError);
  });
  test('tarjeta y transferencia no aumentan efectivo físico', () {
    data.openCashSession(100);
    sale(method: PaymentMethod.card);
    sale(method: PaymentMethod.transfer);
    expect(data.sales, hasLength(2));
    expect(data.expectedCash(data.openCash!), 100);
    expect(data.cashMovements, isEmpty);
  });
  test('anular devuelve lotes y efectivo una sola vez y excluye ingreso', () {
    final stock = data.stockTotal;
    data.openCashSession(100);
    sale();
    final id = data.sales.single.id;
    expect(data.cancelSale(id, ''), isNotNull);
    expect(data.cancelSale(id, 'Error de captura'), isNull);
    expect(data.stockTotal, stock);
    expect(data.expectedCash(data.openCash!), 100);
    expect(data.revenueToday, 0);
    expect(data.cancelSale(id, 'Duplicado'), isNotNull);
    expect(data.stockTotal, stock);
  });
  test('pago proveedor requiere recepción/fondos y no se duplica', () {
    order();
    final id = data.purchases.single.id;
    expect(data.payPurchase(id, PaymentMethod.cash), isNotNull);
    receive();
    data.openCashSession(0);
    expect(data.payPurchase(id, PaymentMethod.cash), isNotNull);
    expect(data.cashAdjustment(100, 'Fondo'), isNull);
    expect(data.payPurchase(id, PaymentMethod.cash), isNull);
    expect(data.expectedCash(data.openCash!), 64);
    expect(data.payPurchase(id, PaymentMethod.cash), isNotNull);
    expect(data.expectedCash(data.openCash!), 64);
  });
  test('salida no deja caja negativa y arqueo conserva diferencia', () {
    data.openCashSession(20);
    expect(data.openCashSession(20), isNotNull);
    expect(data.cashAdjustment(-21, 'Salida'), isNotNull);
    expect(data.cashAdjustment(-5, 'Salida'), isNull);
    data.addToCart(data.products.first);
    expect(data.closeCashSession(14), isNotNull);
    data.clearCart();
    expect(data.closeCashSession(14), isNull);
    expect(data.openCash, isNull);
    expect(
      data.cashSessions.single.counted! -
          data.expectedCash(data.cashSessions.single),
      -1,
    );
  });
  test('archivar contactos conserva historial pero bloquea nuevas compras', () {
    order();
    expect(data.toggleContact('supplier-demo'), isNull);
    expect(data.purchases.single.supplierName, 'Proveedor general');
    expect(
      data.createPurchase('supplier-demo', data.purchases.single.lines),
      isNotNull,
    );
    expect(data.toggleContact('supplier-demo'), isNull);
    expect(
      data.saveContact(
        kind: ContactKind.customer,
        name: 'Persona',
        email: 'invalido',
      ),
      isNotNull,
    );
  });
  test('producto archivado conserva físico y excluye disponibilidad', () {
    final p = data.products.first;
    final physical = data.stockTotal;
    final available = data.availableTotal;
    final pStock = data.availableStock(p);
    expect(data.toggleProduct(p.id), isNull);
    expect(data.stockTotal, physical);
    expect(data.availableTotal, available - pStock);
    expect(data.addToCart(data.products.first), isFalse);
  });
  test(
    'incidente requiere solución; tiempos se derivan de registros reales',
    () {
      expect(
        data.saveIncident(
          title: 'Problema',
          description: 'Detalle',
          priority: 'Alta',
        ),
        isNull,
      );
      final id = data.incidents.single.id;
      now = now.add(const Duration(minutes: 30));
      expect(
        data.saveIncident(
          id: id,
          title: 'Problema',
          description: 'Detalle',
          priority: 'Alta',
          status: IncidentStatus.resolved,
        ),
        isNotNull,
      );
      expect(
        data.saveIncident(
          id: id,
          title: 'Problema',
          description: 'Detalle',
          priority: 'Alta',
          status: IncidentStatus.resolved,
          resolution: 'Solucionado',
        ),
        isNull,
      );
      expect(
        data.incidents.single.resolvedAt!
            .difference(data.incidents.single.createdAt)
            .inMinutes,
        30,
      );
    },
  );
  test(
    'empleado no ejecuta comandos administrativos ni restaura respaldos',
    () {
      final employee = PharmacyController(
        userProvider: () => AuthController.demoUsers.last,
      );
      addTearDown(employee.dispose);
      expect(
        employee.saveContact(kind: ContactKind.customer, name: 'Cliente'),
        isNull,
      );
      expect(
        employee.saveContact(kind: ContactKind.supplier, name: 'Proveedor'),
        isNotNull,
      );
      expect(employee.toggleProduct(employee.products.first.id), isNotNull);
      expect(
        employee.adjustLot(employee.lots.first.id, 1, 'Ajuste'),
        isNotNull,
      );
      expect(employee.createPurchase('supplier-demo', []), isNotNull);
      expect(employee.restoreBackup(data.createBackup()), isNotNull);
    },
  );
  test(
    'snapshot roundtrip conserva dominio y no incluye sesión/carrito/contraseña',
    () {
      data.openCashSession(100);
      order();
      receive();
      sale();
      data.addToCart(data.products.first);
      final raw = data.createBackup();
      final clone = PharmacyController(seedDemo: false);
      addTearDown(clone.dispose);
      expect(clone.restoreBackup(raw), isNull);
      expect(clone.stockTotal, data.stockTotal);
      expect(
        clone.expectedCash(clone.openCash!),
        data.expectedCash(data.openCash!),
      );
      expect(clone.sales.single.total, data.sales.single.total);
      expect(clone.cart, isEmpty);
      expect(raw.contains('"password":'), isFalse);
      expect(
        () => clone.sales.single.lines.single.allocations.clear(),
        throwsUnsupportedError,
      );
    },
  );
  for (final corruption in [
    'version',
    'duplicate',
    'foreignKey',
    'negative',
    'date',
    'sequence',
  ]) {
    test('respaldo $corruption se rechaza sin reemplazo parcial', () {
      final before = data.stockTotal;
      final j = jsonDecode(data.createBackup()) as Map<String, dynamic>;
      switch (corruption) {
        case 'version':
          j['version'] = 999;
        case 'duplicate':
          j['products'].add(j['products'].first);
        case 'foreignKey':
          j['lots'].first['productId'] = 'missing';
        case 'negative':
          j['lots'].first['quantity'] = -12;
        case 'date':
          j['lots'].first['expiry'] = '2026-02-31T00:00:00.000';
        case 'sequence':
          j['sequence'] = 0;
      }
      expect(data.restoreBackup(jsonEncode(j)), isNotNull);
      expect(data.stockTotal, before);
      expect(data.products, hasLength(8));
    });
  }
  test(
    'persistencia serializada conserva última revisión tras recrear controlador',
    () async {
      final store = MemoryAdministrationStore();
      final local = PharmacyController(store: store);
      addTearDown(local.dispose);
      await local.initialize();
      for (var i = 0; i < 5; i++) {
        local.saveContact(kind: ContactKind.customer, name: 'Cliente $i');
      }
      await local.flush();
      final reload = PharmacyController(store: store);
      addTearDown(reload.dispose);
      await reload.initialize();
      expect(reload.contacts, hasLength(7));
      expect(reload.storageError, isNull);
    },
  );
  test(
    'fallo lectura bloquea cambios sin sobrescribir y permite recuperar',
    () async {
      final store = FailingStore(failRead: true)..data = 'original';
      final local = PharmacyController(store: store);
      addTearDown(local.dispose);
      await local.initialize();
      expect(local.loadFailed, isTrue);
      expect(local.openCashSession(0), isNotNull);
      await local.flush();
      expect(store.data, 'original');
      expect(local.restoreBackup(data.createBackup()), isNull);
      await local.flush();
      expect(local.loadFailed, isFalse);
      expect(jsonDecode(store.data!)['version'], 2);
    },
  );
  test('fallo guardado muestra error y reintento guarda', () async {
    final store = FailingStore(failWrite: true);
    final local = PharmacyController(store: store);
    addTearDown(local.dispose);
    await local.initialize();
    await local.flush();
    expect(local.storageError, isNotNull);
    store.failWrite = false;
    local.retrySaving();
    await local.flush();
    expect(local.storageError, isNull);
    expect(store.data, isNotNull);
  });
  test('reportes respetan período y usan operaciones reales', () {
    data.openCashSession(100);
    sale();
    final report = LocalReportBuilder.build(
      data,
      LocalReportKind.sales,
      data.today,
      data.today,
    );
    expect(report.rows, hasLength(1));
    expect(
      report.rows.single[report.headers.indexOf('Total')],
      data.sales.single.total,
    );
    final other = now.add(const Duration(days: 1));
    expect(
      LocalReportBuilder.build(data, LocalReportKind.sales, other, other).rows,
      isEmpty,
    );
  });
  test('CSV neutraliza fórmulas y escapa separadores/comillas', () {
    final csv = buildCsv(
      ['Nombre', 'Valor'],
      [
        ['=1+1', -12],
        ['A,"B"', 2],
      ],
    );
    expect(csv.startsWith('\uFEFF'), isTrue);
    expect(csv.contains("'=1+1"), isTrue);
    expect(csv.contains('A,""B""'), isTrue);
    expect(csv.contains('"-12"'), isTrue);
  });
  test('perfil persiste nombre/teléfono sin permitir elevar rol', () async {
    final store = MemoryPreferencesStore();
    final auth = AuthController(profiles: store);
    addTearDown(auth.dispose);
    await auth.signIn(
      AuthController.demoUsers.last.username,
      AuthController.demoPassword,
    );
    auth.updateProfile(name: 'Empleado local', phone: '12345678');
    await auth.flushProfile();
    final next = AuthController(profiles: store);
    addTearDown(next.dispose);
    await next.signIn(
      AuthController.demoUsers.last.username,
      AuthController.demoPassword,
    );
    expect(next.user!.name, 'Empleado local');
    expect(next.user!.isAdministrator, isFalse);
    expect(store.data!.contains('password'), isFalse);
    expect(store.data!.contains('role'), isFalse);
  });
}
