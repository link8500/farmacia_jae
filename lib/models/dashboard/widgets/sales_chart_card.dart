import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../purchases/models/purchase_order.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/chart_entrance.dart';

/// Comparación de compras y ventas inspirada en las barras dobles del Figma.
/// La información es de ejemplo; el selector actualiza ambas series locales.
class SalesChartCard extends StatefulWidget {
  const SalesChartCard({this.controller, super.key});
  final PharmacyController? controller;
  @override
  State<SalesChartCard> createState() => _SalesChartCardState();
}

class _SalesChartCardState extends State<SalesChartCard> {
  late int _year;
  @override
  void initState() {
    super.initState();
    _year = widget.controller?.now.year ?? DateTime.now().year;
  }

  static const _purchasesColor = Color(0xFF71C9E7);
  static const _salesColor = Color(0xFF53BF79);
  static const _months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
  List<double> get _purchases {
    final values = List<double>.filled(12, 0);
    for (final order in widget.controller?.purchases ?? []) {
      if (order.status == PurchaseStatus.received &&
          order.receivedAt!.year == _year) {
        values[order.receivedAt!.month - 1] += order.total;
      }
    }
    return values;
  }

  List<double> get _sales {
    final values = List<double>.filled(12, 0);
    for (final sale in widget.controller?.sales ?? []) {
      if (!sale.cancelled &&
          sale.branchId == widget.controller?.workingBranchId &&
          sale.createdAt.year == _year) {
        values[sale.createdAt.month - 1] += sale.total;
      }
    }
    return values;
  }

  double get _maximum {
    final largest = [
      ..._purchases,
      ..._sales,
    ].fold<double>(0, (a, b) => a > b ? a : b);
    return largest == 0 ? 100 : (largest * 1.2 / 100).ceil() * 100.0;
  }

  List<int> get _years => ({
    _year,
    (widget.controller?.now.year ?? DateTime.now().year),
    (widget.controller?.now.year ?? DateTime.now().year) - 1,
    ...?widget.controller?.sales.map((s) => s.createdAt.year),
    ...?widget.controller?.purchases.map((p) => p.createdAt.year),
  }.toList()..sort((a, b) => b.compareTo(a)));

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 20,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ventas y compras',
                  style: TextStyle(
                    color: context.palette.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Comparativo mensual · Registros locales',
                  style: TextStyle(color: context.palette.muted, fontSize: 10),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: context.palette.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _year,
                  isDense: true,
                  style: TextStyle(color: context.palette.ink, fontSize: 11),
                  items: [
                    for (final year in _years)
                      DropdownMenuItem(value: year, child: Text('$year')),
                  ],
                  onChanged: (year) {
                    if (year != null) setState(() => _year = year);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        LayoutBuilder(
          builder: (context, constraints) {
            // Las barras permanecen legibles en móvil. Se conserva todo el año y
            // se omiten etiquetas alternas, no datos, cuando hay poco espacio.
            final compact = constraints.maxWidth < 450;
            final purchases = _purchases, sales = _sales;
            return Semantics(
              label:
                  'Gráfico comparativo de compras y ventas mensuales de $_year, datos locales',
              child: SizedBox(
                height: 235,
                child: ChartEntrance(
                  revision: Object.hash(
                    _year,
                    Object.hashAll(purchases),
                    Object.hashAll(sales),
                  ),
                  builder: (context, progress) => BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: _maximum,
                      alignment: BarChartAlignment.spaceAround,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _maximum / 5,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: context.palette.border,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _maximum / 5,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(
                              value < 1000
                                  ? value.toStringAsFixed(0)
                                  : '${(value / 1000).toStringAsFixed(0)}k',
                              style: TextStyle(
                                color: context.palette.muted,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 ||
                                  index >= _months.length ||
                                  (compact && index.isOdd)) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                meta: meta,
                                space: 12,
                                child: Text(
                                  _months[index],
                                  style: TextStyle(
                                    color: context.palette.muted,
                                    fontSize: 9,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        enabled: progress >= 1,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.navy,
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                              BarTooltipItem(
                                '${rodIndex == 0 ? 'Compras' : 'Ventas'} · ${_months[group.x]}\n${formatCordobas(rod.toY)}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  height: 1.6,
                                ),
                              ),
                        ),
                      ),
                      barGroups: [
                        for (var index = 0; index < _months.length; index++)
                          BarChartGroupData(
                            x: index,
                            barsSpace: compact ? 2 : 4,
                            barRods: [
                              BarChartRodData(
                                toY:
                                    purchases[index] *
                                    ChartEntrance.factor(
                                      progress,
                                      index,
                                      _months.length,
                                    ),
                                width: compact ? 5 : 9,
                                color: _purchasesColor,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                              BarChartRodData(
                                toY:
                                    sales[index] *
                                    ChartEntrance.factor(
                                      progress,
                                      index,
                                      _months.length,
                                    ),
                                width: compact ? 5 : 9,
                                color: _salesColor,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    duration: Duration.zero,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(color: _purchasesColor, label: 'Compras'),
            SizedBox(width: 24),
            _Legend(color: _salesColor, label: 'Ventas'),
          ],
        ),
      ],
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 7),
      Text(label, style: TextStyle(color: context.palette.muted, fontSize: 10)),
    ],
  );
}
