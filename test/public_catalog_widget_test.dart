import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/core/routing/app_paths.dart';
import 'package:farmacia_sae/core/routing/app_router.dart';
import 'package:farmacia_sae/core/services/auth_controller.dart';
import 'package:farmacia_sae/models/presentation/views/contact_page.dart';
import 'package:farmacia_sae/shared/themes/app_theme.dart';

void main() {
  for (final width in [320.0, 1440.0]) {
    testWidgets(
      'catálogo editorial busca, filtra y abre información sin datos privados a $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final auth = AuthController();
        addTearDown(auth.dispose);
        var reads = 0;
        final router = createAppRouter(
          auth: auth,
          initialLocation: AppPaths.presentationServices,
          pharmacyProvider: () {
            reads++;
            throw StateError('Datos privados');
          },
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
        );
        await tester.pumpAndSettle();
        final search = find.byKey(const Key('public-product-search'));
        await tester.enterText(search, '500 mg');
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('public-article-paracetamol')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('public-article-amoxicilina')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('public-article-losartan')), findsNothing);
        await tester.ensureVisible(
          find.byKey(const Key('public-article-paracetamol')),
        );
        await tester.tap(find.byKey(const Key('public-article-paracetamol')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Componente: Paracetamol'), findsOneWidget);
        await tester.tap(find.text('Consultar en farmacia'));
        await tester.pumpAndSettle();
        expect(find.byType(ContactPage), findsOneWidget);
        expect(find.text('Iniciar sesión'), findsNothing);
        router.go(AppPaths.presentation);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Primeros auxilios'));
        await tester.tap(find.text('Primeros auxilios'));
        await tester.pumpAndSettle();
        expect(
          router
              .routeInformationProvider
              .value
              .uri
              .queryParameters['categoria'],
          'Primeros auxilios',
        );
        expect(find.byKey(const Key('public-article-alcohol')), findsOneWidget);
        expect(
          find.byKey(const Key('public-article-paracetamol')),
          findsNothing,
        );
        expect(reads, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
