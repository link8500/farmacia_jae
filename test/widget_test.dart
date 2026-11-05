import 'package:flutter/material.dart';
import 'package:farmacia_sae/core/services/local_administration_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:farmacia_sae/main.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';
import 'package:farmacia_sae/core/routing/app_router.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/shared/themes/app_theme.dart';
import 'package:farmacia_sae/models/dashboard/widgets/sales_chart_card.dart';
import 'package:farmacia_sae/models/home/views/home.dart';
import 'package:farmacia_sae/models/presentation/views/presentation_page.dart';

Future<AuthController> signInForTest(
  WidgetTester tester, {
  bool admin = true,
}) async {
  final auth = AuthController();
  final future = auth.signIn(
    AuthController.demoUsers[admin ? 0 : 1].username,
    AuthController.demoPassword,
  );
  await tester.pump(const Duration(milliseconds: 450));
  expect(await future, isNull);
  addTearDown(auth.dispose);
  return auth;
}

/// Revisa separación pública/privada, sesión, perfiles y anchuras responsive.
void main() {
  testWidgets('login solicita usuario y rellena las dos credenciales demo', (
    tester,
  ) async {
    await tester.pumpWidget(
      FarmaciaApp(
        administrationStore: MemoryAdministrationStore(),
        initialLocation: '/administracion/login',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsNothing);
    final username = find.byKey(const Key('login-username'));
    final password = find.byKey(const Key('login-password'));
    for (final account in [
      ('Probar administrador', 'admin'),
      ('Probar empleado', 'usuario'),
    ]) {
      await tester.ensureVisible(find.text(account.$1));
      await tester.tap(find.text(account.$1));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(username).controller!.text,
        account.$2,
      );
      expect(tester.widget<TextFormField>(password).controller!.text, '1234');
      expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    }
  });

  testWidgets('presentación y login no inicializan datos operativos', (
    tester,
  ) async {
    final auth = AuthController();
    var privateInitializations = 0;
    final router = createAppRouter(
      auth: auth,
      initialLocation: '/presentacion',
      pharmacyProvider: () {
        privateInitializations++;
        return PharmacyController();
      },
    );
    addTearDown(router.dispose);
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    expect(privateInitializations, 0);
    router.go('/administracion/inventario');
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(privateInitializations, 0);
  });

  testWidgets('edición del perfil guarda en memoria sin cambiar permisos', (
    tester,
  ) async {
    final auth = await signInForTest(tester);
    await tester.pumpWidget(
      FarmaciaApp(
        administrationStore: MemoryAdministrationStore(),
        auth: auth,
        initialLocation: '/administracion/perfil',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile-name')));
    await tester.enterText(find.byKey(const Key('profile-name')), 'Ana Demo');
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(auth.user!.name, 'Ana Demo');
    expect(auth.user!.isAdministrator, isTrue);
    expect(auth.user!.email, 'admin@farmaciajae.demo');
    expect(tester.takeException(), isNull);
  });
  testWidgets('la raíz muestra presentación y no enlaza a administración', (
    tester,
  ) async {
    await tester.pumpWidget(
      FarmaciaApp(administrationStore: MemoryAdministrationStore()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PresentationPage), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('Iniciar sesión'), findsNothing);
    expect(find.text('Administración'), findsNothing);
    expect(find.text('Cuidado que\nacompaña tu día.'), findsOneWidget);
    expect(find.byKey(const Key('home-promotions')), findsOneWidget);
  });

  testWidgets('abrir un inventario privado sin sesión muestra login', (
    tester,
  ) async {
    await tester.pumpWidget(
      FarmaciaApp(
        administrationStore: MemoryAdministrationStore(),
        initialLocation: '/administracion/inventario',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(
      GoRouter.of(
        tester.element(find.byKey(const Key('login-username'))),
      ).routeInformationProvider.value.uri.toString(),
      '/administracion',
    );
    expect(find.text('Registrarse'), findsNothing);
    expect(find.text('Crear cuenta'), findsNothing);
  });

  testWidgets('login válido muestra el resumen en la URL limpia', (
    tester,
  ) async {
    await tester.pumpWidget(
      FarmaciaApp(
        administrationStore: MemoryAdministrationStore(),
        initialLocation: '/administracion/inventario',
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('login-username')),
      AuthController.demoUsers[0].username,
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      AuthController.demoPassword,
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Bienvenido de nuevo'), findsNothing);
    final context = tester.element(find.byType(HomeScreen));
    expect(
      GoRouter.of(context).routeInformationProvider.value.uri.path,
      '/administracion',
    );
  });

  testWidgets('dashboard conserva módulos e incorpora barras comparativas', (
    tester,
  ) async {
    final auth = await signInForTest(tester);
    await tester.pumpWidget(
      FarmaciaApp(
        administrationStore: MemoryAdministrationStore(),
        auth: auth,
        initialLocation: '/administracion',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Buenos días, equipo'), findsOneWidget);
    expect(find.text('Estado de la operación'), findsNothing);
    expect(find.text('Actividad reciente'), findsNothing);
    expect(find.byType(SalesChartCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('perfil administrador muestra identidad y privilegios', (
    tester,
  ) async {
    final auth = await signInForTest(tester);
    await tester.pumpWidget(
      FarmaciaApp(
        administrationStore: MemoryAdministrationStore(),
        auth: auth,
        initialLocation: '/administracion/perfil',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Perfil del administrador'), findsOneWidget);
    await tester.ensureVisible(find.text('Acceso y seguridad'));
    await tester.tap(find.text('Acceso y seguridad'));
    await tester.pumpAndSettle();
    expect(find.text('15 de 15 vistas'), findsOneWidget);
    expect(find.text('Ana Martínez'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('perfil empleado y guard de configuración funcionan juntos', (
    tester,
  ) async {
    final auth = await signInForTest(tester, admin: false);
    await tester.pumpWidget(
      FarmaciaApp(
        administrationStore: MemoryAdministrationStore(),
        auth: auth,
        initialLocation: '/administracion/configuracion',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Perfil del empleado'), findsOneWidget);
    await tester.ensureVisible(find.text('Acceso y seguridad'));
    await tester.tap(find.text('Acceso y seguridad'));
    await tester.pumpAndSettle();
    expect(find.text('9 de 15 vistas'), findsOneWidget);
    expect(find.text('Configuración general'), findsNothing);
    expect(
      GoRouter.of(
        tester.element(find.byType(HomeScreen)),
      ).routeInformationProvider.value.uri.path,
      '/administracion/perfil',
    );
  });

  testWidgets('cerrar sesión impide volver a una página privada', (
    tester,
  ) async {
    final auth = await signInForTest(tester);
    await tester.pumpWidget(
      FarmaciaApp(
        administrationStore: MemoryAdministrationStore(),
        auth: auth,
        initialLocation: '/administracion/perfil',
      ),
    );
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    auth.signOut();
    await tester.pumpAndSettle();
    router.go('/administracion/inventario');
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
  });

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('dashboard y gráfico se adaptan a $width px', (tester) async {
      tester.view
        ..physicalSize = Size(width, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final auth = await signInForTest(tester);
      await tester.pumpWidget(
        FarmaciaApp(
          administrationStore: MemoryAdministrationStore(),
          auth: auth,
          initialLocation: '/administracion',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SalesChartCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    testWidgets('presentación se adapta a $width px', (tester) async {
      tester.view
        ..physicalSize = Size(width, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        FarmaciaApp(administrationStore: MemoryAdministrationStore()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PresentationPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('login y perfil se adaptan a $width px', (tester) async {
      tester.view
        ..physicalSize = Size(width, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final auth = AuthController();
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        FarmaciaApp(
          administrationStore: MemoryAdministrationStore(),
          auth: auth,
          initialLocation: '/administracion/perfil',
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final future = auth.signIn(
        AuthController.demoUsers[1].username,
        AuthController.demoPassword,
      );
      await tester.pump(const Duration(milliseconds: 450));
      expect(await future, isNull);
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/administracion',
      );
      router.go('/administracion/perfil');
      await tester.pumpAndSettle();
      expect(find.text('Perfil del empleado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
