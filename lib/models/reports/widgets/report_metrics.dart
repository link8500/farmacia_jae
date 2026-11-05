import 'package:flutter/material.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/adaptive_grid.dart';
import '../../../shared/widgets/section_card.dart';
import '../models/report_visuals.dart';

class ReportMetrics extends StatelessWidget {
  const ReportMetrics({required this.values, this.compact = false, super.key});
  final List<ReportMetric> values;
  final bool compact;
  @override
  Widget build(BuildContext context) => AdaptiveGrid(
    minItemWidth: compact ? 130 : 190,
    maxColumns: 5,
    gap: 12,
    children: [
      for (final metric in values)
        if (compact)
          Tooltip(
            message: metric.explanation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.palette.surface,
                border: Border.all(color: context.palette.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.label,
                    style: TextStyle(
                      color: context.palette.muted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      metric.value,
                      style: TextStyle(
                        fontSize: 21,
                        color: context.palette.blue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SectionCard(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 112),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.label,
                    style: TextStyle(
                      color: context.palette.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      metric.value,
                      style: TextStyle(
                        color: context.palette.blue,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    metric.explanation,
                    style: TextStyle(
                      color: context.palette.muted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
    ],
  );
}
