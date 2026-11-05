import 'package:flutter/material.dart';
import '../themes/app_palette.dart';
import 'adaptive_grid.dart';
import 'administration_page.dart';
import 'section_card.dart';

/// Detalle común con imagen opcional y campos de lectura. En escritorio la
/// imagen acompaña los datos; en móvil se apila sin aumentar el tamaño de fichas.
class RecordDetail extends StatelessWidget {
  const RecordDetail({
    required this.title,
    required this.onBack,
    required this.fields,
    this.subtitle = '',
    this.backLabel = 'Volver al listado',
    this.media,
    this.navigation,
    this.actions = const [],
    this.children = const [],
    super.key,
  });
  final String title, subtitle;
  final String backLabel;
  final VoidCallback onBack;
  final List<(String, String)> fields;
  final List<Widget> actions, children;
  final Widget? media, navigation;
  @override
  Widget build(BuildContext context) => AdministrationPage(
    title: title,
    description: subtitle,
    action: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, size: 17),
          label: Text(backLabel),
        ),
        ...actions,
      ],
    ),
    children: [
      ?navigation,
      SectionCard(
        child: LayoutBuilder(
          builder: (context, box) {
            final info = AdaptiveGrid(
              minItemWidth: 220,
              children: [
                for (final field in fields)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.$1,
                        style: TextStyle(
                          color: context.palette.muted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SelectableText(
                        field.$2.isEmpty ? 'Sin registrar' : field.$2,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            );
            if (media == null) return info;
            final picture = SizedBox(
              width: 156,
              child: Align(alignment: Alignment.topLeft, child: media),
            );
            if (box.maxWidth >= 620 &&
                MediaQuery.textScalerOf(context).scale(1) <= 1.3) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  picture,
                  const SizedBox(width: 24),
                  Expanded(child: info),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [picture, const SizedBox(height: 18), info],
            );
          },
        ),
      ),
      ...children,
    ],
  );
}
