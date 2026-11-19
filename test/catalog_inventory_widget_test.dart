import 'package:flutter/material.dart';
import 'package:farmacia_sae/models/contacts/models/contact.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/core/routing/app_router.dart';
import 'package:farmacia_sae/core/routing/app_paths.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/models/inventory/views/inventory_page.dart';
import 'package:farmacia_sae/models/products/views/products_page.dart';
import 'package:farmacia_sae/shared/themes/app_theme.dart';

/// Revisa el flujo real de ambas vistas, no solo los comandos del controlador.
void main() {
  testWidgets('registrar ficha y recibir 12 cajas sin duplicar producto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = AuthController();
    final signingIn = auth.signIn(
      AuthController.demoUsers.first.username,
      AuthController.demoPassword,
    );
    await tester.pump(const Duration(milliseconds: 450));
    await signingIn;
    final controller = PharmacyController(seedDemo: false);
    controller.saveContact(
      kind: ContactKind.supplier,
      name: 'Proveedor de prueba',
    );
    final router = createAppRouter(
      auth: auth,
      pharmacyProvider: () => controller,
      initialLocation: '/administracion/productos',
    );
    addTearDown(router.dispose);
    addTearDown(auth.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar producto'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lot-quantity')), findsNothing);
    for (final (name, value) in [
      ('category', 'Analgésicos'),
      ('presentation', 'Tabletas / pastillas'),
    ]) {
      final field = find.byKey(Key('product-$name'));
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.tap(find.text(value).last);
      await tester.pumpAndSettle();
    }
    for (final entry in {
      'code': 'MED-TEST',
      'name': 'Producto de prueba',
      'unit': 'Caja',
      'minimum': '5',
    }.entries) {
      final field = find.byKey(Key('product-${entry.key}'));
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value);
    }
    final infoTab = find.byKey(const Key('product-tab-1'));
    await tester.ensureVisible(infoTab);
    await tester.tap(infoTab);
    await tester.pumpAndSettle();
    final measure = find.byKey(const Key('product-measure'));
    await tester.ensureVisible(measure);
    await tester.enterText(measure, 'mg');
    await tester.ensureVisible(find.byKey(const Key('product-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('product-save')));
    await tester.pumpAndSettle();
    expect(controller.products, hasLength(1));
    expect(controller.stockTotal, 0);
    expect(controller.products.single.price, 0);
    final productId = controller.products.single.id;
    await tester.ensureVisible(find.text('Ir a inventario y lotes'));
    await tester.tap(find.text('Ir a inventario y lotes'));
    await tester.pumpAndSettle();
    expect(find.text('Recibir lote'), findsNothing);
    await tester.tap(find.text('Ir a compras'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva compra'));
    await tester.pumpAndSettle();
    final productSearch = find.descendant(
      of: find.byKey(const Key('purchase-product')),
      matching: find.byType(TextField),
    );
    await tester.enterText(productSearch, 'Producto de prueba');
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Producto de prueba · Tabletas / pastillas').last,
    );
    await tester.pumpAndSettle();
    final supplier = find.byKey(
      Key('purchase-supplier-$productId-false-false'),
    );
    await tester.ensureVisible(supplier);
    await tester.tap(supplier);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Proveedor de prueba').last);
    await tester.pumpAndSettle();
    final cost = find.byKey(const Key('purchase-cost'));
    await tester.ensureVisible(cost);
    await tester.enterText(cost, '5');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('purchase-save')));
    await tester.pumpAndSettle();
    final orderId = controller.purchases.single.id;
    expect(controller.suppliersForProduct(productId), hasLength(1));
    await tester.tap(find.text(orderId));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recibir lotes'));
    await tester.pumpAndSettle();
    final expiry = controller.today
        .add(const Duration(days: 365))
        .toIso8601String()
        .substring(0, 10);
    await tester.ensureVisible(find.text('Añadir otro lote'));
    await tester.tap(find.text('Añadir otro lote'));
    await tester.pumpAndSettle();
    for (final (suffix, code, quantity) in [
      ('', 'LT-TEST-A', '7'),
      ('-2', 'LT-TEST-B', '5'),
    ]) {
      for (final entry in {
        'batch': code,
        'quantity': quantity,
        'manufactured': controller.today
            .subtract(const Duration(days: 100))
            .toIso8601String()
            .substring(0, 10),
        'location': 'Estante A - 1',
        'expiry': expiry,
      }.entries) {
        final field = find.byKey(Key('${entry.key}-$productId$suffix'));
        await tester.ensureVisible(field);
        await tester.enterText(field, entry.value);
      }
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar recepción'));
    await tester.pumpAndSettle();
    expect(controller.products, hasLength(1));
    expect(controller.lots.map((lot) => lot.quantity), [7, 5]);
    expect(controller.stockTotal, 12);
    expect(
      controller.purchases.single.receivedLots.map((lot) => lot.quantity),
      [7, 5],
    );
    await tester.ensureVisible(find.text('LT-TEST-A · 7 ud.'));
    await tester.tap(find.text('LT-TEST-A · 7 ud.'));
    await tester.pumpAndSettle();
    expect(find.text('Ver proveedor'), findsOneWidget);
    router.go(AppPaths.sections[2]);
    await tester.pumpAndSettle();
    expect(find.textContaining('12 · Caja'), findsOneWidget);
    final search = find.byKey(const Key('inventory-search'));
    await tester.ensureVisible(search);
    await tester.enterText(search, 'MED-TEST');
    await tester.ensureVisible(find.text('Abrir catálogo de productos'));
    await tester.tap(find.text('Abrir catálogo de productos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ir a inventario y lotes'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, 'MED-TEST');
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('catálogo, inventario y formularios responsive a $width px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = PharmacyController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ProductsPage(controller: controller, onInventory: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar producto'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Cancelar'));
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: InventoryPage(controller: controller, onProducts: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Recibir lote'), findsNothing);
    });
  }
}
