import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/core/utils/form_validators.dart';
import 'package:farmacia_sae/core/routing/app_paths.dart';
import 'package:farmacia_sae/models/home/models/admin_modules.dart';

/// Pruebas del dominio: producto 1:N lotes, sumas, validación y ventas FEFO.
void main() {
  late PharmacyController controller;
  late DateTime now;
  String? register({String code = 'MED-TEST', String barcode = ''}) =>
      controller.registerProduct(
        code: code,
        name: 'Medicamento de prueba',
        category: 'Analgésicos',
        presentation: 'Caja de 10 tabletas',
        unit: 'Caja',
        price: 10,
        minimum: 5,
        barcode: barcode,
      );
  String? receive(String code, int quantity, int days, {String? productId}) =>
      controller.receiveLot(
        productId: productId ?? controller.products.first.id,
        code: code,
        quantity: quantity,
        expiry: now.add(Duration(days: days)),
      );

  setUp(() {
    now = DateTime(2026, 10, 13);
    controller = PharmacyController(
      seedDemo: false,
      clock: () => now,
      cashEnabled: true,
    );
    controller.openCashSession(0);
  });
  tearDown(() => controller.dispose());

  test('una ficha nueva no crea stock ni un lote con vencimiento ficticio', () {
    expect(register(), isNull);
    expect(controller.products, hasLength(1));
    expect(controller.lots, isEmpty);
    expect(controller.availableStock(controller.products.single), 0);
    expect(
      controller.summaryFor(controller.products.single).nextExpiry,
      isNull,
    );
  });

  test(
    'recibir 12 unidades vincula un lote al producto sin duplicar ficha',
    () {
      register();
      expect(receive('LOTE-A', 12, 365), isNull);
      expect(controller.products, hasLength(1));
      expect(controller.lots.single.productId, controller.products.single.id);
      expect(controller.lots.single.quantity, 12);
      expect(controller.stockTotal, 12);
      expect(controller.lots.single.expiry, DateTime(2027, 10, 13));
    },
  );

  test('dos lotes suman stock y conservan vencimientos diferentes', () {
    register();
    receive('A', 12, 365);
    receive('B', 8, 30);
    final summary = controller.summaryFor(controller.products.single);
    expect(summary.availableQuantity, 20);
    expect(summary.lotCount, 2);
    expect(summary.nextExpiry, now.add(const Duration(days: 30)));
    expect(controller.expiringCount, 1);
    expect(controller.lowStockCount, 0);
  });

  test('recepciones inválidas no alteran el inventario', () {
    register();
    expect(receive('A', 12, 30, productId: 'no-existe'), isNotNull);
    expect(receive('A', 0, 30), isNotNull);
    expect(receive('A', -12, 30), isNotNull);
    expect(receive('', 12, 30), isNotNull);
    expect(receive('A', 12, -1), isNotNull);
    expect(controller.lots, isEmpty);
  });

  test('no permite repetir código de producto o barcode', () {
    register(barcode: '123');
    expect(register(code: ' med-test '), isNotNull);
    expect(register(code: 'OTRO', barcode: '123'), isNotNull);
    expect(controller.products, hasLength(1));
  });

  test('lote único por producto, no global, y sin doble recepción', () {
    register();
    receive('A', 12, 30);
    expect(receive(' a ', 12, 30), isNotNull);
    register(code: 'OTRO');
    expect(receive('A', 4, 30, productId: controller.products.last.id), isNull);
    expect(controller.stockTotal, 16);
  });

  test('FEFO consume primero el que vence antes aunque se recibió después', () {
    register();
    receive('LEJANO', 12, 365);
    receive('CERCANO', 2, 30);
    final product = controller.products.single;
    for (var i = 0; i < 3; i++) {
      expect(controller.addToCart(product), isTrue);
    }
    expect(controller.finishSale(), isTrue);
    expect(controller.lots.first.quantity, 11);
    expect(controller.lots.last.quantity, 0);
    expect(controller.cart, isEmpty);
  });

  test('no sobrevende ni descuenta al agregar o vaciar el carrito', () {
    register();
    receive('A', 2, 30);
    final product = controller.products.single;
    expect(controller.addToCart(product), isTrue);
    expect(controller.addToCart(product), isTrue);
    expect(controller.addToCart(product), isFalse);
    expect(controller.stockTotal, 2);
    controller.clearCart();
    expect(controller.stockTotal, 2);
    expect(controller.finishSale(), isFalse);
  });

  test('vencidos siguen en saldo físico pero no se pueden vender', () {
    register();
    receive('A', 12, 0);
    final product = controller.products.single;
    expect(controller.availableStock(product), 12); // Válido durante su fecha.
    now = now.add(const Duration(days: 1));
    expect(controller.stockTotal, 12);
    expect(controller.availableStock(product), 0);
    expect(controller.expiredCount, 1);
    expect(controller.expiringCount, 0);
    expect(controller.addToCart(product), isFalse);
  });

  test(
    'venta que perdió disponibilidad falla completa, sin descuentos parciales',
    () {
      register();
      receive('A', 3, 30);
      controller.addToCart(controller.products.first);
      register(code: 'OTRO');
      receive('B', 2, 0, productId: controller.products.last.id);
      controller.addToCart(controller.products.last);
      now = now.add(const Duration(days: 1));
      expect(controller.finishSale(), isFalse);
      expect(controller.lots.first.quantity, 3);
      expect(controller.lots.last.quantity, 2);
      expect(controller.cart, hasLength(2));
    },
  );

  test('búsqueda por lote y filtros de vencimiento no mezclan otros lotes', () {
    register();
    receive('A', 12, 365);
    receive('B', 8, 30);
    controller.setInventoryFilter('Por vencer');
    expect(controller.visibleInventory, hasLength(1));
    expect(controller.visibleLots.single.code, 'B');
    controller.setInventoryFilter('Todos');
    controller.setInventorySearch('A');
    // El nombre contiene A: buscar un código exclusivo de lote prueba el enlace.
    receive('EXCLUSIVO-999', 1, 365);
    controller.setInventorySearch('EXCLUSIVO-999');
    expect(controller.visibleLots.single.code, 'EXCLUSIVO-999');
    expect(controller.visibleInventory.single.availableQuantity, 21);
  });

  test('las colecciones operativas no se mutan desde las vistas', () {
    register();
    receive('A', 12, 365);
    expect(() => controller.products.clear(), throwsUnsupportedError);
    expect(() => controller.lots.clear(), throwsUnsupportedError);
    expect(() => controller.cart.clear(), throwsUnsupportedError);
  });

  test(
    'catálogo de módulos cubre cada ruta una vez y agrupa el abastecimiento',
    () {
      final indices =
          adminModules
              .expand((module) => module.items)
              .map((item) => item.index)
              .toList()
            ..sort();
      expect(indices, AppPaths.enabledSectionIndices);
      final supply = adminModules.singleWhere(
        (module) => module.id == 'abastecimiento',
      );
      expect(supply.items.map((item) => item.index), [10, 2, 3, 4]);
    },
  );

  test(
    'fechas imposibles, fracciones de unidades y precios inválidos se rechazan',
    () {
      expect(parseCalendarDate('2027-02-31'), isNull);
      expect(parseCalendarDate('2027-02-29'), isNull);
      expect(parseCalendarDate('2028-02-29'), DateTime(2028, 2, 29));
      expect(positiveInteger('1.5'), isNotNull);
      expect(positiveInteger('12'), isNull);
      expect(positiveAmount('NaN'), isNotNull);
      expect(positiveAmount('Infinity'), isNotNull);
      expect(positiveAmount('-1'), isNotNull);
      expect(positiveAmount('10,50'), isNull);
    },
  );

  test('nombres del menú cambian sin mover vistas ni alterar URLs', () {
    final dashboard = adminModules.singleWhere((m) => m.id == 'supervision');
    expect(dashboard.label, 'Dashboard');
    expect(dashboard.items.map((i) => i.label), ['Resumen', 'Reportes']);
    final purchase = adminModules.singleWhere((m) => m.id == 'abastecimiento');
    expect(purchase.label, 'Inventario');
    expect(purchase.items.map((i) => i.label), [
      'Productos',
      'Lotes',
      'Compras',
      'Proveedores',
    ]);
    final sales = adminModules.singleWhere((m) => m.id == 'ventas');
    expect(sales.label, 'Ventas');
    expect(sales.items.map((i) => i.label), [
      'Cajas de facturación',
      'Facturación',
      'Clientes',
    ]);
    expect(AppPaths.titles[1], 'Facturación');
    expect(AppPaths.titles[2], 'Lotes');
    expect(AppPaths.sections[1], '/administracion/ventas');
    expect(AppPaths.sections[2], '/administracion/inventario');
  });
}
