import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:farmacia_sae/core/services/local_administration_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:farmacia_sae/core/app.dart';
import 'package:farmacia_sae/core/routing/app_router.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/core/services/preferences_controller.dart';
import 'package:farmacia_sae/core/services/preferences_store.dart';
import 'package:farmacia_sae/models/home/views/home.dart';
import 'package:farmacia_sae/models/presentation/views/presentation_page.dart';
import 'package:farmacia_sae/models/settings/models/app_preferences.dart';
import 'package:farmacia_sae/models/settings/views/settings_page.dart';
import 'package:farmacia_sae/shared/themes/app_theme.dart';

Future<AuthController> signedIn(WidgetTester tester) async {
  final auth = AuthController();
  final signing = auth.signIn(
    AuthController.demoUsers.first.username,
    AuthController.demoPassword,
  );
  await tester.pump(const Duration(milliseconds: 450));
  await signing;
  addTearDown(auth.dispose);
  return auth;
}

void main() {
  testWidgets(
    'cambiar tema actualiza la administración y se puede restablecer',
    (tester) async {
      final prefs = PreferencesController(MemoryPreferencesStore());
      await prefs.initialize();
      prefs.useAccount('demo-admin');
      addTearDown(prefs.dispose);
      final auth = await signedIn(tester);
      await tester.pumpWidget(
        FarmaciaApp(
          administrationStore: MemoryAdministrationStore(),
          auth: auth,
          preferences: prefs,
          initialLocation: '/administracion/preferencias',
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('theme-dark')));
      await tester.tap(find.byKey(const Key('theme-dark')));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(SettingsPage))).brightness,
        Brightness.dark,
      );
      expect(prefs.value.themeMode, ThemeMode.dark);
      await tester.ensureVisible(find.byKey(const Key('preferences-reset')));
      await tester.tap(find.byKey(const Key('preferences-reset')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restablecer').last);
      await tester.pumpAndSettle();
      expect(prefs.value.themeMode, ThemeMode.system);
    },
  );

  testWidgets(
    'la presentación permanece clara, con escala normal y sin cargar preferencias',
    (tester) async {
      final prefs = PreferencesController(
        MemoryPreferencesStore(
          jsonEncode(
            const AppPreferences(
              themeMode: ThemeMode.dark,
              textSize: AppTextSize.extraLarge,
              reduceMotion: true,
            ).toJson(),
          ),
        ),
      );
      addTearDown(prefs.dispose);
      await tester.pumpWidget(
        FarmaciaApp(
          administrationStore: MemoryAdministrationStore(),
          preferences: prefs,
          initialLocation: '/presentacion',
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(PresentationPage));
      expect(Theme.of(context).brightness, Brightness.light);
      expect(MediaQuery.textScalerOf(context).scale(1), 1);
      expect(prefs.isLoaded, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tema del sistema responde cuando cambia el brillo del dispositivo',
    (tester) async {
      final prefs = PreferencesController(MemoryPreferencesStore());
      await prefs.initialize();
      prefs.useAccount('demo-admin');
      addTearDown(prefs.dispose);
      final auth = await signedIn(tester);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(
        FarmaciaApp(
          administrationStore: MemoryAdministrationStore(),
          auth: auth,
          preferences: prefs,
          initialLocation: '/administracion/preferencias',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(SettingsPage))).brightness,
        Brightness.dark,
      );
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(SettingsPage))).brightness,
        Brightness.light,
      );
    },
  );

  testWidgets(
    'confirmar vaciado protege el carrito y desactivarlo tiene efecto',
    (tester) async {
      final prefs = PreferencesController(MemoryPreferencesStore());
      await prefs.initialize();
      prefs.useAccount('demo-admin');
      addTearDown(prefs.dispose);
      final auth = await signedIn(tester);
      final pharmacy = PharmacyController();
      addTearDown(pharmacy.dispose);
      pharmacy.addToCart(pharmacy.products.first);
      final router = createAppRouter(
        auth: auth,
        preferences: prefs,
        pharmacyProvider: () => pharmacy,
        initialLocation: '/administracion/ventas',
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
      await tester.pumpAndSettle();
      if (find.textContaining('Venta (').evaluate().isNotEmpty) {
        await tester.tap(find.textContaining('Venta ('));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Vaciar'));
      await tester.tap(find.text('Vaciar'));
      await tester.pumpAndSettle();
      expect(find.text('¿Vaciar la venta?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(pharmacy.cart, hasLength(1));
      prefs.setConfirmClearSale(false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vaciar'));
      await tester.pumpAndSettle();
      expect(pharmacy.cart, isEmpty);
      expect(pharmacy.stockTotal, 211);
    },
  );

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets(
      'preferencias, dashboard y perfil oscuros con texto grande a $width px',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final prefs = PreferencesController(MemoryPreferencesStore());
        await prefs.initialize();
        prefs.useAccount('demo-admin');
        addTearDown(prefs.dispose);
        prefs.setThemeMode(ThemeMode.dark);
        prefs.setTextSize(AppTextSize.extraLarge);
        prefs.setReduceMotion(true);
        prefs.setNotificationBadges(false);
        await prefs.flush();
        final auth = await signedIn(tester);
        await tester.pumpWidget(
          FarmaciaApp(
            administrationStore: MemoryAdministrationStore(),
            auth: auth,
            preferences: prefs,
            initialLocation: '/administracion/preferencias',
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final context = tester.element(find.byType(HomeScreen));
        expect(MediaQuery.disableAnimationsOf(context), isTrue);
        expect(MediaQuery.textScalerOf(context).scale(1), 1.2);
        final router = GoRouter.of(context);
        for (final path in [
          '/administracion',
          '/administracion/perfil',
          '/administracion/productos',
          '/administracion/inventario',
          '/administracion/compras',
          '/administracion/proveedores',
          '/administracion/clientes',
          '/administracion/caja',
          '/administracion/ventas',
          '/administracion/reportes',
          '/administracion/incidentes',
        ]) {
          router.go(path);
          await tester.pumpAndSettle();
          expect(
            MediaQuery.textScalerOf(
              tester.element(find.byType(HomeScreen)),
            ).scale(1),
            1.2,
            reason: path,
          );
          expect(tester.takeException(), isNull, reason: path);
        }
      },
    );
  }
}
