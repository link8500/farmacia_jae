import 'package:flutter/material.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/section_card.dart';

/// Tarjeta descriptiva para un reporte disponible.
class ReportCard extends StatelessWidget {
  /// Crea una tarjeta de reporte.
  const ReportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 245,
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: context.palette.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              style: TextStyle(
                color: context.palette.muted,
                fontSize: 11,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              'Ver reporte  →',
              style: TextStyle(
                color: context.palette.blue,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
