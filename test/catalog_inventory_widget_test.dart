import 'package:flutter/material.dart';
import 'package:farmacia_sae/models/contacts/models/contact.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/core/routing/app_router.dart';
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
    for (final entry in {
      'code': 'MED-TEST',
      'name': 'Producto de prueba',
      'category': 'Analgésicos',
      'presentation': 'Caja de 10 tabletas',
      'unit': 'Caja',
      'measure': 'mg',
      'origin': 'Nicaragua',
      'manufacturer': 'Laboratorio de prueba',
      'minimum': '5',
    }.entries) {
      final field = find.byKey(Key('product-${entry.key}'));
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value);
    }
    await tester.ensureVisible(find.byKey(const Key('product-save')));
    // El selector de imagen alarga el formulario: espera también el scroll
    // automático del último campo enfocado antes de pulsar el botón visible.
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('product-save')));
    await tester.pumpAndSettle();
    expect(controller.products, hasLength(1));
    expect(controller.stockTotal, 0);
    expect(controller.products.single.price, 0);
    await tester.ensureVisible(find.text('Ir a inventario y lotes'));
    await tester.tap(find.text('Ir a inventario y lotes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recibir lote'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lot-product')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MED-TEST · Producto de prueba').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('lot-supplier')));
    await tester.tap(find.byKey(const Key('lot-supplier')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proveedor de prueba').last);
    await tester.pumpAndSettle();
    final expiry = controller.today
        .add(const Duration(days: 365))
        .toIso8601String()
        .substring(0, 10);
    for (final entry in {
      'code': 'LT-TEST-A',
      'quantity': '12',
      'manufactured': controller.today
          .subtract(const Duration(days: 100))
          .toIso8601String()
          .substring(0, 10),
      'location': 'Estante A - 1',
      'price': '10.50',
      'expiry': expiry,
    }.entries) {
      final field = find.byKey(Key('lot-${entry.key}'));
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value);
    }
    await tester.ensureVisible(find.byKey(const Key('lot-save')));
    await tester.tap(find.byKey(const Key('lot-save')));
    await tester.pumpAndSettle();
    expect(controller.products, hasLength(1));
    expect(controller.lots, hasLength(1));
    expect(controller.stockTotal, 12);
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
      await tester.tap(find.text('Recibir lote'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
    });
  }
}
