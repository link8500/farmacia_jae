import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:farmacia_sae/core/app.dart';
import 'package:farmacia_sae/core/routing/app_paths.dart';
import 'package:farmacia_sae/core/routing/app_router.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';
import 'package:farmacia_sae/core/services/local_administration_store.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/core/services/promotion_store.dart';
import 'package:farmacia_sae/core/services/promotions_controller.dart';
import 'package:farmacia_sae/models/presentation/views/about_page.dart';
import 'package:farmacia_sae/models/presentation/views/contact_page.dart';
import 'package:farmacia_sae/models/presentation/views/presentation_page.dart';
import 'package:farmacia_sae/models/presentation/views/public_promotions_page.dart';
import 'package:farmacia_sae/models/presentation/views/services_page.dart';
import 'package:farmacia_sae/models/promotions/models/promotion.dart';
import 'package:farmacia_sae/models/promotions/views/promotions_admin_page.dart';
import 'package:farmacia_sae/models/reports/views/reports_page.dart';
import 'package:farmacia_sae/models/reports/widgets/report_chart_card.dart';
import 'package:farmacia_sae/models/sales/models/sale_receipt.dart';
import 'package:farmacia_sae/shared/themes/app_theme.dart';

void main() {
  testWidgets(
    'navegación pública usa vistas reales sin inicializar operaciones',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = AuthController();
      addTearDown(auth.dispose);
      var privateLoads = 0;
      final promotions = PromotionsController(
        store: MemoryPromotionStore(),
        canManage: () => false,
      );
      addTearDown(promotions.dispose);
      final router = createAppRouter(
        auth: auth,
        promotions: promotions,
        initialLocation: AppPaths.presentation,
        pharmacyProvider: () {
          privateLoads++;
          throw StateError('Public must not load operations');
        },
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
      await tester.pumpAndSettle();
      for (final link in [
        ('Nosotros', AboutPage),
        ('Servicios', ServicesPage),
        ('Promociones', PublicPromotionsPage),
        ('Contacto', ContactPage),
        ('Inicio', PresentationPage),
      ]) {
        await tester.tap(find.byKey(Key('public-nav-${link.$1}')));
        await tester.pumpAndSettle();
        expect(find.byType(link.$2), findsOneWidget);
        expect(find.text('Iniciar sesión'), findsNothing);
        expect(find.text('Administración'), findsNothing);
        expect(tester.takeException(), isNull);
      }
      expect(privateLoads, 0);
    },
  );
  testWidgets(
    'crear una promoción publicada desde administración aparece en su ruta pública',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = AuthController();
      addTearDown(auth.dispose);
      final login = auth.signIn('admin', '1234');
      await tester.pump(const Duration(milliseconds: 450));
      expect(await login, isNull);
      final store = MemoryPromotionStore();
      await tester.pumpWidget(
        FarmaciaApp(
          auth: auth,
          administrationStore: MemoryAdministrationStore(),
          promotionStore: store,
          initialLocation: AppPaths.promotions,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PromotionsAdminPage), findsOneWidget);
      await tester.tap(find.byKey(const Key('promotion-create')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('promotion-title')),
        'Campaña de bienestar',
      );
      await tester.enterText(
        find.byKey(const Key('promotion-description')),
        'Contenido informativo de prueba.',
      );
      await tester.ensureVisible(find.byKey(const Key('promotion-status')));
      await tester.tap(find.byKey(const Key('promotion-status')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publicada').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('promotion-save')));
      await tester.tap(find.byKey(const Key('promotion-save')));
      await tester.pumpAndSettle();
      expect(store.publicData, contains('Campaña de bienestar'));
      await tester.ensureVisible(
        find.text('Ver página pública de promociones'),
      );
      await tester.tap(find.text('Ver página pública de promociones'));
      await tester.pumpAndSettle();
      expect(find.byType(PublicPromotionsPage), findsOneWidget);
      expect(find.text('Campaña de bienestar'), findsOneWidget);
      expect(find.text('Nueva promoción'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'empleado no accede a la nueva ruta de promociones administrativas',
    (tester) async {
      final auth = AuthController();
      addTearDown(auth.dispose);
      final login = auth.signIn('usuario', '1234');
      await tester.pump(const Duration(milliseconds: 450));
      await login;
      await tester.pumpWidget(
        FarmaciaApp(
          auth: auth,
          administrationStore: MemoryAdministrationStore(),
          promotionStore: MemoryPromotionStore(),
          initialLocation: AppPaths.promotions,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PromotionsAdminPage), findsNothing);
      expect(
        GoRouter.of(
          tester.element(find.text('Perfil del empleado')),
        ).routeInformationProvider.value.uri.path,
        AppPaths.profile,
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'reportes completos y vistas públicas adaptables $width oscuro=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final data = PharmacyController();
          addTearDown(data.dispose);
          data.addToCart(data.products.first);
          data.checkoutSale(method: PaymentMethod.cash, tendered: 100);
          final promotions = PromotionsController(
            store: MemoryPromotionStore(),
            canManage: () => true,
          );
          addTearDown(promotions.dispose);
          await promotions.loadEditor();
          await promotions.save(
            Promotion(
              id: '',
              title: 'Campaña con nombre largo para revisar legibilidad',
              description:
                  'Información de prueba para comprobar el diseño adaptable.',
              startsAt: promotions.today,
              endsAt: promotions.today,
            ),
          );
          final router = GoRouter(
            initialLocation: '/',
            routes: [GoRoute(path: '/', builder: (_, _) => const SizedBox())],
          );
          addTearDown(router.dispose);
          // Las vistas públicas necesitan GoRouter para sus enlaces, pero no realizan
          // navegación en esta prueba de geometría y escala de texto.
          Future<void> mount(Widget page) async {
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 1000),
                    textScaler: const TextScaler.linear(1.5),
                  ),
                  child: Scaffold(body: page),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }

          await mount(ReportsPage(controller: data));
          expect(find.byType(ReportChartCard), findsOneWidget);
          expect(find.byType(LineChart), findsOneWidget);
          final selector = find.descendant(
            of: find.byKey(const Key('report-chart-select')),
            matching: find.byType(DropdownButton<String>),
          );
          expect(
            tester.widget<DropdownButton<String>>(selector).items,
            hasLength(7),
          );
          await tester.tap(find.byKey(const Key('report-detail-view')));
          await tester.pumpAndSettle();
          expect(
            find.textContaining('Total: C\$ 3.50 · Vigente'),
            findsOneWidget,
          );
          await tester.ensureVisible(find.byKey(const Key('report-search')));
          await tester.enterText(
            find.byKey(const Key('report-search')),
            'NO-COINCIDE',
          );
          await tester.pumpAndSettle();
          expect(
            find.text('No hay registros en este período o búsqueda.'),
            findsOneWidget,
          );
          await tester.tap(find.text('Gráficos').first);
          await tester.pumpAndSettle();
          expect(find.byType(LineChart), findsOneWidget);
          for (final page in [
            const PresentationPage(),
            const AboutPage(),
            const ServicesPage(),
            const ContactPage(),
            PublicPromotionsPage(controller: promotions),
            PromotionsAdminPage(controller: promotions, onPublicPage: () {}),
          ]) {
            await mount(page);
          }
        },
      );
    }
  }
}
