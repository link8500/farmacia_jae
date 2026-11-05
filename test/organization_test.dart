import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';
import 'package:farmacia_sae/core/services/local_administration_store.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/models/auth/models/session_user.dart';
import 'package:farmacia_sae/models/organization/models/organization.dart';
import 'package:farmacia_sae/models/purchases/models/purchase_order.dart';
import 'package:farmacia_sae/models/reports/models/local_report.dart';
import 'package:farmacia_sae/models/reports/models/sales_analytics.dart';
import 'package:farmacia_sae/models/sales/models/sale_receipt.dart';
import 'package:farmacia_sae/models/sales/widgets/receipt_dialog.dart';

/// Invariantes multisedes y trazabilidad: se prueban los comandos directamente,
/// no solamente que la interfaz oculte botones.
void main() {
  late PharmacyController data;
  late SessionUser actor;
  late DateTime now;
  setUp(() {
    actor = AuthController.demoUsers.first;
    now = DateTime(2026, 10, 21, 10);
    data = PharmacyController(userProvider: () => actor, clock: () => now);
  });
  tearDown(() => data.dispose());
  test(
    'cada fila exportable conserva la correspondencia con sus encabezados',
    () {
      data.addToCart(data.products.first);
      expect(
        data.checkoutSale(method: PaymentMethod.cash, tendered: 10),
        isNull,
      );
      for (final kind in LocalReportKind.values) {
        final report = LocalReportBuilder.build(
          data,
          kind,
          data.today,
          data.today,
        );
        for (final row in report.rows) {
          expect(row.length, report.headers.length, reason: kind.name);
        }
      }
    },
  );
  test('sin sesión no se exponen inventario, cajas ni comprobantes', () {
    final privateData = PharmacyController(userProvider: () => null);
    addTearDown(privateData.dispose);
    expect(privateData.products, isEmpty);
    expect(privateData.lots, isEmpty);
    expect(privateData.sales, isEmpty);
    expect(privateData.registers, isEmpty);
    expect(privateData.isAdministrator, isFalse);
    expect(privateData.createBackup, throwsStateError);
  });
  void login(SessionUser user) {
    actor = user;
    data.recordSessionChange(user);
  }

  String branch() {
    expect(data.saveBranch(name: 'Sucursal 2'), isNull);
    return data.branches.last.id;
  }

  String register(String branchId, {String name = 'Caja 3'}) {
    expect(data.saveRegister(branchId: branchId, name: name), isNull);
    return data.registers.last.id;
  }

  void assign(
    String id,
    String branchId,
    String registerId, {
    bool active = true,
  }) {
    final member = data.staffById(id)!;
    expect(
      data.saveStaff(
        id: id,
        name: member.name,
        username: member.username,
        branchId: branchId,
        registerId: registerId,
        active: active,
      ),
      isNull,
    );
  }

  void stock(
    String productId, {
    String code = 'MISMO-LOTE',
    int quantity = 12,
    int days = 20,
  }) {
    expect(
      data.receiveLot(
        productId: productId,
        code: code,
        quantity: quantity,
        expiry: now.add(Duration(days: days)),
      ),
      isNull,
    );
  }

  void sell({PaymentMethod method = PaymentMethod.cash}) {
    expect(data.addToCart(data.products.first), isTrue);
    expect(data.checkoutSale(method: method, tendered: 100), isNull);
  }

  test('empleado ve únicamente catálogo y lotes habilitados de su sede', () {
    final product = data.products.first;
    final id = branch();
    data.selectBranch(id);
    expect(data.products, isEmpty);
    expect(data.lots, isEmpty);
    expect(data.setBranchProduct(id, product.id, true), isNull);
    stock(product.id);
    login(AuthController.demoUsers.last);
    expect(data.workingBranchId, mainBranchId);
    expect(data.lots.every((l) => l.branchId == mainBranchId), isTrue);
    expect(data.selectBranch(id), isNotNull);
    expect(data.masterProducts.length, data.products.length);
    expect(data.registers.map((r) => r.id), ['register-main-1']);
  });
  test(
    'misma ficha y lote en dos sedes tienen saldos independientes y FEFO local',
    () {
      final product = data.products.first;
      final before = data.availableStock(product);
      stock(product.id, days: 1);
      final id = branch(), box = register(data.branches.last.id);
      data.setBranchProduct(id, product.id, true);
      data.selectBranch(id);
      stock(product.id, quantity: 4, days: 10);
      assign('demo-employee', id, box);
      login(AuthController.demoUsers.last);
      expect(data.availableStock(product), 4);
      sell();
      final sale = data.sales.single;
      expect(sale.actorId, 'demo-employee');
      expect(sale.branchId, id);
      expect(sale.registerId, box);
      expect(data.availableStock(product), 3);
      expect(data.lots.single.id, sale.lines.single.allocations.single.lotId);
      expect(data.cashSessions, isEmpty);
      expect(data.cashMovements, isEmpty);
      login(AuthController.demoUsers.first);
      data.selectBranch(mainBranchId);
      expect(data.availableStock(product), before + 12);
    },
  );
  test(
    'producto exclusivo de otra sede no se consulta ni se añade por objeto o ID',
    () {
      final id = branch();
      data.selectBranch(id);
      expect(
        data.registerProduct(
          code: 'EXCLUSIVO',
          name: 'Exclusivo',
          category: 'General',
          presentation: 'Caja',
          unit: 'Caja',
          minimum: 0,
          price: 9,
        ),
        isNull,
      );
      final product = data.products.single;
      stock(product.id);
      login(AuthController.demoUsers.last);
      expect(data.productById(product.id), isNull);
      expect(data.products.any((p) => p.id == product.id), isFalse);
      expect(data.addToCart(product), isFalse);
      expect(data.availableStock(product), 0);
      expect(
        data.receiveLot(
          productId: product.id,
          code: 'FORANEO',
          quantity: 1,
          expiry: now.add(const Duration(days: 1)),
        ),
        isNotNull,
      );
    },
  );
  test(
    'empleado no modifica personal, cajas, sucursales ni catálogo maestro',
    () {
      login(AuthController.demoUsers.last);
      expect(data.saveBranch(name: 'No'), isNotNull);
      expect(data.createBackup, throwsStateError);
      expect(data.saveRegister(branchId: mainBranchId, name: 'No'), isNotNull);
      expect(
        data.saveStaff(name: 'Otro', username: 'otro', branchId: mainBranchId),
        isNotNull,
      );
      expect(
        data.setBranchProduct(mainBranchId, data.products.first.id, false),
        isNotNull,
      );
      expect(
        data.registerProduct(
          code: 'NO',
          name: 'No',
          category: 'A',
          presentation: 'A',
          unit: 'A',
          minimum: 0,
          price: 1,
        ),
        isNotNull,
      );
    },
  );
  test('caja de otra sede, ocupada o inactiva no admite asignación', () {
    final id = branch(), box = register(data.branches.last.id);
    final member = data.staffById('demo-employee')!;
    String? attempt(String branchId, String registerId) => data.saveStaff(
      id: member.id,
      name: member.name,
      username: member.username,
      branchId: branchId,
      registerId: registerId,
    );
    expect(attempt(mainBranchId, box), isNotNull);
    expect(attempt(mainBranchId, 'register-main-2'), isNotNull);
    expect(
      data.saveRegister(id: box, branchId: id, name: 'Caja 3', active: false),
      isNull,
    );
    expect(attempt(id, box), isNotNull);
    expect(data.staffById(member.id)!.registerId, 'register-main-1');
  });
  test('sin caja no se cobra y no se toca carrito ni stock', () {
    assign('demo-employee', mainBranchId, '');
    login(AuthController.demoUsers.last);
    data.addToCart(data.products.first);
    final before = data.stockTotal;
    expect(data.billingAssignmentError, isNotNull);
    expect(
      data.checkoutSale(method: PaymentMethod.card, tendered: 10),
      isNotNull,
    );
    expect(data.cart, hasLength(1));
    expect(data.stockTotal, before);
    expect(data.sales, isEmpty);
  });
  test(
    'cambiar sede descarta carrito, editar otra persona no descarta la venta propia',
    () {
      data.addToCart(data.products.first);
      final before = data.stockTotal;
      final id = branch();
      data.selectBranch(id);
      expect(data.cart, isEmpty);
      expect(data.billingAssignmentError, isNotNull);
      data.selectBranch(mainBranchId);
      expect(data.stockTotal, before);
      data.addToCart(data.products.first);
      assign('demo-employee', mainBranchId, '');
      expect(data.cart, hasLength(1));
      assign('demo-admin', mainBranchId, '');
      expect(data.cart, isEmpty);
    },
  );
  test(
    'factura conserva nombres y asignación después de reasignar y renombrar',
    () {
      login(AuthController.demoUsers.last);
      sell();
      final original = data.sales.single;
      login(AuthController.demoUsers.first);
      final id = branch(), box = register(data.branches.last.id);
      assign('demo-employee', id, box);
      data.saveBranch(id: mainBranchId, name: 'Sede renombrada');
      data.saveRegister(
        id: 'register-main-1',
        branchId: mainBranchId,
        name: 'Caja renombrada',
      );
      expect(data.sales.single.branchName, 'Sucursal principal');
      expect(data.sales.single.registerName, 'Caja 1');
      expect(data.sales.single.actorId, original.actorId);
      expect(receiptHtml(data.sales.single), contains('Caja 1'));
      expect(data.cancelSale(original.id, 'Prueba'), isNull);
      expect(data.sales.single.branchId, mainBranchId);
      expect(data.sales.single.registerId, 'register-main-1');
    },
  );
  test('caja y sucursal con personal asignado no se desactivan', () {
    expect(
      data.saveRegister(
        id: 'register-main-1',
        branchId: mainBranchId,
        name: 'Caja 1',
        active: false,
      ),
      isNotNull,
    );
    expect(
      data.saveBranch(id: mainBranchId, name: 'Principal', active: false),
      isNotNull,
    );
  });
  test(
    'compra se recibe en su sede original aunque el administrador cambie contexto',
    () {
      final product = data.products.first;
      data.createPurchase('supplier-demo', [
        PurchaseLine(
          productId: product.id,
          productName: product.name,
          quantity: 12,
          unitCost: 1,
        ),
      ]);
      final purchase = data.purchases.single;
      final id = branch();
      data.setBranchProduct(id, product.id, true);
      data.selectBranch(id);
      expect(data.purchases, isEmpty);
      expect(
        data.receivePurchase(purchase.id, [
          LotReceipt(
            productId: product.id,
            code: 'OC',
            expiry: now.add(const Duration(days: 10)),
          ),
        ]),
        isNotNull,
      );
      expect(data.lots, isEmpty);
      data.selectBranch(mainBranchId);
      expect(
        data.receivePurchase(purchase.id, [
          LotReceipt(
            productId: product.id,
            code: 'OC',
            expiry: now.add(const Duration(days: 10)),
          ),
        ]),
        isNull,
      );
      expect(data.lots.last.branchId, mainBranchId);
    },
  );
  test('reportes filtran por fecha, sede, caja, operador, método y estado', () {
    login(AuthController.demoUsers.last);
    sell();
    sell(method: PaymentMethod.card);
    final cancelled = data.sales.last.id;
    login(AuthController.demoUsers.first);
    data.cancelSale(cancelled, 'Error');
    sell(method: PaymentMethod.transfer);
    final all = const SalesReportFilter().apply(data, now, now);
    final totals = SalesTotals(all);
    expect(totals.count, 2);
    expect(totals.cancelledCount, 1);
    expect(totals.units, 2);
    expect(totals.net, 7);
    expect(totals.average, 3.5);
    expect(totals.byMethod(PaymentMethod.card), 0);
    expect(
      const SalesReportFilter(
        branchId: mainBranchId,
        registerId: 'register-main-1',
        actorId: 'demo-employee',
        method: PaymentMethod.cash,
        state: SaleReportState.valid,
      ).apply(data, now, now),
      hasLength(1),
    );
    expect(
      const SalesReportFilter().apply(
        data,
        now.add(const Duration(days: 1)),
        now.add(const Duration(days: 1)),
      ),
      isEmpty,
    );
    final grouped = LocalReportBuilder.build(
      data,
      LocalReportKind.salesByOperator,
      now,
      now,
    );
    expect(grouped.rows, hasLength(2));
    final detail = LocalReportBuilder.build(
      data,
      LocalReportKind.salesDetails,
      now,
      now,
    );
    expect(detail.rows, hasLength(3));
    expect(detail.headers, contains('Producto'));
    expect(
      LocalReportBuilder.build(data, LocalReportKind.sales, now, now).headers,
      containsAll(['Sucursal', 'Caja', 'Operador']),
    );
  });
  test('empleado no ve ventas de otro operador ni reportes de otra caja', () {
    sell();
    login(AuthController.demoUsers.last);
    sell();
    expect(data.sales, hasLength(1));
    expect(data.sales.single.actorId, 'demo-employee');
    expect(
      const SalesReportFilter(
        registerId: 'register-main-2',
      ).apply(data, now, now),
      isEmpty,
    );
    expect(data.cashSessions, isEmpty);
    expect(data.audit.every((a) => a.actorId == 'demo-employee'), isTrue);
  });
  test(
    'personal nuevo puede entrar al demo y desactivado deja de poder operar',
    () async {
      expect(
        data.saveStaff(
          name: 'Operador nuevo',
          username: 'operador2',
          branchId: mainBranchId,
        ),
        isNull,
      );
      final member = data.staff.last;
      expect(member.role, UserRole.employee);
      final auth = AuthController()..accountProvider = data.localLoginAccounts;
      addTearDown(auth.dispose);
      expect(await auth.signIn('operador2', '1234'), isNull);
      expect(auth.user!.id, member.id);
      assign(member.id, mainBranchId, '', active: false);
      login(auth.user!);
      expect(data.products, isEmpty);
      expect(
        data.checkoutSale(method: PaymentMethod.cash, tendered: 0),
        isNotNull,
      );
      expect(await auth.signIn('operador2', '1234'), isNotNull);
    },
  );
  test(
    'v2 persiste sedes, cajas, personal y metadatos tras recargar',
    () async {
      sell();
      final id = branch(), box = register(data.branches.last.id);
      assign('demo-employee', id, box);
      final store = MemoryAdministrationStore(data.createBackup());
      final restored = PharmacyController(store: store);
      addTearDown(restored.dispose);
      await restored.initialize();
      expect(restored.loadFailed, isFalse);
      expect(restored.branches, hasLength(2));
      expect(restored.staffById('demo-employee')!.registerId, box);
      expect(restored.sales.single.branchId, mainBranchId);
      expect(jsonDecode(restored.createBackup())['version'], 2);
    },
  );
  test(
    'respaldo v1 migra stock a principal sin inventar atribución histórica',
    () {
      sell();
      final json = jsonDecode(data.createBackup()) as Map<String, dynamic>;
      json['version'] = 1;
      for (final key in ['branches', 'registers', 'staff', 'branchProducts']) {
        json.remove(key);
      }
      for (final lot in json['lots']) {
        (lot as Map).remove('branchId');
      }
      for (final sale in json['sales']) {
        for (final key in [
          'actorId',
          'branchId',
          'branchName',
          'registerId',
          'registerName',
        ]) {
          (sale as Map).remove(key);
        }
      }
      final restored = PharmacyController(seedDemo: false);
      addTearDown(restored.dispose);
      expect(restored.restoreBackup(jsonEncode(json)), isNull);
      expect(restored.lots.every((l) => l.branchId == mainBranchId), isTrue);
      expect(restored.sales.single.branchId, isEmpty);
      expect(restored.sales.single.registerId, isEmpty);
      expect(restored.sales.single.actorName, isNotEmpty);
    },
  );
  for (final corruption in [
    'assignment',
    'doubleOperator',
    'saleBranch',
    'lotBranch',
    'missingDirectory',
  ]) {
    test('respaldo rechaza $corruption sin reemplazo parcial', () {
      sell();
      final json = jsonDecode(data.createBackup()) as Map<String, dynamic>;
      switch (corruption) {
        case 'assignment':
          json['staff'].last['registerId'] = 'otra-sede';
        case 'doubleOperator':
          json['staff'].last['registerId'] = json['staff'].first['registerId'];
        case 'saleBranch':
          json['sales'].first['branchId'] = 'otra-sede';
        case 'lotBranch':
          json['lots'].first['branchId'] = 'otra-sede';
        case 'missingDirectory':
          json.remove('staff');
      }
      final before = data.stockTotal;
      expect(data.restoreBackup(jsonEncode(json)), isNotNull);
      expect(data.stockTotal, before);
      expect(data.sales, hasLength(1));
    });
  }
}
