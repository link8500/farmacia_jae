import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:farmacia_sae/core/routing/app_paths.dart';
import 'package:farmacia_sae/core/routing/app_router.dart';
import 'package:farmacia_sae/core/routing/auth_guard.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/core/services/promotions_controller.dart';
import 'package:farmacia_sae/core/services/promotion_store.dart';
import 'package:farmacia_sae/models/contacts/models/contact.dart';
import 'package:farmacia_sae/models/home/views/home.dart';
import 'package:farmacia_sae/models/sales/widgets/cart_card.dart';
import 'package:farmacia_sae/models/sales/widgets/product_catalog.dart';
import 'package:farmacia_sae/shared/themes/app_theme.dart';
import 'package:farmacia_sae/shared/widgets/compact_workspace.dart';
import 'package:farmacia_sae/models/organization/widgets/staff_form_dialog.dart';

/// Regresión de alineación entre roles, con el shell real y sus menús distintos.
/// Las capturas son opcionales: se generan solo al solicitar UI_CAPTURE_DIR.
void main() {
  const output = String.fromEnvironment('UI_CAPTURE_DIR');
  const captureKey = Key('administration-qa-capture');
  setUpAll(() async {
    if (output.isEmpty) {
      return;
    }
    // Fuente real para revisar capturas; el resto de la suite conserva Ahem
    // para detectar desbordamientos con métricas de texto más exigentes.
    final font = FontLoader('Arial');
    font.addFont(
      Future.value(
        ByteData.sublistView(
          await File('C:/Windows/Fonts/arial.ttf').readAsBytes(),
        ),
      ),
    );
    font.addFont(
      Future.value(
        ByteData.sublistView(
          await File('C:/Windows/Fonts/arialbd.ttf').readAsBytes(),
        ),
      ),
    );
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  Future<void> capture(WidgetTester tester, String name) async {
    if (output.isEmpty) {
      return;
    }
    // Esperar la decodificación real evita capturar espacios blancos antes de
    // que los JPEG locales entreguen su primer cuadro al árbol de imágenes.
    final images = find.byType(Image);
    if (images.evaluate().isNotEmpty) {
      final context = tester.element(images.first);
      final providers = tester
          .widgetList<Image>(images)
          .map((i) => i.image)
          .toList();
      await tester.runAsync(() async {
        for (final provider in providers) {
          await precacheImage(provider, context);
        }
      });
      await tester.pumpAndSettle();
    }
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(captureKey),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(output).create(recursive: true);
      await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<(AuthController, PharmacyController, GoRouter)> mount(
    WidgetTester tester,
    String user,
    Size size, {
    bool dark = false,
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    final auth = AuthController();
    addTearDown(auth.dispose);
    final signing = auth.signIn(user, '1234');
    await tester.pump(const Duration(milliseconds: 500));
    await signing;
    final data = PharmacyController(
      userProvider: () => auth.user,
      seedDemoHistory: true,
    );
    addTearDown(data.dispose);
    final promotions = PromotionsController(
      store: MemoryPromotionStore(),
      canManage: () =>
          auth.user?.isAdministrator == true && data.isAdministrator,
      seedDemo: output.isNotEmpty,
    );
    addTearDown(promotions.dispose);
    final router = createAppRouter(
      promotions: promotions,
      auth: auth,
      pharmacyProvider: () => data,
      initialLocation: AppPaths.sections[1],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: MaterialApp.router(
          key: ValueKey('$user-$size-$dark'),
          theme: dark ? AppTheme.dark : AppTheme.light,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (auth, data, router);
  }

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(768, 900),
    const Size(1280, 720),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'facturación conserva alineación entre admin y usuario a $size',
      (tester) async {
        addTearDown(tester.view.reset);
        Rect? catalogBounds, cartBounds;
        for (final role in ['admin', 'usuario']) {
          final (_, data, _) = await mount(tester, role, size);
          expect(data.billingAssignmentError, isNull);
          expect(tester.takeException(), isNull);
          final catalog = tester.getRect(find.byType(ProductCatalog));
          if (catalogBounds != null) expect(catalog, catalogBounds);
          catalogBounds = catalog;
          if (size.width == 1440) await capture(tester, 'facturacion-$role');
          if (size.width == 390) {
            await capture(tester, 'facturacion-movil-$role');
          }
          data.addToCart(data.products.first);
          await tester.pumpAndSettle();
          final mobileTab = find.textContaining('Venta (');
          if (mobileTab.evaluate().isNotEmpty) {
            await tester.tap(mobileTab);
            await tester.pumpAndSettle();
          }
          final cart = tester.getRect(find.byType(CartCard));
          if (cartBounds != null) expect(cart, cartBounds);
          cartBounds = cart;
          expect(find.text('Completar venta'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      },
    );
  }

  for (final role in ['admin', 'usuario']) {
    testWidgets(
      'vistas compartidas $role con texto grande, tema oscuro y pantalla estrecha',
      (tester) async {
        addTearDown(tester.view.reset);
        final (_, data, router) = await mount(
          tester,
          role,
          const Size(390, 844),
          dark: true,
          scale: 1.5,
        );
        for (final path in [
          AppPaths.sections[1],
          AppPaths.salesLocation(true),
          AppPaths.sections[2],
          AppPaths.products,
          AppPaths.sections[5],
          AppPaths.profile,
          AppPaths.billingRegisters,
          AppPaths.registerLocation(data.currentRegister!.id),
          AppPaths.preferences,
          AppPaths.preferenceLocation(1),
          AppPaths.preferenceLocation(2),
          AppPaths.sections[7],
          if (role == 'admin') ...[
            AppPaths.sections[3],
            AppPaths.sections[4],
            AppPaths.sections[6],
            AppPaths.sections[8],
            AppPaths.organization,
            AppPaths.promotions,
          ],
        ]) {
          router.go(path);
          await tester.pumpAndSettle();
          expect(find.byType(HomeScreen), findsOneWidget, reason: path);
          expect(
            find.textContaining(
              RegExp(r'demostraci[oó]n', caseSensitive: false),
              findRichText: true,
            ),
            findsNothing,
            reason: path,
          );
          expect(tester.takeException(), isNull, reason: path);
        }
      },
    );
  }

  testWidgets(
    'detalle de caja respeta período y no revela otra caja al empleado',
    (tester) async {
      addTearDown(tester.view.reset);
      final (auth, data, router) = await mount(
        tester,
        'usuario',
        const Size(1440, 900),
      );
      final end = data.today.subtract(const Duration(days: 20));
      final start = end.subtract(const Duration(days: 10));
      final path = AppPaths.registerLocation(
        data.currentRegister!.id,
        start: start,
        end: end,
      );
      expect(AppPaths.safeDestination('$path&externo=true'), path);
      router.go(path);
      await tester.pumpAndSettle();
      expect(find.text('Productos vendidos'), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      router.go(AppPaths.registerLocation('register-main-2'));
      await tester.pumpAndSettle();
      expect(find.text('Caja no disponible'), findsOneWidget);
      expect(find.text('Ana Martínez'), findsNothing);
      expect(
        AuthGuard(
          auth,
        ).redirect(Uri.parse(AppPaths.promotionLocation('promo-1'))),
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'formulario de asignación permite guardar con ventana baja y teclado',
    (tester) async {
      addTearDown(tester.view.reset);
      final (_, data, router) = await mount(
        tester,
        'admin',
        const Size(390, 540),
      );
      router.go(AppPaths.organization);
      await tester.pumpAndSettle();
      // La ventana baja pagina el directorio: buscar evita depender de la fila
      // visible y reproduce el acceso real al empleado antes de editarlo.
      await tester.enterText(find.byKey(const Key('staff-search')), 'Daniel');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('staff-edit-demo-employee')),
        150,
        scrollable: find
            .descendant(
              of: find.byType(CompactWorkspace),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('staff-edit-demo-employee')));
      await tester.pumpAndSettle();
      expect(find.byType(StaffFormDialog), findsOneWidget);
      tester.view.viewInsets = const FakeViewPadding(bottom: 160);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('staff-name')));
      await tester.enterText(
        find.byKey(const Key('staff-name')),
        'Daniel de prueba',
      );
      await tester.ensureVisible(find.byKey(const Key('staff-save')));
      await tester.tap(find.byKey(const Key('staff-save')));
      await tester.pumpAndSettle();
      expect(
        data.staff.firstWhere((m) => m.id == 'demo-employee').name,
        'Daniel de prueba',
      );
      expect(find.byType(StaffFormDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  if (output.isNotEmpty) {
    testWidgets(
      'capturas de cajas, detalle y formulario del centro de personal',
      (tester) async {
        addTearDown(tester.view.reset);
        final (_, data, router) = await mount(
          tester,
          'admin',
          const Size(1440, 900),
        );
        router.go(AppPaths.billingRegisters);
        await tester.pumpAndSettle();
        await capture(tester, 'cajas-compactas');
        router.go(AppPaths.registerLocation(data.currentRegister!.id));
        await tester.pumpAndSettle();
        await capture(tester, 'detalle-caja');
        router.go(AppPaths.organization);
        await tester.pumpAndSettle();
        await capture(tester, 'personal-compacto');
        await tester.tap(find.byKey(const Key('staff-edit-demo-employee')));
        await tester.pumpAndSettle();
        await capture(tester, 'modal-asignacion');
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('capturas de imágenes vinculadas y acceso con URL limpia', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      final (auth, data, router) = await mount(
        tester,
        'admin',
        const Size(1440, 900),
      );
      Future<void> show(String path, String name) async {
        router.go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capture(tester, name);
      }

      await show(
        AppPaths.productLocation(data.products.first.id),
        'producto-con-imagen',
      );
      await show(AppPaths.administration, 'resumen-con-imagenes');
      await show(
        AppPaths.inventoryLocation(lotId: data.lots.first.id),
        'lote-con-imagen',
      );
      final client = data.contacts.firstWhere(
        (c) =>
            c.kind == ContactKind.customer && c.id.startsWith('demo-history'),
      );
      final supplier = data.contacts.firstWhere(
        (c) =>
            c.kind == ContactKind.supplier && c.id.startsWith('demo-history'),
      );
      await show(AppPaths.contactLocation(5, client.id), 'cliente-con-foto');
      await show(
        AppPaths.contactLocation(4, supplier.id),
        'proveedor-con-foto',
      );
      final order = data.purchases
          .where((p) => p.supplierId == supplier.id)
          .first;
      await show(
        AppPaths.purchaseLocation(order.id, supplierId: supplier.id),
        'compra-desde-proveedor',
      );
      await show(AppPaths.salesLocation(true), 'historial-facturas');
      final latest = data.sales.reversed.firstWhere((s) => !s.cancelled);
      await tester.ensureVisible(find.text(latest.id));
      await tester.tap(find.text(latest.id));
      await tester.pumpAndSettle();
      await capture(tester, 'comprobante-con-imagenes');
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      await show(AppPaths.promotions, 'promociones-con-imagen');
      await show(
        AppPaths.promotionLocation('promo-900001'),
        'detalle-promocion',
      );
      await show(AppPaths.publicPromotions, 'promociones-publicas');
      await show(AppPaths.presentation, 'presentacion-renovada');
      await show(AppPaths.presentationServices, 'catalogo-publico');
      await show(AppPaths.presentationAbout, 'nosotros-renovado');
      await show(AppPaths.presentationContact, 'contacto-renovado');
      tester.view.physicalSize = const Size(390, 844);
      await show(AppPaths.presentation, 'presentacion-renovada-movil');
      tester.view.physicalSize = const Size(1440, 900);
      auth.signOut();
      await show(
        '/administracion/login?desde=/administracion/productos',
        'login-url-limpia',
      );
      expect(
        router.routeInformationProvider.value.uri.toString(),
        AppPaths.administration,
      );
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      await capture(tester, 'login-movil-url-limpia');
      expect(tester.takeException(), isNull);
    });
  }
}
