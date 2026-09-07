import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/main.dart';

/// Verifica que el dashboard principal arranque con sus elementos esenciales.
void main() {
  testWidgets('muestra el panel principal de Farmacia JAE', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FarmaciaApp());

    expect(find.text('Resumen general'), findsOneWidget);
    expect(find.text('Buenos días, equipo 👋'), findsOneWidget);
    expect(find.text('Gobernanza y continuidad'), findsOneWidget);
    expect(find.text('Control de inventario'), findsNothing);
  });

  /// Comprueba que el layout móvil pueda construirse sin overflow.
  testWidgets('adapta el dashboard a un viewport móvil', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const FarmaciaApp());

    expect(find.text('Resumen general'), findsOneWidget);
    expect(find.text('Buenos días, equipo 👋'), findsOneWidget);
  });
}
