import 'package:farmacia_sae/core/routing/app_paths.dart';
import 'package:farmacia_sae/core/routing/app_router.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/models/home/widgets/sidebar.dart';
import 'package:farmacia_sae/models/incidents/models/support_case.dart';
import 'package:farmacia_sae/models/products/models/product_classification.dart';
import 'package:farmacia_sae/shared/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> signIn(
  WidgetTester tester,
  AuthController auth,
  int account,
) async {
  final pending = auth.signIn(
    AuthController.demoUsers[account].username,
    AuthController.demoPassword,
  );
  await tester.pump(const Duration(milliseconds: 450));
  await pending;
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('los catálogos personalizados alimentan la ficha y el respaldo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final auth = AuthController();
    final data = PharmacyController(seedDemo: false);
    final restored = PharmacyController(seedDemo: false);
    addTearDown(auth.dispose);
    addTearDown(data.dispose);
    addTearDown(restored.dispose);
    await signIn(tester, auth, 0);
    final router = createAppRouter(
      auth: auth,
      pharmacyProvider: () => data,
      initialLocation: AppPaths.products,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    const classifications = 'Gestionar categorías y presentaciones';
    expect(
      find.descendant(
        of: find.byType(Sidebar),
        matching: find.text(classifications),
      ),
      findsNothing,
    );
    final search = find.byKey(const Key('products-search'));
    await tester.enterText(search, 'filtro de prueba');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, classifications));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      AppPaths.productClassifications,
    );
    expect(
      tester.widget<Sidebar>(find.byType(Sidebar)).selected,
      AppPaths.indexOf(AppPaths.products),
    );
    expect(
      data.registerProduct(
        code: 'TEST-CLAS',
        name: 'Producto de prueba',
        category: 'Analgésicos',
        presentation: 'Gomas / gomitas',
        unit: 'Envase',
        minimum: 0,
      ),
      isNull,
    );
    for (final (type, name) in [
      (ProductClassification.category, 'Salud bucal'),
      (ProductClassification.presentation, 'Tiras solubles'),
    ]) {
      await tester.tap(find.text(type.plural));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agregar ${type.label.toLowerCase()}'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('classification-name')),
        name,
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(data.classificationOptions(type), contains(name));
    }
    expect(
      data.saveClassificationOption(
        ProductClassification.category,
        '  salud   bucal ',
      ),
      isNotNull,
    );
    await tester.tap(find.text('Categorías'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('classification-actions-Analgésicos')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('classification-name')),
      'Dolor y fiebre',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(data.products.single.category, 'Dolor y fiebre');
    expect(
      data.deleteClassificationOption(
        ProductClassification.category,
        'Dolor y fiebre',
      ),
      isNotNull,
    );
    await tester.tap(
      find.byKey(const Key('classification-actions-Antialérgicos')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(restored.restoreBackup(data.createBackup()), isNull);
    expect(
      restored.classificationOptions(ProductClassification.category),
      isNot(contains('Antialérgicos')),
    );
    expect(
      restored.classificationOptions(ProductClassification.category),
      isNot(contains('Analgésicos')),
    );
    expect(
      restored.classificationOptions(ProductClassification.presentation),
      contains('Tiras solubles'),
    );
    await tester.tap(find.text('Volver a productos'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppPaths.products);
    expect(
      tester.widget<TextField>(search).controller!.text,
      'filtro de prueba',
    );
    await tester.tap(find.text('Registrar producto'));
    await tester.pumpAndSettle();
    List<String> optionsFor(ProductClassification type) => tester
        .widget<DropdownButton<String>>(
          find.descendant(
            of: find.byKey(Key('product-${type.name}')),
            matching: find.byType(DropdownButton<String>),
          ),
        )
        .items!
        .map((item) => item.value!)
        .toList();
    expect(optionsFor(ProductClassification.category), contains('Salud bucal'));
    expect(
      optionsFor(ProductClassification.category),
      contains('Dolor y fiebre'),
    );
    expect(
      optionsFor(ProductClassification.category),
      isNot(contains('Antialérgicos')),
    );
    expect(
      optionsFor(ProductClassification.presentation),
      containsAll(['Gomas / gomitas', 'Tiras solubles']),
    );
  });

  testWidgets('el empleado envía y el administrador gestiona por otra ruta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final auth = AuthController();
    final data = PharmacyController(userProvider: () => auth.user);
    addTearDown(auth.dispose);
    addTearDown(data.dispose);
    await signIn(tester, auth, 1);
    final router = createAppRouter(
      auth: auth,
      pharmacyProvider: () => data,
      initialLocation: AppPaths.support,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    final requester = auth.user!.name;
    await tester.enterText(
      find.byKey(const Key('support-title')),
      'No abre el comprobante',
    );
    await tester.enterText(
      find.byKey(const Key('support-description')),
      'Al terminar una factura no se abrió su detalle.',
    );
    await tester.ensureVisible(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();
    expect(
      find.text('Solicitud enviada al panel de soporte de este navegador.'),
      findsOneWidget,
    );
    expect(find.text('No abre el comprobante'), findsNothing);
    expect(data.incidents, isEmpty);
    expect(
      data.saveIncident(
        id: 'INC-000001',
        title: 'Editar',
        description: 'Editar',
        priority: 'Alta',
      ),
      isNotNull,
    );
    router.go(AppPaths.supportRequests);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppPaths.profile);
    router.go(AppPaths.products);
    await tester.pumpAndSettle();
    expect(find.text('Gestionar categorías y presentaciones'), findsNothing);
    router.go(AppPaths.productClassifications);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppPaths.profile);
    auth.signOut();
    await tester.pumpAndSettle();
    await signIn(tester, auth, 0);
    router.go(AppPaths.supportRequests);
    await tester.pumpAndSettle();
    expect(find.text('Enviar solicitud'), findsNothing);
    expect(data.incidents.single.requestedBy, requester);
    await tester.tap(find.text('No abre el comprobante'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Actualizar solicitud'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('incident-status')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resuelto').last);
    await tester.pumpAndSettle();
    final resolution = find.byKey(const Key('incident-resolution'));
    await tester.ensureVisible(resolution);
    await tester.enterText(resolution, 'Se verificó el historial de facturas.');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(data.incidents.single.status, IncidentStatus.resolved);
    expect(data.incidents.single.requestedBy, requester);
    expect(tester.takeException(), isNull);
  });
}
