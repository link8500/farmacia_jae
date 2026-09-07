import 'package:flutter/material.dart';

/// Contenedor visual para agrupar una sección de contenido.
///
/// Se usa en tablas, formularios, listas y paneles para mantener el mismo
/// espaciado y la misma superficie blanca en toda la aplicación.
class SectionCard extends StatelessWidget {
  /// Crea una tarjeta de sección con contenido arbitrario.
  const SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    super.key,
  });

  /// Contenido que se mostrará dentro de la tarjeta.
  final Widget child;

  /// Espaciado interior personalizable.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: padding, child: child),
    );
  }
}
