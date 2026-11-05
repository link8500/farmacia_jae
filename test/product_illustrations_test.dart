import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/core/services/pharmacy_demo_data.dart';
import 'package:farmacia_sae/core/services/local_administration_store.dart';
import 'package:farmacia_sae/models/products/models/product.dart';
import 'package:farmacia_sae/models/products/models/product_illustration.dart';
import 'package:farmacia_sae/models/products/widgets/product_form_dialog.dart';
import 'package:farmacia_sae/models/products/widgets/product_thumbnail.dart';
import 'package:farmacia_sae/models/products/views/products_page.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';
import 'package:farmacia_sae/models/sales/widgets/product_catalog.dart';
import 'package:farmacia_sae/shared/themes/app_theme.dart';

String? edit(PharmacyController data, Product p, {String? illustrationKey}) =>
    data.registerProduct(
      id: p.id,
      code: p.code,
      name: p.name,
      category: p.category,
      presentation: p.presentation,
      unit: p.unit,
      minimum: p.minimum,
      price: p.price,
      activeIngredient: p.activeIngredient,
      barcode: p.barcode,
      illustrationKey: illustrationKey,
    );

class _MissingProductImages extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key.startsWith('images/products/')) {
      return Future.error(
        FlutterError('Recurso no disponible en este bundle de prueba.'),
      );
    }
    return rootBundle.load(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'los ocho recursos son PNG reales incluidos en el bundle de Flutter',
    () async {
      expect(ProductIllustrations.values, hasLength(8));
      expect(
        ProductIllustrations.values.map((i) => i.key).toSet(),
        hasLength(8),
      );
      for (final entry in ProductIllustrations.values) {
        final bytes = await rootBundle.load(entry.assetPath);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          targetWidth: 64,
        );
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 64);
        expect(frame.image.height, greaterThan(0));
        frame.image.dispose();
        codec.dispose();
      }
    },
  );

  test(
    'serializa, archiva y restaura la selección sin alterar precio o stock',
    () {
      final data = PharmacyController();
      final restored = PharmacyController(seedDemo: false);
      addTearDown(data.dispose);
      addTearDown(restored.dispose);
      final stock = data.stockTotal;
      final first = data.products.first;
      expect(Product.fromJson(first.toJson()).illustrationKey, 'paracetamol');
      expect(first.withActive(false).illustrationKey, 'paracetamol');
      expect(edit(data, first), isNull);
      expect(data.products.first.illustrationKey, 'paracetamol');
      expect(restored.restoreBackup(data.createBackup()), isNull);
      expect(
        restored.products.map((p) => p.illustrationKey),
        PharmacyDemoData.products.map((p) => p.illustrationKey),
      );
      expect(data.stockTotal, stock);
      expect(restored.stockTotal, stock);
      expect(restored.products.first.price, first.price);
    },
  );

  test('migración antigua solo reconoce las fichas demo exactas', () {
    for (final p in PharmacyDemoData.products) {
      final old = p.toJson()..remove('illustrationKey');
      expect(Product.fromJson(old).illustrationKey, p.illustrationKey);
      old['name'] = 'Otro producto con el mismo código';
      expect(Product.fromJson(old).illustrationKey, isEmpty);
    }
  });

  test(
    'recupera imágenes de fichas antiguas con presentación abreviada',
    () async {
      final original = PharmacyController();
      addTearDown(original.dispose);
      final snapshot =
          jsonDecode(original.createBackup()) as Map<String, dynamic>;
      for (final raw in snapshot['products'] as List) {
        final product = raw as Map<String, dynamic>;
        product.remove('illustrationKey');
        product['presentation'] = product['unit'];
      }
      final store = MemoryAdministrationStore(jsonEncode(snapshot));
      final restored = PharmacyController(store: store);
      addTearDown(restored.dispose);
      await restored.initialize();
      expect(restored.loadFailed, isFalse);
      expect(
        restored.products.map((p) => p.illustrationKey),
        PharmacyDemoData.products.map((p) => p.illustrationKey),
      );
      expect(
        restored.products.map((p) => p.presentation),
        PharmacyDemoData.products.map((p) => p.unit),
      );
      expect(restored.stockTotal, original.stockTotal);
    },
  );

  test('sin imagen persiste y no vuelve a asignarse al recargar', () {
    final data = PharmacyController();
    final restored = PharmacyController(seedDemo: false);
    addTearDown(data.dispose);
    addTearDown(restored.dispose);
    expect(edit(data, data.products.first, illustrationKey: ''), isNull);
    expect(data.products.first.illustrationKey, isEmpty);
    expect(restored.restoreBackup(data.createBackup()), isNull);
    expect(restored.products.first.illustrationKey, isEmpty);
  });

  test(
    'recuperación explícita conserva todo excepto asociaciones visuales ausentes',
    () async {
      final data = PharmacyController();
      addTearDown(data.dispose);
      final snapshot = jsonDecode(data.createBackup()) as Map<String, dynamic>;
      final rawProducts = snapshot['products'] as List;
      for (final raw in rawProducts) {
        final product = raw as Map<String, dynamic>;
        product['illustrationKey'] = '';
        product['presentation'] = product['unit'];
      }
      // Una selección válida se respeta, aunque sea otra imagen del catálogo.
      rawProducts[1]['illustrationKey'] = 'alcohol';
      final store = MemoryAdministrationStore(jsonEncode(snapshot));
      final restored = PharmacyController(store: store);
      addTearDown(restored.dispose);
      await restored.initialize();
      final before = restored.products.map((p) => p.toJson()).toList();
      final lots = restored.lots.map((lot) => lot.toJson()).toList();
      expect(restored.productsWithRecoverableIllustration, hasLength(7));
      expect(restored.restoreMissingDemoIllustrations(), isNull);
      expect(restored.productsWithRecoverableIllustration, isEmpty);
      for (var i = 0; i < before.length; i++) {
        final after = restored.products[i].toJson()..remove('illustrationKey');
        before[i].remove('illustrationKey');
        expect(after, before[i]);
      }
      expect(restored.products[1].illustrationKey, 'alcohol');
      expect(restored.lots.map((lot) => lot.toJson()), lots);
      await restored.flush();
      final reloaded = PharmacyController(store: store);
      addTearDown(reloaded.dispose);
      await reloaded.initialize();
      expect(
        reloaded.products.map((p) => p.illustrationKey),
        restored.products.map((p) => p.illustrationKey),
      );
      expect(restored.restoreMissingDemoIllustrations(), isNotNull);
    },
  );

  test(
    'no recupera imágenes de otros productos ni permite hacerlo a empleados',
    () {
      final data = PharmacyController();
      final employeeData = PharmacyController(
        userProvider: () => AuthController.demoUsers.last,
      );
      addTearDown(data.dispose);
      addTearDown(employeeData.dispose);
      for (final product in PharmacyDemoData.products) {
        final unrelated = product.toJson()
          ..remove('illustrationKey')
          ..['id'] = 'otro-id';
        expect(Product.fromJson(unrelated).illustrationKey, isEmpty);
        final otherPresentation = product.toJson()
          ..remove('illustrationKey')
          ..['presentation'] = 'Otra presentación';
        expect(Product.fromJson(otherPresentation).illustrationKey, isEmpty);
      }
      expect(employeeData.productsWithRecoverableIllustration, isEmpty);
      expect(employeeData.restoreMissingDemoIllustrations(), isNotNull);
    },
  );

  testWidgets(
    'Productos recupera las asociaciones en lote solo después de confirmar',
    (tester) async {
      final data = PharmacyController();
      addTearDown(data.dispose);
      for (final product in data.products.toList()) {
        expect(edit(data, product, illustrationKey: ''), isNull);
      }
      final stock = data.stockTotal;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ProductsPage(controller: data, onInventory: () {}),
          ),
        ),
      );
      final button = find.byKey(const Key('products-restore-images'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(data.products.every((p) => p.illustrationKey.isEmpty), isTrue);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(
        data.products.map((p) => p.illustrationKey),
        PharmacyDemoData.products.map((p) => p.illustrationKey),
      );
      expect(button, findsNothing);
      expect(data.stockTotal, stock);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'las ocho miniaturas llegan a pintar una imagen real, no solo el widget',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => SingleChildScrollView(
                child: Wrap(
                  children: [
                    for (final image in ProductIllustrations.values)
                      ProductThumbnail(illustrationKey: image.key, width: 150),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final context = tester.element(find.byType(Wrap).first);
      await tester.runAsync(
        () => Future.wait([
          for (final image in ProductIllustrations.values)
            precacheImage(
              ResizeImage.resizeIfNeeded(
                512,
                null,
                AssetImage(image.assetPath),
              ),
              context,
            ),
        ]),
      );
      await tester.pumpAndSettle();
      final painted = tester
          .widgetList<RawImage>(find.byType(RawImage))
          .where((image) => image.image != null);
      expect(painted, hasLength(8));
      expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
      expect(find.byIcon(Icons.medication_outlined), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('un error de carga se distingue de una ficha sin imagen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DefaultAssetBundle(
            bundle: _MissingProductImages(),
            child: const Row(
              children: [
                ProductThumbnail(illustrationKey: 'paracetamol', width: 120),
                ProductThumbnail(illustrationKey: '', width: 120),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.byIcon(Icons.medication_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('rechaza claves externas y permite seleccionar otro recurso local', () {
    final data = PharmacyController();
    addTearDown(data.dispose);
    final first = data.products.first;
    expect(
      edit(data, first, illustrationKey: 'https://example.invalid/a.jpg'),
      isNotNull,
    );
    expect(data.products.first.illustrationKey, first.illustrationKey);
    expect(edit(data, first, illustrationKey: 'alcohol'), isNull);
    expect(data.products.first.illustrationKey, 'alcohol');
  });

  testWidgets('clave desconocida usa fallback local y etiqueta accesible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(
            child: ProductThumbnail(
              illustrationKey: 'desconocida',
              width: 180,
              showCaption: true,
            ),
          ),
        ),
      ),
    );
    expect(find.byType(Image), findsNothing);
    expect(find.text('Sin imagen'), findsOneWidget);
    expect(find.byTooltip('Sin imagen de producto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('imágenes en tarjetas y lista: $width oscuro=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final selected = <Product>[];
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 1000),
                  textScaler: TextScaler.linear(1.3),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ProductCatalog(
                      products: PharmacyDemoData.products,
                      availableStock: (_) => 12,
                      onAdd: selected.add,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ProductThumbnail), findsNWidgets(8));
        // Las miniaturas conservan su semántica sin etiquetas visibles al pie.
        expect(find.text('Imagen ilustrativa · IA'), findsNothing);
        final add = find.byKey(const Key('add-product-prd-001'));
        await tester.ensureVisible(add);
        await tester.tap(add);
        expect(selected.single.id, 'prd-001');
        await tester.ensureVisible(find.byTooltip('Vista en lista'));
        await tester.tap(find.byTooltip('Vista en lista'));
        await tester.pumpAndSettle();
        expect(find.byType(ProductThumbnail), findsNWidgets(8));
        expect(find.text('Imagen ilustrativa · IA'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('el formulario permite quitar una imagen sin cambiar la ficha', (
    tester,
  ) async {
    final data = PharmacyController();
    addTearDown(data.dispose);
    final before = data.products.first;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    ProductFormDialog(controller: data, product: before),
              ),
              child: const Text('Editar imagen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Editar imagen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('product-tab-2')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('product-illustration')));
    await tester.tap(find.byKey(const Key('product-illustration')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sin imagen').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('product-save')));
    await tester.tap(find.byKey(const Key('product-save')));
    await tester.pumpAndSettle();
    expect(data.products.first.illustrationKey, isEmpty);
    expect(data.products.first.name, before.name);
    expect(data.products.first.price, before.price);
    expect(tester.takeException(), isNull);
  });
}
