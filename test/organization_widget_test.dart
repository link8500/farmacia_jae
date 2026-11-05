import 'package:flutter/material.dart';
import 'package:farmacia_sae/core/app.dart';
import 'package:farmacia_sae/core/services/local_administration_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/models/auth/models/session_user.dart';
import 'package:farmacia_sae/models/organization/views/organization_page.dart';
import 'package:farmacia_sae/models/organization/views/registers_page.dart';
import 'package:farmacia_sae/models/organization/widgets/staff_form_dialog.dart';
import 'package:farmacia_sae/models/reports/views/reports_page.dart';
import 'package:farmacia_sae/models/sales/models/sale_receipt.dart';
import 'package:farmacia_sae/shared/themes/app_theme.dart';
import 'package:farmacia_sae/shared/widgets/administration_breadcrumbs.dart';
import 'package:farmacia_sae/models/home/views/home.dart';

void main() {
  testWidgets(
    'login de la app recupera empleados y su sede desde el respaldo local',
    (tester) async {
      final data = PharmacyController();
      addTearDown(data.dispose);
      data.saveBranch(name: 'Sucursal 2');
      final branch = data.branches.last.id;
      data.saveRegister(branchId: branch, name: 'Caja 3');
      data.saveStaff(
        name: 'Elena Suárez',
        username: 'elena',
        branchId: branch,
        registerId: data.registers.last.id,
      );
      final store = MemoryAdministrationStore(data.createBackup());
      final auth = AuthController();
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        FarmaciaApp(
          auth: auth,
          administrationStore: store,
          initialLocation: '/administracion/login',
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('login-username')), 'elena');
      await tester.enterText(find.byKey(const Key('login-password')), '1234');
      await tester.ensureVisible(find.text('Iniciar sesión'));
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(auth.user?.username, 'elena');
      expect(auth.user?.role, UserRole.employee);
      expect(find.text('Sucursal: Sucursal 2'), findsNothing);
      expect(find.text('Caja: Caja 3'), findsNothing);
      final operations = tester
          .widget<HomeScreen>(find.byType(HomeScreen))
          .controller!;
      expect(operations.workingBranchId, branch);
      expect(operations.currentRegister?.name, 'Caja 3');
      expect(find.byKey(const Key('breadcrumb-current')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('crear empleado y asignar sucursal y caja desde el formulario', (
    tester,
  ) async {
    final data = PharmacyController();
    addTearDown(data.dispose);
    data.saveBranch(name: 'Sucursal 2');
    final branch = data.branches.last.id;
    data.saveRegister(branchId: branch, name: 'Caja 3');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => StaffFormDialog(controller: data),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('staff-name')), 'Empleado 2');
    await tester.enterText(
      find.byKey(const Key('staff-username')),
      'empleado2',
    );
    await tester.ensureVisible(find.byKey(const Key('staff-branch')));
    await tester.tap(find.byKey(const Key('staff-branch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sucursal 2').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('staff-name')))
          .controller!
          .text,
      'Empleado 2',
    );
    final registerField = find.byKey(ValueKey('staff-register-$branch-'));
    await tester.ensureVisible(registerField);
    await tester.tap(registerField);
    await tester.pumpAndSettle();
    expect(find.text('Caja 3'), findsOneWidget);
    expect(find.text('Caja 1'), findsNothing);
    await tester.tap(find.text('Caja 3'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('staff-save')));
    await tester.tap(find.byKey(const Key('staff-save')));
    await tester.pumpAndSettle();
    final member = data.staff.last;
    expect(member.username, 'empleado2');
    expect(member.branchId, branch);
    expect(member.registerId, data.registers.last.id);
    expect(member.role, UserRole.employee);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'caja muestra operador actual, productos y comprobante histórico',
    (tester) async {
      var actor = AuthController.demoUsers.last;
      final data = PharmacyController(userProvider: () => actor);
      addTearDown(data.dispose);
      data.addToCart(data.products.first);
      data.checkoutSale(method: PaymentMethod.cash, tendered: 10);
      actor = AuthController.demoUsers.first;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: RegistersPage(controller: data)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Daniel López'), findsOneWidget);
      await tester.tap(find.text('Caja 1'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Operador actual: Daniel López'),
        findsOneWidget,
      );
      await tester.tap(find.text('Productos vendidos'));
      await tester.pumpAndSettle();
      expect(find.text('Paracetamol 500 mg'), findsOneWidget);
      await tester.tap(find.text('Facturas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(data.sales.single.id));
      await tester.pumpAndSettle();
      expect(find.text('Operador: Daniel López'), findsOneWidget);
      expect(
        find.text('Sucursal: Sucursal principal · Caja: Caja 1'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'organización, cajas y filtros adaptables $width oscuro=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final data = PharmacyController();
          addTearDown(data.dispose);
          data.saveBranch(name: 'Sucursal con nombre de referencia largo');
          for (final page in [
            OrganizationPage(controller: data),
            RegistersPage(controller: data),
            ReportsPage(controller: data),
          ]) {
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 1000),
                    textScaler: TextScaler.linear(1.2),
                  ),
                  child: Scaffold(
                    body: Column(
                      children: [
                        AdministrationBreadcrumbs(
                          section: 12,
                          uri: Uri.parse('/administracion/sucursales'),
                          onNavigate: (_) {},
                        ),
                        Expanded(child: page),
                      ],
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  testWidgets(
    'vista de organización no permite gestionar a empleado sin rol admin',
    (tester) async {
      final data = PharmacyController(
        userProvider: () => AuthController.demoUsers.last,
      );
      addTearDown(data.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: OrganizationPage(controller: data)),
        ),
      );
      expect(find.text('Crear sucursal'), findsNothing);
      expect(
        find.text('Solo administración puede gestionar sucursales y personal.'),
        findsOneWidget,
      );
    },
  );
}
