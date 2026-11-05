import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:farmacia_sae/core/routing/app_paths.dart';
import 'package:farmacia_sae/core/routing/app_router.dart';
import 'package:farmacia_sae/core/routing/auth_guard.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/models/contacts/models/contact.dart';
import 'package:farmacia_sae/models/contacts/views/contacts_page.dart';
import 'package:farmacia_sae/models/contacts/views/contact_details_page.dart';
import 'package:farmacia_sae/models/inventory/views/inventory_page.dart';
import 'package:farmacia_sae/models/inventory/views/lot_details_page.dart';
import 'package:farmacia_sae/models/products/views/products_page.dart';
import 'package:farmacia_sae/models/products/views/product_details_page.dart';
import 'package:farmacia_sae/models/purchases/views/purchases_page.dart';
import 'package:farmacia_sae/models/purchases/views/purchase_details_page.dart';
import 'package:farmacia_sae/shared/themes/app_theme.dart';
import 'package:farmacia_sae/shared/widgets/compact_workspace.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    Widget page, {
    double width = 1440,
    bool dark = false,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 900),
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(body: page),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'directorio grande pagina, busca, edita en detalle y conserva búsqueda al volver',
    (tester) async {
      final data = PharmacyController(seedDemoHistory: true);
      addTearDown(data.dispose);
      final contacts = data.contacts
          .where((c) => c.kind == ContactKind.customer)
          .toList();
      expect(contacts.length, greaterThan(8));
      await mount(
        tester,
        ContactsPage(controller: data, kind: ContactKind.customer),
      );
      expect(
        tester.widget<DataTable>(find.byType(DataTable)).rows,
        hasLength(8),
      );
      await tester.tap(find.byTooltip('Página siguiente'));
      await tester.pumpAndSettle();
      expect(find.text(contacts.first.name), findsNothing);
      final contact = contacts.last;
      await tester.enterText(
        find.byKey(const Key('contacts-search')),
        contact.name,
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<DataTable>(find.byType(DataTable)).rows,
        hasLength(1),
      );
      await tester.tap(find.text(contact.name).last);
      await tester.pumpAndSettle();
      expect(find.byType(ContactDetailsPage), findsOneWidget);
      expect(find.byType(TextField), findsNothing); // Ficha de lectura.
      await tester.tap(find.text('Editar contacto').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('contact-name')),
        '${contact.name} Editado',
      );
      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(data.contactById(contact.id)!.name, '${contact.name} Editado');
      await tester.tap(find.text('Volver al listado'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('contacts-search')))
            .controller!
            .text,
        contact.name,
      );
      expect(
        tester.widget<DataTable>(find.byType(DataTable)).rows,
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ruta producto → lotes → detalle permite ajustar y volver a cada nivel',
    (tester) async {
      final auth = AuthController();
      final signing = auth.signIn('admin', '1234');
      await tester.pump(const Duration(milliseconds: 450));
      await signing;
      final data = PharmacyController(
        seedDemoHistory: true,
        userProvider: () => auth.user,
      );
      final router = createAppRouter(
        auth: auth,
        pharmacyProvider: () => data,
        initialLocation: AppPaths.products,
      );
      addTearDown(router.dispose);
      addTearDown(data.dispose);
      addTearDown(auth.dispose);
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
      await tester.pumpAndSettle();
      final product = data.products.first;
      await tester.tap(find.text(product.name));
      await tester.pumpAndSettle();
      expect(find.byType(ProductDetailsPage), findsOneWidget);
      expect(
        GoRouterState.of(
          tester.element(find.byType(ProductDetailsPage)),
        ).uri.queryParameters['producto'],
        product.id,
      );
      expect(find.byKey(const Key('breadcrumb-current')), findsOneWidget);
      await tester.tap(find.text('Ver lotes'));
      await tester.pumpAndSettle();
      final table = tester.widget<CompactRecords>(find.byType(CompactRecords));
      expect(
        table.itemCount,
        data.lots.where((l) => l.productId == product.id).length,
      );
      final codeCell = tester
          .widget<DataTable>(find.byType(DataTable))
          .rows
          .first
          .cells
          .first
          .child;
      final code = (codeCell as SizedBox).child as RecordText;
      await tester.tap(find.text(code.text).first);
      await tester.pumpAndSettle();
      expect(find.byType(LotDetailsPage), findsOneWidget);
      final lotId = tester
          .widget<LotDetailsPage>(find.byType(LotDetailsPage))
          .lotId;
      final quantity = data.lots.firstWhere((l) => l.id == lotId).quantity;
      await tester.tap(find.text('Ajustar existencias'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('adjust-delta')), '2');
      await tester.enterText(
        find.byKey(const Key('adjust-reason')),
        'Recuento de verificación',
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(data.lots.firstWhere((l) => l.id == lotId).quantity, quantity + 2);
      await tester.tap(find.text('Volver al listado'));
      await tester.pumpAndSettle();
      expect(find.byType(InventoryPage), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(ProductDetailsPage), findsOneWidget);
      await tester.tap(find.text('Volver al listado'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'los enlaces de detalle conservan solo parámetros admitidos y respetan el rol',
    () async {
      final auth = AuthController();
      addTearDown(auth.dispose);
      final guard = AuthGuard(auth);
      for (final location in [
        AppPaths.productLocation('id con espacio'),
        AppPaths.inventoryLocation(productId: 'p1', lotId: 'l1'),
        AppPaths.contactLocation(4, 's1'),
        AppPaths.contactLocation(5, 'c1'),
        AppPaths.purchaseLocation('oc1'),
        AppPaths.reportLocation(true),
      ]) {
        final safe = AppPaths.safeDestination(
          '$location&destino=https://externo.example',
        );
        expect(Uri.parse(safe).queryParameters.containsKey('destino'), isFalse);
        final redirect = Uri.parse(guard.redirect(Uri.parse(location))!);
        expect(redirect.path, AppPaths.login);
        expect(redirect.hasQuery, isFalse);
      }
      await auth.signIn('usuario', '1234');
      expect(
        guard.redirect(Uri.parse(AppPaths.purchaseLocation('oc1'))),
        isNotNull,
      );
      expect(
        guard.redirect(Uri.parse(AppPaths.contactLocation(4, 's1'))),
        isNotNull,
      );
      expect(guard.redirect(Uri.parse(AppPaths.productLocation('p1'))), isNull);
    },
  );

  testWidgets(
    'detalles de lote ajeno no revelan datos y empleado no tiene ajuste',
    (tester) async {
      final admin = PharmacyController(seedDemoHistory: true);
      addTearDown(admin.dispose);
      final employee = PharmacyController(
        userProvider: () => AuthController.demoUsers.last,
        store: null,
        seedDemoHistory: true,
      );
      addTearDown(employee.dispose);
      admin.selectBranch(
        admin.branches.firstWhere((b) => b.id != employee.workingBranchId).id,
      );
      final foreign = admin.lots.first;
      await mount(
        tester,
        LotDetailsPage(controller: employee, lotId: foreign.id, onBack: () {}),
      );
      expect(find.text('Lote no disponible'), findsOneWidget);
      expect(find.text(foreign.code), findsNothing);
      await mount(
        tester,
        LotDetailsPage(
          controller: employee,
          lotId: employee.lots.first.id,
          onBack: () {},
        ),
      );
      expect(find.text('Ajustar existencias'), findsNothing);
      expect(find.text('Costo unitario'), findsNothing);
    },
  );

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('listados y fichas con texto ampliado a $width px', (
      tester,
    ) async {
      final data = PharmacyController(seedDemoHistory: true);
      addTearDown(data.dispose);
      final customer = data.contacts.firstWhere(
        (c) => c.kind == ContactKind.customer,
      );
      for (final dark in [false, true]) {
        for (final page in [
          ProductsPage(controller: data, onInventory: () {}),
          InventoryPage(controller: data, onProducts: () {}, lotsView: true),
          ContactsPage(controller: data, kind: ContactKind.customer),
          ContactsPage(controller: data, kind: ContactKind.supplier),
          PurchasesPage(controller: data),
          ContactDetailsPage(
            controller: data,
            kind: ContactKind.customer,
            contactId: customer.id,
            onBack: () {},
          ),
          PurchaseDetailsPage(
            controller: data,
            purchaseId: data.purchases.first.id,
            onBack: () {},
          ),
        ]) {
          await mount(tester, page, width: width, dark: dark, scale: 1.5);
          expect(tester.takeException(), isNull);
        }
      }
    });
  }
}
