import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmacia_sae/models/reports/models/report_visuals.dart';
import 'package:farmacia_sae/models/reports/widgets/report_chart_card.dart';
import 'package:farmacia_sae/shared/themes/app_theme.dart';
import 'package:farmacia_sae/shared/widgets/chart_entrance.dart';

void main() {
  const values = [
    ChartValue('a', 'Uno', 5),
    ChartValue('b', 'Dos', 8),
    ChartValue('c', 'Tres', 12),
  ];
  ReportChartSpec spec(ReportChartType type) => ReportChartSpec(
    id: 'animation',
    title: 'Animación',
    description: 'Prueba',
    explanation: 'Valores finales',
    type: type,
    values: values,
  );
  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    bool reduced = false,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  List<double> bars(WidgetTester tester) => tester
      .widget<BarChart>(find.byType(BarChart))
      .data
      .barGroups
      .map((g) => g.barRods.first.toY)
      .toList();
  testWidgets(
    'barras empiezan en cero y recorren datos de izquierda a derecha',
    (tester) async {
      await mount(tester, ReportChartCard(spec: spec(ReportChartType.bars)));
      expect(bars(tester), [0, 0, 0]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final intermediate = bars(tester);
      expect(intermediate.first, greaterThan(0));
      expect(intermediate.last, 0);
      await tester.pumpAndSettle();
      expect(bars(tester), [5, 8, 12]);
      // El mismo contenido reconstruido no reinicia la animación.
      await mount(tester, ReportChartCard(spec: spec(ReportChartType.bars)));
      expect(bars(tester), [5, 8, 12]);
    },
  );
  testWidgets('línea parte de cero y solo revela el tramo recorrido', (
    tester,
  ) async {
    await mount(tester, ReportChartCard(spec: spec(ReportChartType.line)));
    List<FlSpot> spots() => tester
        .widget<LineChart>(find.byType(LineChart))
        .data
        .lineBarsData
        .single
        .spots;
    expect(spots(), [const FlSpot(0, 0)]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(spots().last.x, lessThan(2));
    expect(spots().first.y, 5);
    await tester.pumpAndSettle();
    expect(spots(), [
      const FlSpot(0, 5),
      const FlSpot(1, 8),
      const FlSpot(2, 12),
    ]);
  });
  testWidgets(
    'gráficos fuera de pantalla esperan hasta entrar en el área visible',
    (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: scroll,
              child: Column(
                children: [
                  const SizedBox(height: 1200),
                  SizedBox(
                    height: 200,
                    child: ChartEntrance(
                      revision: 1,
                      builder: (_, p) => Text('Progreso $p'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Progreso 0.0'), findsOneWidget);
      scroll.jumpTo(1100);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Progreso 1.0'), findsOneWidget);
    },
  );
  testWidgets('reducir movimiento muestra valores finales sin animación', (
    tester,
  ) async {
    await mount(
      tester,
      ReportChartCard(spec: spec(ReportChartType.bars)),
      reduced: true,
    );
    expect(bars(tester), [5, 8, 12]);
  });
  testWidgets('circular se revela sin alterar proporciones de los datos', (
    tester,
  ) async {
    await mount(tester, ReportChartCard(spec: spec(ReportChartType.donut)));
    ChartSweepClipper clip() => tester
        .widgetList<ClipPath>(find.byType(ClipPath))
        .map((w) => w.clipper)
        .whereType<ChartSweepClipper>()
        .single;
    expect(clip().progress, 0);
    expect(
      tester
          .widget<PieChart>(find.byType(PieChart))
          .data
          .sections
          .map((s) => s.value),
      [5, 8, 12],
    );
    await tester.pumpAndSettle();
    expect(clip().progress, 1);
  });
}
