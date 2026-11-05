import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:farmacia_sae/core/app.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';
import 'package:farmacia_sae/core/services/local_administration_store.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/core/services/preferences_controller.dart';
import 'package:farmacia_sae/core/services/preferences_store.dart';
import 'package:farmacia_sae/models/home/views/home.dart';
import 'package:farmacia_sae/models/sales/models/sale_receipt.dart';
import 'package:farmacia_sae/models/sales/views/sales_page.dart';
import 'package:farmacia_sae/models/sales/widgets/product_catalog.dart';
import 'package:farmacia_sae/models/settings/models/app_preferences.dart';
import 'package:farmacia_sae/models/settings/widgets/data_tools.dart';
import 'package:farmacia_sae/shared/themes/app_theme.dart';
import 'package:farmacia_sae/shared/widgets/administration_appearance.dart';
import 'package:farmacia_sae/models/settings/views/settings_page.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'todas las preferencias adaptables $width ${mode.name} con contraste y texto grande',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final prefs = PreferencesController(MemoryPreferencesStore());
          addTearDown(prefs.dispose);
          await prefs.initialize();
          prefs.setThemeMode(mode);
          prefs.setAccent(AppAccent.teal);
          prefs.setHighContrast(true);
          prefs.setTextSize(AppTextSize.extraLarge);
          prefs.setDensity(WorkspaceDensity.compact);
          await prefs.flush();
          await tester.pumpWidget(
            MaterialApp(
              home: AdministrationAppearance(
                preferences: prefs,
                child: Scaffold(body: SettingsPage(preferences: prefs)),
              ),
            ),
          );
          await tester.pumpAndSettle();
          for (var section = 0; section < 3; section++) {
            await tester.ensureVisible(
              find.byKey(Key('preferences-section-$section')),
            );
            await tester.tap(find.byKey(Key('preferences-section-$section')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }
  testWidgets(
    'empleado personaliza su cuenta sin acceso a respaldos ni afectar otra cuenta',
    (tester) async {
      final prefs = PreferencesController(MemoryPreferencesStore());
      final auth = AuthController();
      addTearDown(prefs.dispose);
      addTearDown(auth.dispose);
      final login = auth.signIn('usuario', '1234');
      await tester.pump(const Duration(milliseconds: 450));
      await login;
      await tester.pumpWidget(
        FarmaciaApp(
          auth: auth,
          preferences: prefs,
          administrationStore: MemoryAdministrationStore(),
          initialLocation: '/administracion/preferencias',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mis preferencias'), findsWidgets);
      expect(find.byType(DataTools), findsNothing);
      expect(prefs.accountId, 'demo-employee');
      await tester.ensureVisible(find.byKey(const Key('theme-dark')));
      await tester.tap(find.byKey(const Key('theme-dark')));
      await tester.pumpAndSettle();
      expect(prefs.value.themeMode, ThemeMode.dark);
      await tester.ensureVisible(
        find.byKey(const Key('preferences-section-2')),
      );
      await tester.tap(find.byKey(const Key('preferences-section-2')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('confirm-clear-sale')));
      await tester.tap(find.byKey(const Key('confirm-clear-sale')));
      await tester.pumpAndSettle();
      expect(prefs.value.confirmClearSale, isFalse);
      await tester.ensureVisible(find.byKey(const Key('catalog-layout-list')));
      await tester.tap(find.byKey(const Key('catalog-layout-list')));
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
      router.go('/administracion/ventas');
      await tester.pumpAndSettle();
      expect(
        tester.widget<ProductCatalog>(find.byType(ProductCatalog)).layout,
        CatalogLayout.list,
      );
      auth.signOut();
      await tester.pumpAndSettle();
      final adminLogin = auth.signIn('admin', '1234');
      await tester.pump(const Duration(milliseconds: 450));
      await adminLogin;
      await tester.pumpAndSettle();
      expect(prefs.accountId, 'demo-admin');
      expect(prefs.value.themeMode, ThemeMode.system);
      expect(prefs.value.confirmClearSale, isTrue);
      prefs.useAccount('demo-employee');
      expect(prefs.value.themeMode, ThemeMode.dark);
      expect(prefs.value.catalogLayout, CatalogLayout.list);
      expect(tester.takeException(), isNull);
    },
  );

  for (final method in PaymentMethod.values) {
    testWidgets(
      'nuevo cobro registra ${method.name} con stock y trazabilidad intactos',
      (tester) async {
        final data = PharmacyController();
        addTearDown(data.dispose);
        final stock = data.stockTotal;
        data.addToCart(data.products.first);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: AnimatedBuilder(
                animation: data,
                builder: (_, _) =>
                    SalesPage(controller: data, onMessage: (_) {}),
              ),
            ),
          ),
        );
        if (find.textContaining('Venta (').evaluate().isNotEmpty) {
          await tester.tap(find.textContaining('Venta ('));
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(find.text('Completar venta'));
        await tester.tap(find.text('Completar venta'));
        await tester.pumpAndSettle();
        if (method != PaymentMethod.cash) {
          await tester.tap(find.widgetWithText(ChoiceChip, method.label));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('sale-tendered')), findsNothing);
        } else {
          await tester.enterText(find.byKey(const Key('sale-tendered')), '1');
          await tester.ensureVisible(find.text('Registrar venta'));
          await tester.tap(find.text('Registrar venta'));
          await tester.pumpAndSettle();
          expect(data.sales, isEmpty);
          expect(data.stockTotal, stock);
          await tester.enterText(find.byKey(const Key('sale-tendered')), '10');
        }
        await tester.ensureVisible(find.text('Registrar venta'));
        await tester.tap(find.text('Registrar venta'));
        await tester.pumpAndSettle();
        expect(data.sales.single.method, method);
        expect(data.sales.single.registerId, 'register-main-2');
        expect(data.stockTotal, stock - 1);
        expect(data.cashMovements, isEmpty);
        await tester.tap(find.text('Cerrar'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Historial de facturas'));
        await tester.tap(find.text('Historial de facturas'));
        await tester.pumpAndSettle();
        expect(find.textContaining(data.sales.single.id), findsOneWidget);
        await tester.tap(find.text(data.sales.single.id));
        await tester.pumpAndSettle();
        expect(
          find.text('Comprobante ${data.sales.single.id}'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'búsqueda por código, categoría y eliminación de línea sin tocar stock',
    (tester) async {
      final data = PharmacyController();
      addTearDown(data.dispose);
      final before = data.stockTotal;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AnimatedBuilder(
              animation: data,
              builder: (_, _) => SalesPage(controller: data, onMessage: (_) {}),
            ),
          ),
        ),
      );
      await tester.enterText(find.byKey(const Key('sales-search')), 'MED-001');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(data.cart.single.quantity, 1);
      if (find.textContaining('Venta (').evaluate().isNotEmpty) {
        await tester.tap(find.textContaining('Venta ('));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(
        find.byTooltip('Eliminar Paracetamol 500 mg de la venta'),
      );
      await tester.tap(
        find.byTooltip('Eliminar Paracetamol 500 mg de la venta'),
      );
      await tester.pumpAndSettle();
      expect(data.cart, isEmpty);
      expect(data.stockTotal, before);
    },
  );
}
