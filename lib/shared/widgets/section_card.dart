import 'package:flutter/material.dart';
import 'package:forui/forui.dart' show FCard, FCardStyle;

import '../themes/app_palette.dart';

/// Contenedor visual para agrupar una sección de contenido.
///
/// Se usa en tablas, formularios, listas y paneles para mantener el mismo
/// espaciado y la misma superficie blanca en toda la aplicación.
class SectionCard extends StatelessWidget {
  /// Crea una tarjeta de sección con contenido arbitrario.
  const SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 12,
    super.key,
  });

  /// Contenido que se mostrará dentro de la tarjeta.
  final Widget child;

  /// Espaciado interior personalizable.
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return FCard(
      clipBehavior: Clip.antiAlias,
      style: FCardStyle(
        decoration: ShapeDecoration(
          color: palette.surface,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(color: palette.border),
          ),
        ),
        titleTextStyle: theme.textTheme.titleMedium!,
        subtitleTextStyle: theme.textTheme.bodySmall!,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
