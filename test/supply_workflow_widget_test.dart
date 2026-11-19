import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/models/contacts/models/contact.dart';
import 'package:farmacia_sae/models/purchases/widgets/purchase_dialogs.dart';
import 'package:farmacia_sae/models/purchases/models/purchase_order.dart';
import 'package:farmacia_sae/models/purchases/views/purchase_details_page.dart';
import 'package:farmacia_sae/models/products/views/product_details_page.dart';
import 'package:farmacia_sae/models/sales/models/sale_receipt.dart';
import 'package:farmacia_sae/models/inventory/views/lot_details_page.dart';
import 'package:farmacia_sae/shared/themes/app_theme.dart';

void main() {
  for (final width in [320.0, 1280.0]) {
    testWidgets(
      'compra por medicamento, envases, recepción y precio posterior a $width px',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final today = DateTime(2026, 11, 4);
        final data = PharmacyController(seedDemo: false, clock: () => today);
        addTearDown(data.dispose);
        data.saveContact(
          kind: ContactKind.supplier,
          name: 'Proveedor vinculado',
          code: 'P-001',
        );
        data.saveContact(
          kind: ContactKind.supplier,
          name: 'Proveedor sin vínculo',
          code: 'P-002',
        );
        data.registerProduct(
          code: 'M-001',
          name: 'Medicamento de prueba',
          category: 'Medicamentos',
          presentation: 'Caja de 10 tabletas',
          unit: 'Tableta',
          minimum: 10,
          dosage: '250 mg',
          measurementUnit: 'mg',
          packageUnits: 10,
          origin: 'Nicaragua',
        );
        final id = data.products.single.id;
        data.saveProductSupplier(
          productId: id,
          supplierId: data.contacts.first.id,
          referenceCost: 1.2,
        );
        Future<void> mountAction(
          Widget Function(BuildContext) button,
          String key,
        ) async {
          await tester.pumpWidget(
            MaterialApp(
              key: ValueKey(key),
              theme: AppTheme.light,
              home: Scaffold(body: Builder(builder: button)),
            ),
          );
          await tester.pumpAndSettle();
        }

        await mountAction(
          (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => PurchaseFormDialog(controller: data),
            ),
            child: const Text('Preparar compra'),
          ),
          'buy',
        );
        await tester.tap(find.text('Preparar compra'));
        await tester.pumpAndSettle();
        final search = find.descendant(
          of: find.byKey(const Key('purchase-product')),
          matching: find.byType(TextField),
        );
        await tester.enterText(search, 'Medicamento de prueba');
        await tester.pumpAndSettle();
        await tester.tap(
          find
              .text('Medicamento de prueba · 250 mg · Caja de 10 tabletas')
              .last,
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Dosis / concentración: 250 mg'),
          findsOneWidget,
        );
        expect(find.textContaining('Proveedor vinculado'), findsWidgets);
        expect(
          tester
              .widget<TextFormField>(find.byKey(const Key('purchase-cost')))
              .controller!
              .text,
          '1.2',
        );
        await tester.ensureVisible(find.byKey(const Key('purchase-packages')));
        await tester.tap(find.byKey(const Key('purchase-packages')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('purchase-quantity')));
        await tester.enterText(find.byKey(const Key('purchase-quantity')), '3');
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('purchase-add-line')));
        await tester.tap(find.byKey(const Key('purchase-add-line')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('purchase-save')));
        await tester.pumpAndSettle();
        expect(data.purchases, hasLength(1));
        expect(data.purchases.single.lines.single.quantity, 30);
        expect(data.purchases.single.total, 36);
        expect(data.lots, isEmpty);
        expect(data.products.single.price, 0);
        await mountAction(
          (context) => TextButton(
            onPressed: () =>
                receivePurchaseDialog(context, data, data.purchases.single),
            child: const Text('Recibir compra'),
          ),
          'receive',
        );
        await tester.tap(find.text('Recibir compra'));
        await tester.pumpAndSettle();
        const leaflet = 'Texto del prospecto recibido en esta compra.';
        for (final field in {
          'batch-$id': 'FAB-250-A',
          'manufactured-$id': '2026-07-01',
          'expiry-$id': '2027-11-04',
          'location-$id': 'Estante A · Nivel 2',
          'manufacturer-indications-$id': leaflet,
        }.entries) {
          final finder = find.byKey(Key(field.key));
          await tester.ensureVisible(finder);
          await tester.enterText(finder, field.value);
        }
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirmar recepción'));
        await tester.pumpAndSettle();
        expect(data.lots, hasLength(1));
        expect(data.lots.single.quantity, 30);
        expect(data.lots.single.location, 'Estante A · Nivel 2');
        expect(data.lots.single.supplierId, data.contacts.first.id);
        expect(data.products.single.price, 0);
        expect(data.products.single.indications, isEmpty);
        expect(data.purchases.single.manufacturerIndications, {id: leaflet});
        final purchaseId = data.purchases.single.id;
        await mountAction(
          (_) => PurchaseDetailsPage(
            controller: data,
            purchaseId: purchaseId,
            onBack: () {},
          ),
          'purchase-details',
        );
        final indications = find.byType(ExpansionTile);
        await tester.ensureVisible(indications);
        await tester.tap(indications);
        await tester.pumpAndSettle();
        expect(find.text(leaflet), findsOneWidget);
        expect(data.addToCart(data.products.single), isFalse);
        await mountAction(
          (_) => ProductDetailsPage(
            controller: data,
            productId: id,
            onBack: () {},
            onLots: () {},
          ),
          'price',
        );
        await tester.tap(find.text('Definir precio'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('sale-price')), '2.50');
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();
        expect(data.products.single.price, 2.5);
        expect(data.addToCart(data.products.single), isTrue);
        expect(
          data.checkoutSale(method: PaymentMethod.cash, tendered: 5),
          isNull,
        );
        expect(data.sales.single.total, 2.5);
        expect(data.lots.single.quantity, 29);
        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('lot-document'),
            theme: AppTheme.light,
            home: Scaffold(
              body: LotDetailsPage(
                controller: data,
                lotId: data.lots.single.id,
                onBack: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Completar trazabilidad'), findsNothing);
        await tester.tap(find.text('Ubicar lote'));
        await tester.pumpAndSettle();
        final location = find.byKey(const Key('lot-new-location'));
        await tester.ensureVisible(location);
        await tester.enterText(location, 'Estante B · Nivel 3');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();
        expect(data.lots.single.location, 'Estante B · Nivel 3');
        expect(data.lots.single.quantity, 29);
        expect(data.sales.single.total, 2.5);
        expect(
          data.createPurchase(data.contacts.first.id, [
            PurchaseLine(
              productId: id,
              productName: '',
              quantity: 3,
              unitCost: 1.2,
            ),
          ]),
          isNull,
        );
        await mountAction(
          (context) => TextButton(
            onPressed: () =>
                receivePurchaseDialog(context, data, data.purchases.last),
            child: const Text('Recibir otra compra'),
          ),
          'receive-again',
        );
        await tester.tap(find.text('Recibir otra compra'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(Key('batch-$id')), ' fab-250-a ');
        await tester.pumpAndSettle();
        for (final entry in {
          'manufactured-$id': '2026-07-01',
          'expiry-$id': '2027-11-04',
          'location-$id': 'Estante B · Nivel 3',
        }.entries) {
          final field = tester.widget<TextFormField>(
            find.byKey(Key(entry.key)),
          );
          expect(field.controller!.text, entry.value);
        }
        await tester.tap(find.text('Confirmar recepción'));
        await tester.pumpAndSettle();
        expect(data.lots.single.quantity, 32);
        expect(data.purchases.first.receivedLots.single.quantity, 30);
        expect(data.purchases.first.manufacturerIndications, {id: leaflet});
        expect(data.purchases.last.manufacturerIndications, isEmpty);
        final restored = PharmacyController(seedDemo: false);
        addTearDown(restored.dispose);
        expect(restored.restoreBackup(data.createBackup()), isNull);
        expect(restored.purchases.first.manufacturerIndications, {id: leaflet});
        expect(
          data.purchases.last.receivedLots.single.lotId,
          data.lots.single.id,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
