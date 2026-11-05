import 'package:flutter/material.dart';
import '../themes/app_palette.dart';

/// Navegación secundaria uniforme. Una línea desplazable evita que las pestañas
/// consuman varias filas en teléfonos; cada vista conserva un único propósito.
class WorkspaceTabs extends StatelessWidget {
  const WorkspaceTabs({
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.keyPrefix,
    super.key,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final String? keyPrefix;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: context.palette.border)),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Semantics(
              selected: selected == i,
              button: true,
              child: InkWell(
                key: keyPrefix == null ? null : Key('$keyPrefix-$i'),
                onTap: () => onSelected(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 2,
                        color: selected == i
                            ? context.palette.blue
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected == i
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected == i
                          ? context.palette.blue
                          : context.palette.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Indicadores de contexto en una franja, sin una tarjeta grande por cifra.
/// El ajuste natural mantiene legibles importes largos y texto ampliado.
class SummaryStrip extends StatelessWidget {
  const SummaryStrip({required this.values, super.key});
  final List<(String label, String value)> values;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 28,
    runSpacing: 12,
    children: [
      for (final value in values)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.$1,
              style: TextStyle(fontSize: 11, color: context.palette.muted),
            ),
            const SizedBox(height: 3),
            Text(
              value.$2,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
    ],
  );
}
