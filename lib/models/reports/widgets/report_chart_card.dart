import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/chart_entrance.dart';
import '../models/report_visuals.dart';

/// Un único contenedor para títulos, unidades, leyendas, criterios y datos
/// accesibles. Todos los gráficos de datos se renderizan mediante fl_chart.
class ReportChartCard extends StatefulWidget {
  const ReportChartCard({required this.spec, this.compact = false, super.key});
  final ReportChartSpec spec;
  final bool compact;
  @override
  State<ReportChartCard> createState() => _ReportChartCardState();
}

class _ReportChartCardState extends State<ReportChartCard> {
  static const _colors = [
    Color(0xff2563eb),
    Color(0xff0f8b79),
    Color(0xffd97706),
    Color(0xffdc4260),
    Color(0xff7c3aed),
    Color(0xff0891b2),
  ];
  int _touched = -1;
  ReportChartSpec get spec => widget.spec;
  Object get _revision => Object.hash(
    spec.id,
    spec.type,
    Object.hashAll([
      for (final v in spec.values)
        Object.hash(v.key, v.label, v.value, v.reference),
    ]),
  );
  @override
  void didUpdateWidget(covariant ReportChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _touched = -1;
  }

  String _axis(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
  }

  double get _maximum {
    final top = spec.values.fold<double>(
      0,
      (n, v) => math.max(n, math.max(v.value, v.reference ?? 0)),
    );
    return top == 0
        ? 1
        : spec.currency
        ? top * 1.25
        : (top * 1.25).ceilToDouble();
  }

  double get _interval =>
      spec.currency ? _maximum / 4 : math.max(1, (_maximum / 4).ceilToDouble());

  FlTitlesData _titles({bool line = false}) => FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 48,
        interval: _interval,
        getTitlesWidget: (v, meta) => Text(
          _axis(v),
          style: TextStyle(color: context.palette.muted, fontSize: 10),
        ),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 36,
        interval: 1,
        getTitlesWidget: (v, meta) {
          final index = v.toInt();
          if (v != index.toDouble() ||
              index < 0 ||
              index >= spec.values.length) {
            return const SizedBox.shrink();
          }
          final marks = {
            for (var i = 0; i < 4; i++)
              ((spec.values.length - 1) * i / 3).round(),
          };
          if (line && !marks.contains(index)) {
            return const SizedBox.shrink();
          }
          final label = line
              ? spec.values[index].label
                    .replaceFirst('Semana ', 'S')
                    .split(' · ')
                    .first
              : '${index + 1}';
          final shortLabel = RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(label)
              ? label.substring(0, 5)
              : label;
          return SideTitleWidget(
            meta: meta,
            space: 10,
            child: Text(
              shortLabel,
              style: TextStyle(color: context.palette.muted, fontSize: 9),
            ),
          );
        },
      ),
    ),
  );
  FlGridData get _grid => FlGridData(
    drawVerticalLine: false,
    horizontalInterval: _interval,
    getDrawingHorizontalLine: (_) => FlLine(
      color: context.palette.border,
      strokeWidth: 1,
      dashArray: [4, 4],
    ),
  );
  Widget _bars(double progress) => BarChart(
    BarChartData(
      minY: 0,
      maxY: _maximum,
      gridData: _grid,
      titlesData: _titles(),
      borderData: FlBorderData(show: false),
      alignment: BarChartAlignment.spaceAround,
      barTouchData: BarTouchData(
        enabled: progress >= 1,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => AppColors.navy,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final value = spec.values[group.x];
            return BarTooltipItem(
              '${value.label}\n${rodIndex == 1 ? '${spec.referenceLabel}: ' : ''}${spec.format(rod.toY, unit: value.unit.isEmpty ? null : value.unit)}',
              const TextStyle(color: Colors.white, fontSize: 11),
            );
          },
        ),
      ),
      barGroups: [
        for (var i = 0; i < spec.values.length; i++)
          BarChartGroupData(
            x: i,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY:
                    spec.values[i].value *
                    ChartEntrance.factor(progress, i, spec.values.length),
                width: spec.referenceLabel == null ? 19 : 11,
                color: _colors[0],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              if (spec.values[i].reference != null)
                BarChartRodData(
                  toY:
                      spec.values[i].reference! *
                      ChartEntrance.factor(progress, i, spec.values.length),
                  width: 11,
                  color: _colors[2],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
            ],
          ),
      ],
    ),
    duration: Duration.zero,
  );

  // El eje conserva el rango final. La punta recorre las muestras e interpola
  // solo el segmento actual, evitando mostrar toda la línea desde el inicio.
  List<FlSpot> _lineSpots(double progress) {
    final position = progress * spec.values.length;
    if (position < 1) return [FlSpot(0, spec.values.first.value * position)];
    final last = math.min(spec.values.length - 1, position.floor() - 1);
    final result = [
      for (var i = 0; i <= last; i++)
        FlSpot(i.toDouble(), spec.values[i].value),
    ];
    final fraction = position - last - 1;
    if (last + 1 < spec.values.length && fraction > 0) {
      result.add(
        FlSpot(
          last + fraction,
          spec.values[last].value +
              (spec.values[last + 1].value - spec.values[last].value) *
                  fraction,
        ),
      );
    }
    return result;
  }

  Widget _line(double progress) => LineChart(
    LineChartData(
      minY: 0,
      maxY: _maximum,
      minX: 0,
      maxX: math.max(1, spec.values.length - 1).toDouble(),
      gridData: _grid,
      borderData: FlBorderData(show: false),
      titlesData: _titles(line: true),
      lineTouchData: LineTouchData(
        enabled: progress >= 1,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.navy,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (spots) => [
            for (final spot in spots)
              LineTooltipItem(
                '${spec.values[spot.x.toInt()].label}\n${spec.format(spot.y)}',
                const TextStyle(color: Colors.white, fontSize: 11),
              ),
          ],
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          isCurved: false,
          color: _colors[0],
          barWidth: 3,
          spots: _lineSpots(progress),
          dotData: FlDotData(show: spec.values.length < 16),
          belowBarData: BarAreaData(
            show: true,
            color: _colors[0].withValues(alpha: .09),
          ),
        ),
      ],
    ),
    duration: Duration.zero,
  );

  Widget _donut(double progress) {
    final values = spec.values.where((v) => v.value > 0).toList();
    return ClipPath(
      clipper: ChartSweepClipper(progress),
      child: PieChart(
        PieChartData(
          startDegreeOffset: 270,
          centerSpaceRadius: 44,
          sectionsSpace: 3,
          pieTouchData: PieTouchData(
            enabled: progress >= 1,
            touchCallback: (event, response) {
              final next = event.isInterestedForInteractions
                  ? response?.touchedSection?.touchedSectionIndex ?? -1
                  : -1;
              if (_touched != next) setState(() => _touched = next);
            },
          ),
          sections: [
            for (var i = 0; i < values.length; i++)
              PieChartSectionData(
                value: values[i].value,
                radius: _touched == i ? 66 : 60,
                color: _colors[spec.values.indexOf(values[i]) % _colors.length],
                title: values[i].value / spec.total >= .07
                    ? '${(values[i].value / spec.total * 100).toStringAsFixed(0)}%'
                    : '',
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          spec.title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          spec.description,
          style: TextStyle(
            color: context.palette.muted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          spec.currency ? 'Importes en C\$' : spec.unit,
          style: TextStyle(
            color: context.palette.blue,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          label: '${spec.title}. ${spec.explanation}',
          child: SizedBox(
            height: widget.compact ? 210 : 240,
            child: !spec.hasData
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.insights_outlined,
                        size: 36,
                        color: context.palette.muted,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Sin datos para este gráfico',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Registra operaciones o ajusta los filtros.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.palette.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                : ChartEntrance(
                    revision: _revision,
                    builder: (context, progress) => switch (spec.type) {
                      ReportChartType.line => _line(progress),
                      ReportChartType.bars => _bars(progress),
                      ReportChartType.donut => _donut(progress),
                    },
                  ),
          ),
        ),
        if (spec.type != ReportChartType.line && spec.values.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            initiallyExpanded: !widget.compact,
            title: const Text('Ver desglose', style: TextStyle(fontSize: 12)),
            children: [
              const SizedBox(height: 16),
              for (var i = 0; i < spec.values.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4, right: 8),
                        child: Icon(
                          Icons.circle,
                          size: 8,
                          color: spec.type == ReportChartType.bars
                              ? _colors[0]
                              : _colors[i % _colors.length],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${spec.type == ReportChartType.bars ? '${i + 1}. ' : ''}${spec.values[i].label}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          spec.format(
                            spec.values[i].value,
                            unit: spec.values[i].unit.isEmpty
                                ? null
                                : spec.values[i].unit,
                          ),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (spec.referenceLabel != null)
                Text(
                  'Azul: disponible · Naranja: ${spec.referenceLabel}',
                  style: TextStyle(color: context.palette.muted, fontSize: 11),
                ),
            ],
          ),
        if (widget.compact)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(
              'Cómo leerlo',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  spec.explanation,
                  style: TextStyle(
                    color: context.palette.muted,
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          )
        else ...[
          const Divider(height: 28),
          const Text(
            'Cómo leerlo',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            spec.explanation,
            style: TextStyle(
              color: context.palette.muted,
              height: 1.55,
              fontSize: 12,
            ),
          ),
        ],
        if (spec.type == ReportChartType.line && spec.hasData)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(
              'Ver valores por intervalo',
              style: TextStyle(fontSize: 12),
            ),
            children: [
              for (final value in spec.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          value.label,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          spec.format(value.value),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    ),
  );
}
