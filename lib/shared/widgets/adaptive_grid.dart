import 'package:flutter/material.dart';

/// Distribuye componentes por el espacio real disponible, sin anchos fijos
/// ni alturas que recorten contenido al aumentar el tamaño del texto.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    required this.children,
    this.minItemWidth = 280,
    this.maxColumns = 3,
    this.gap = 16,
    super.key,
  });
  final List<Widget> children;
  final double minItemWidth, gap;
  final int maxColumns;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = ((box.maxWidth + gap) / (minItemWidth + gap))
          .floor()
          .clamp(1, maxColumns);
      final width = (box.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}
