import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:farmacia_sae/core/app.dart';
import 'package:farmacia_sae/core/routing/app_paths.dart';
import 'package:farmacia_sae/core/routing/auth_guard.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';
import 'package:farmacia_sae/core/services/local_administration_store.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/models/auth/models/session_user.dart';
import 'package:farmacia_sae/models/home/views/home.dart';
import 'package:farmacia_sae/models/organization/models/organization.dart';
import 'package:farmacia_sae/models/organization/views/organization_page.dart';
import 'package:farmacia_sae/models/organization/views/registers_page.dart';
import 'package:farmacia_sae/models/organization/widgets/staff_form_dialog.dart';
import 'package:farmacia_sae/models/sales/models/sale_receipt.dart';
import 'package:farmacia_sae/shared/themes/app_theme.dart';
import 'package:farmacia_sae/shared/widgets/administration_breadcrumbs.dart';

void main() {
  String? update(
    PharmacyController data,
    StaffMember member, {
    UserRole? role,
    bool? active,
    String? branch,
    String? register,
  }) => data.saveStaff(
    id: member.id,
    name: member.name,
    username: member.username,
    branchId: branch ?? member.branchId,
    registerId: register ?? member.registerId,
    jobTitle: member.jobTitle,
    role: role,
    active: active ?? member.active,
  );

  test(
    'roles y asignación se guardan juntos y sobreviven al respaldo',
    () async {
      final data = PharmacyController();
      addTearDown(data.dispose);
      data.addToCart(data.products.first);
      expect(
        data.checkoutSale(method: PaymentMethod.cash, tendered: 20),
        isNull,
      );
      final original = data.sales.single.toJson();
      data.saveBranch(name: 'Sucursal norte');
      final branch = data.branches.last.id;
      data.saveRegister(branchId: branch, name: 'Caja norte');
      final register = data.registers.last.id;
      expect(
        update(
          data,
          data.staffById('demo-employee')!,
          role: UserRole.administrator,
          branch: branch,
          register: register,
        ),
        isNull,
      );
      expect(data.staffById('demo-employee')!.role, UserRole.administrator);
      expect(data.sales.single.toJson(), original);
      final restored = PharmacyController(
        store: MemoryAdministrationStore(data.createBackup()),
      );
      addTearDown(restored.dispose);
      await restored.initialize();
      expect(restored.loadFailed, isFalse);
      expect(restored.staffById('demo-employee')!.role, UserRole.administrator);
      expect(restored.staffById('demo-employee')!.registerId, register);
      expect(restored.sales.single.toJson(), original);
      expect(
        update(data, data.staffById('demo-employee')!, role: UserRole.employee),
        isNull,
      );
    },
  );

  test(
    'no se puede quitar el acceso principal ni el propio y no hay autoascenso',
    () {
      var actor = AuthController.demoUsers.first;
      final data = PharmacyController(userProvider: () => actor);
      addTearDown(data.dispose);
      final root = data.staffById(actor.id)!;
      expect(update(data, root, role: UserRole.employee), isNotNull);
      expect(update(data, root, active: false, register: ''), isNotNull);
      data.saveStaff(
        name: 'Responsable',
        username: 'responsable',
        branchId: mainBranchId,
        role: UserRole.administrator,
      );
      actor = data.staff.last.session;
      expect(
        update(data, data.staffById(actor.id)!, role: UserRole.employee),
        isNotNull,
      );
      actor = AuthController.demoUsers.last;
      expect(
        update(data, data.currentStaff!, role: UserRole.administrator),
        isNotNull,
      );
      expect(data.currentStaff!.role, UserRole.employee);
    },
  );

  test('un error de caja no modifica parcialmente el rol', () {
    final data = PharmacyController();
    addTearDown(data.dispose);
    final member = data.staffById('demo-employee')!;
    expect(
      update(
        data,
        member,
        role: UserRole.administrator,
        register: 'register-main-2',
      ),
      isNotNull,
    );
    expect(data.staffById(member.id)!.role, UserRole.employee);
    expect(data.staffById(member.id)!.registerId, member.registerId);
  });

  test(
    'los destinos conservan sub-vistas permitidas y descartan parámetros ajenos',
    () async {
      final auth = AuthController();
      addTearDown(auth.dispose);
      final guard = AuthGuard(auth);
      final uri = Uri.parse(
        '${AppPaths.sections[1]}?vista=historial&destino=https://otro.example',
      );
      final redirected = Uri.parse(guard.redirect(uri)!);
      expect(redirected.path, AppPaths.administration);
      expect(redirected.hasQuery, isFalse);
      await auth.signIn('usuario', '1234');
      expect(
        guard.redirect(
          Uri(
            path: AppPaths.login,
            queryParameters: {'desde': AppPaths.salesLocation(true)},
          ),
        ),
        AppPaths.administration,
      );
      expect(
        AppPaths.safeDestination('${AppPaths.organization}?vista=historial'),
        AppPaths.organization,
      );
      expect(
        AppPaths.safeDestination(
          'https://otro.example${AppPaths.sections[1]}?vista=historial',
        ),
        AppPaths.administration,
      );
    },
  );

  testWidgets(
    'la app respeta el rol administrado de usuario al iniciar sesión',
    (tester) async {
      final data = PharmacyController();
      addTearDown(data.dispose);
      update(
        data,
        data.staffById('demo-employee')!,
        role: UserRole.administrator,
      );
      final auth = AuthController();
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        FarmaciaApp(
          auth: auth,
          administrationStore: MemoryAdministrationStore(data.createBackup()),
          initialLocation: AppPaths.organization,
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('login-username')),
        'usuario',
      );
      await tester.enterText(find.byKey(const Key('login-password')), '1234');
      await tester.ensureVisible(find.text('Iniciar sesión'));
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(auth.user!.role, UserRole.administrator);
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
      expect(
        router.routeInformationProvider.value.uri.toString(),
        AppPaths.administration,
      );
      router.go(AppPaths.organization);
      await tester.pumpAndSettle();
      expect(find.byType(OrganizationPage), findsOneWidget);
      expect(find.byKey(const Key('staff-add')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('breadcrumb-current'))).data,
        'Personal',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('breadcrumb sigue sub-vistas, URL, volver y preferencias', (
    tester,
  ) async {
    final auth = AuthController();
    addTearDown(auth.dispose);
    final signIn = auth.signIn('admin', '1234');
    await tester.pump(const Duration(milliseconds: 500));
    await signIn;
    await tester.pumpWidget(
      FarmaciaApp(
        auth: auth,
        administrationStore: MemoryAdministrationStore(),
        initialLocation: AppPaths.sections[1],
      ),
    );
    await tester.pumpAndSettle();
    String? current() =>
        tester.widget<Text>(find.byKey(const Key('breadcrumb-current'))).data;
    expect(current(), 'Nueva factura');
    expect(find.text('Sucursal de trabajo'), findsNothing);
    await tester.tap(find.text('Historial de facturas'));
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    expect(
      router.routeInformationProvider.value.uri.queryParameters['vista'],
      'historial',
    );
    expect(current(), 'Historial de facturas');
    await tester.tap(
      find.descendant(
        of: find.byType(AdministrationBreadcrumbs),
        matching: find.widgetWithText(TextButton, 'Facturación'),
      ),
    );
    await tester.pumpAndSettle();
    expect(current(), 'Nueva factura');
    router.go(AppPaths.preferenceLocation(1));
    await tester.pumpAndSettle();
    expect(current(), 'Accesibilidad');
    await tester.tap(find.byKey(const Key('preferences-section-2')));
    await tester.pumpAndSettle();
    expect(current(), 'Facturación y avisos');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['seccion'],
      'facturacion',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('formulario cambia rol, sede y caja en una sola operación', (
    tester,
  ) async {
    final data = PharmacyController();
    addTearDown(data.dispose);
    data.saveBranch(name: 'Sucursal norte');
    final branch = data.branches.last.id;
    data.saveRegister(branchId: branch, name: 'Caja norte');
    final register = data.registers.last.id;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StaffFormDialog(
            controller: data,
            member: data.staffById('demo-employee'),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('staff-role')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Administrador').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('staff-branch')));
    await tester.tap(find.byKey(const Key('staff-branch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sucursal norte').last);
    await tester.pumpAndSettle();
    final registerField = find.byKey(ValueKey('staff-register-$branch-'));
    await tester.ensureVisible(registerField);
    await tester.tap(registerField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Caja norte').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('staff-save')));
    await tester.tap(find.byKey(const Key('staff-save')));
    await tester.pumpAndSettle();
    final member = data.staffById('demo-employee')!;
    expect(member.role, UserRole.administrator);
    expect(member.branchId, branch);
    expect(member.registerId, register);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cajas de facturación ya no duplica editores', (tester) async {
    final data = PharmacyController();
    addTearDown(data.dispose);
    var manage = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: RegistersPage(controller: data, onManage: () => manage = true),
        ),
      ),
    );
    expect(find.text('Crear caja'), findsNothing);
    expect(find.text('Editar caja'), findsNothing);
    await tester.tap(find.text('Personal y asignaciones'));
    expect(manage, isTrue);
  });

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets(
      'rutas de todos los módulos y gestión expandida adaptables $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final index in AppPaths.enabledSectionIndices) {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 1100),
                  textScaler: TextScaler.linear(1.6),
                ),
                child: Scaffold(
                  body: AdministrationBreadcrumbs(
                    section: index,
                    uri: Uri.parse(AppPaths.sections[index]),
                    onNavigate: (_) {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('breadcrumb-current')), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        final data = PharmacyController();
        addTearDown(data.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1100),
                textScaler: TextScaler.linear(1.6),
              ),
              child: Scaffold(body: OrganizationPage(controller: data)),
            ),
          ),
        );
        await tester.ensureVisible(find.byKey(const Key('organization-tab-1')));
        await tester.tap(find.byKey(const Key('organization-tab-1')));
        await tester.pumpAndSettle();
        expect(find.text('Sucursal principal'), findsOneWidget);
        await tester.ensureVisible(find.byKey(const Key('organization-tab-2')));
        await tester.tap(find.byKey(const Key('organization-tab-2')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Crear caja'));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
