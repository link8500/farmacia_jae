import 'package:flutter/material.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/section_card.dart';

/// Grupo de preferencias o controles de configuración.
class SettingGroup extends StatelessWidget {
  /// Crea un grupo con título y filas configurables.
  const SettingGroup({required this.title, required this.rows, super.key});

  final String title;
  final List<String> rows;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.palette.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map(
            (row) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                row,
                style: TextStyle(color: context.palette.muted, fontSize: 12),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: context.palette.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
