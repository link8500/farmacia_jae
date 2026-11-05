import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/core/routing/app_paths.dart';
import 'package:farmacia_sae/core/routing/app_router.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/core/services/local_administration_store.dart';
import 'package:farmacia_sae/core/services/promotion_store.dart';
import 'package:farmacia_sae/core/services/promotions_controller.dart';
import 'package:farmacia_sae/core/utils/legacy_interface_text.dart';
import 'package:farmacia_sae/models/contacts/views/contact_details_page.dart';
import 'package:farmacia_sae/models/purchases/views/purchase_details_page.dart';
import 'package:farmacia_sae/models/products/views/product_details_page.dart';
import 'package:farmacia_sae/models/products/widgets/product_thumbnail.dart';
import 'package:farmacia_sae/models/sales/widgets/receipt_dialog.dart';
import 'package:farmacia_sae/shared/themes/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'la limpieza conserva identificadores, referencias, imágenes e importes',
    () async {
      final data = PharmacyController(seedDemoHistory: true);
      addTearDown(data.dispose);
      final json = jsonDecode(data.createBackup()) as Map<String, dynamic>;
      (json['contacts'] as List).first['name'] = 'Proveedor de demostración';
      (json['purchases'] as List).first['supplierName'] =
          'Proveedor de demostración';
      (json['audit'] as List).first['detail'] = 'Recepción · Demostración';
      final originalOrder = (json['purchases'] as List).first['id'];
      final store = MemoryAdministrationStore(jsonEncode(json));
      final restored = PharmacyController(store: store);
      addTearDown(restored.dispose);
      await restored.initialize();
      expect(restored.loadFailed, isFalse);
      final result =
          jsonDecode(restored.createBackup()) as Map<String, dynamic>;
      expect((result['contacts'] as List).first['name'], 'Proveedor general');
      expect(
        (result['purchases'] as List).first['supplierName'],
        'Proveedor general',
      );
      expect((result['purchases'] as List).first['id'], originalOrder);
      expect((result['audit'] as List).first['detail'], 'Recepción');
      expect(restored.stockTotal, data.stockTotal);
      expect(
        restored.sales.map((s) => s.total),
        data.sales.map((s) => s.total),
      );
      expect(
        restored.contacts.map((s) => s.photoAsset),
        data.contacts.map((s) => s.photoAsset),
      );
      expect(
        cleanLegacyInterfaceDocument({
          'id': 'demo-history-purchase-1',
          'branchId': 'demo-history-branch-1',
          'name': 'Sucursal Norte · Demo',
          'identification': 'DEMO-CLI-0001',
          'photoAsset': 'images/people/customer-demo.jpg',
        }),
        {
          'id': 'demo-history-purchase-1',
          'branchId': 'demo-history-branch-1',
          'name': 'Sucursal Norte',
          'identification': 'DEMO-CLI-0001',
          'photoAsset': 'images/people/customer-demo.jpg',
        },
      );
    },
  );

  test('las promociones antiguas pierden la etiqueta al recuperarse', () async {
    final document = jsonEncode({
      'version': 1,
      'promotions': [
        {
          'id': 'promo-1',
          'title': 'Campaña de demostración',
          'description': 'Cuidado diario',
          'badge': 'Oferta · Demo',
          'conditions': 'Contenido de demostración',
          'illustrationKey': '',
          'startsAt': '2026-10-01T00:00:00.000',
          'endsAt': '2026-12-01T00:00:00.000',
          'status': 'published',
        },
      ],
    });
    final controller = PromotionsController(
      store: MemoryPromotionStore(editorData: document, publicData: document),
      canManage: () => true,
      clock: () => DateTime(2026, 10, 29),
    );
    addTearDown(controller.dispose);
    await controller.loadEditor();
    await controller.loadPublic();
    expect(controller.entries.single.title, 'Campaña');
    expect(controller.visible.single.badge, 'Oferta');
    expect(controller.visible.single.conditions, 'Contenido');
  });

  for (final width in [320.0, 1440.0]) {
    testWidgets(
      'proveedor → compra → producto conserva regreso y fotos a $width px',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final auth = AuthController();
        addTearDown(auth.dispose);
        final signing = auth.signIn('admin', '1234');
        await tester.pump(const Duration(milliseconds: 500));
        await signing;
        final data = PharmacyController(
          seedDemoHistory: true,
          userProvider: () => auth.user,
        );
        addTearDown(data.dispose);
        final order =
            (data.purchases.toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
                .first;
        final supplierPath = AppPaths.contactLocation(4, order.supplierId);
        final router = createAppRouter(
          auth: auth,
          pharmacyProvider: () => data,
          initialLocation: supplierPath,
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(theme: AppTheme.light, routerConfig: router),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(order.id));
        await tester.tap(find.text(order.id));
        await tester.pumpAndSettle();
        expect(find.byType(PurchaseDetailsPage), findsOneWidget);
        expect(
          router
              .routeInformationProvider
              .value
              .uri
              .queryParameters['proveedor'],
          order.supplierId,
        );
        expect(find.byType(ProductThumbnail), findsWidgets);
        final product = find.text(order.lines.first.productName).first;
        await tester.ensureVisible(product);
        await tester.tap(product);
        await tester.pumpAndSettle();
        expect(find.byType(ProductDetailsPage), findsOneWidget);
        await tester.ensureVisible(find.text('Volver al listado'));
        await tester.tap(find.text('Volver al listado'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Volver al proveedor'));
        await tester.tap(find.text('Volver al proveedor'));
        await tester.pumpAndSettle();
        expect(find.byType(ContactDetailsPage), findsOneWidget);
        expect(
          router.routeInformationProvider.value.uri.toString(),
          supplierPath,
        );
        final direct = AppPaths.purchaseLocation(
          order.id,
          supplierId: order.supplierId,
        );
        expect(AppPaths.safeDestination('$direct&externo=true'), direct);
        router.go(direct);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Volver al proveedor'));
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.toString(),
          supplierPath,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'el comprobante muestra miniaturas y omite la etiqueta a $width px',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final data = PharmacyController(seedDemoHistory: true);
        addTearDown(data.dispose);
        final sale = data.sales.first;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showReceipt(context, sale, controller: data),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();
        expect(find.byType(ProductThumbnail), findsNWidgets(sale.lines.length));
        expect(
          find.textContaining(RegExp('demostraci[oó]n', caseSensitive: false)),
          findsNothing,
        );
        expect(
          receiptHtml(sale).toLowerCase(),
          isNot(contains('demostración')),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
