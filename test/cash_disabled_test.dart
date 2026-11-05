import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:farmacia_sae/core/routing/app_paths.dart';
import 'package:farmacia_sae/core/routing/app_router.dart';
import 'package:farmacia_sae/core/routing/auth_guard.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';
import 'package:farmacia_sae/core/services/pharmacy_controller.dart';
import 'package:farmacia_sae/models/cash/views/cash_page.dart';
import 'package:farmacia_sae/models/home/models/admin_modules.dart';
import 'package:farmacia_sae/models/home/views/home.dart';
import 'package:farmacia_sae/models/purchases/models/purchase_order.dart';
import 'package:farmacia_sae/models/sales/models/sale_receipt.dart';
import 'package:farmacia_sae/shared/themes/app_theme.dart';

/// La suspensión debe ser reversible sin cobrar o devolver efectivo ocultamente.
void main() {
  late PharmacyController data;
  setUp(() => data = PharmacyController());
  tearDown(() => data.dispose());

  test('Caja queda suspendida y ninguna orden cambia su historial', () {
    expect(data.cashEnabled, isFalse);
    expect(data.openCashSession(100), isNotNull);
    expect(data.closeCashSession(100), isNotNull);
    expect(data.cashAdjustment(100, 'Fondo'), isNotNull);
    expect(data.cashSessions, isEmpty);
    expect(data.cashMovements, isEmpty);
    expect(data.audit, isEmpty);
  });
  for (final method in PaymentMethod.values) {
    test('facturar con ${method.label} no exige ni genera Caja', () {
      final product = data.products.first;
      final stock = data.stockTotal;
      expect(data.addToCart(product), isTrue);
      expect(data.checkoutSale(method: method, tendered: 10), isNull);
      expect(data.sales.single.total, product.price);
      expect(
        data.sales.single.change,
        method == PaymentMethod.cash ? 10 - product.price : 0,
      );
      expect(data.stockTotal, stock - 1);
      expect(data.cart, isEmpty);
      expect(data.cashSessions, isEmpty);
      expect(data.cashMovements, isEmpty);
      expect(data.revenueToday, product.price);
    });
  }
  test('sin Caja no se omiten validaciones de efectivo y existencias', () {
    data.addToCart(data.products.first);
    final before = data.stockTotal;
    expect(
      data.checkoutSale(method: PaymentMethod.cash, tendered: 0),
      isNotNull,
    );
    expect(
      data.checkoutSale(method: PaymentMethod.cash, tendered: double.nan),
      isNotNull,
    );
    expect(data.sales, isEmpty);
    expect(data.stockTotal, before);
    expect(data.cart, hasLength(1));
  });
  test('anular una factura nueva devuelve stock sin movimiento de Caja', () {
    final before = data.stockTotal;
    data.addToCart(data.products.first);
    expect(data.checkoutSale(method: PaymentMethod.cash, tendered: 10), isNull);
    expect(data.cancelSale(data.sales.single.id, 'Prueba'), isNull);
    expect(data.stockTotal, before);
    expect(data.revenueToday, 0);
    expect(data.cashMovements, isEmpty);
    expect(data.cancelSale(data.sales.single.id, 'Duplicado'), isNotNull);
  });
  test('pago manual de compra no necesita Caja ni crea una salida', () {
    final product = data.products.first;
    expect(
      data.createPurchase('supplier-demo', [
        PurchaseLine(
          productId: product.id,
          productName: product.name,
          quantity: 12,
          unitCost: 3,
        ),
      ]),
      isNull,
    );
    final id = data.purchases.single.id;
    expect(
      data.receivePurchase(id, [
        LotReceipt(
          productId: product.id,
          code: 'SIN-CAJA',
          expiry: data.today.add(const Duration(days: 365)),
        ),
      ]),
      isNull,
    );
    expect(data.payPurchase(id, PaymentMethod.cash), isNull);
    expect(data.purchases.single.paymentMethod, 'Efectivo');
    expect(data.payPurchase(id, PaymentMethod.cash), isNotNull);
    expect(data.cashMovements, isEmpty);
    expect(data.openCash, isNull);
  });
  test('una caja antigua se conserva pero no recibe ventas nuevas', () {
    final previous = PharmacyController(cashEnabled: true);
    addTearDown(previous.dispose);
    previous.openCashSession(100);
    previous.addToCart(previous.products.first);
    previous.checkoutSale(method: PaymentMethod.cash, tendered: 10);
    expect(data.restoreBackup(previous.createBackup()), isNull);
    final oldBalance = data.expectedCash(data.openCash!);
    final oldMovements = data.cashMovements.length;
    data.addToCart(data.products.first);
    expect(data.checkoutSale(method: PaymentMethod.cash, tendered: 10), isNull);
    expect(data.cashMovements, hasLength(oldMovements));
    expect(data.expectedCash(data.openCash!), oldBalance);
    expect(data.closeCashSession(oldBalance), isNotNull);
    expect(data.openCash, isNotNull);
    final stock = data.stockTotal;
    expect(data.cancelSale(data.sales.first.id, 'Cobro anterior'), isNotNull);
    expect(data.stockTotal, stock);
    expect(data.sales.first.cancelled, isFalse);
    expect(data.cancelSale(data.sales.last.id, 'Cobro sin Caja'), isNull);
    expect(data.cashMovements, hasLength(oldMovements));
  });
  test('al reactivar Caja no se reembolsa un ingreso inexistente', () {
    data.addToCart(data.products.first);
    data.checkoutSale(method: PaymentMethod.cash, tendered: 10);
    final restored = PharmacyController(cashEnabled: true);
    addTearDown(restored.dispose);
    expect(restored.restoreBackup(data.createBackup()), isNull);
    expect(
      restored.cancelSale(restored.sales.single.id, 'Registrada sin Caja'),
      isNull,
    );
    expect(restored.cashMovements, isEmpty);
    expect(restored.openCash, isNull);
  });
  test('menú y destinos seguros no permiten acceder a Caja', () {
    expect(
      adminModules.expand((m) => m.items).any((i) => i.index == 11),
      isFalse,
    );
    expect(AppPaths.enabledSectionIndices, isNot(contains(11)));
    expect(AppPaths.safeDestination(AppPaths.cash), AppPaths.administration);
    expect(AppPaths.sections[11], AppPaths.cash);
  });
  for (final username in ['admin', 'usuario']) {
    test(
      'ruta de Caja deshabilitada para $username incluso con sesión',
      () async {
        final auth = AuthController();
        addTearDown(auth.dispose);
        await auth.signIn(username, '1234');
        final guard = AuthGuard(auth);
        expect(
          guard.redirect(Uri.parse(AppPaths.cash)),
          AppPaths.administration,
        );
        expect(
          guard.redirect(Uri.parse('${AppPaths.login}?desde=${AppPaths.cash}')),
          AppPaths.administration,
        );
        expect(guard.redirect(Uri.parse('/administracion/ventas')), isNull);
      },
    );
  }
  testWidgets('facturación cobra sin Caja y el enlace directo está bloqueado', (
    tester,
  ) async {
    final auth = AuthController();
    addTearDown(auth.dispose);
    final signingIn = auth.signIn('usuario', '1234');
    await tester.pump(const Duration(milliseconds: 450));
    await signingIn;
    final router = createAppRouter(
      auth: auth,
      pharmacyProvider: () => data,
      initialLocation: '/administracion/ventas',
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nueva factura'), findsWidgets);
    expect(find.byKey(const Key('breadcrumb-current')), findsOneWidget);
    expect(find.text('Ir a caja'), findsNothing);
    data.addToCart(data.products.first);
    await tester.pumpAndSettle();
    if (find.textContaining('Venta (').evaluate().isNotEmpty) {
      await tester.tap(find.textContaining('Venta ('));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Completar venta'));
    await tester.tap(find.text('Completar venta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('sale-tendered')), '10');
    await tester.ensureVisible(find.text('Registrar venta'));
    await tester.tap(find.text('Registrar venta'));
    await tester.pumpAndSettle();
    expect(data.sales, hasLength(1));
    expect(find.text(r'Recibido: C$ 10.00 · Cambio: C$ 6.50'), findsOneWidget);
    expect(data.cashSessions, isEmpty);
    expect(data.cashMovements, isEmpty);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    router.go(AppPaths.cash);
    await tester.pumpAndSettle();
    expect(find.byType(CashPage), findsNothing);
    expect(
      GoRouter.of(
        tester.element(find.byType(HomeScreen)),
      ).routeInformationProvider.value.uri.path,
      AppPaths.administration,
    );
    expect(tester.takeException(), isNull);
  });
}
