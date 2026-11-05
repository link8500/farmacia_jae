import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';
import '../themes/app_palette.dart';

/// Cabecera reutilizable para las pantallas internas del sistema.
class PageHeader extends StatelessWidget {
  /// Crea una cabecera con título, descripción y acción opcional.
  const PageHeader({
    required this.title,
    required this.description,
    this.action,
    super.key,
  });

  /// Título principal de la pantalla.
  final String title;

  /// Texto que explica el objetivo de la pantalla.
  final String description;

  /// Botón o control opcional que aparece a la derecha.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // El botón pasa debajo del título cuando el espacio horizontal ya
        // no permite mantener una cabecera cómoda en una sola fila.
        final compact =
            isCompactWidth(constraints.maxWidth) ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: context.palette.ink,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(color: context.palette.muted, fontSize: 13),
            ),
          ],
        );
        final compactAction = action == null
            ? null
            : <Widget>[const SizedBox(height: 14), action!];
        // La fila entrega ancho ilimitado a hijos no flexibles. Acotar las
        // acciones permite que sus Wrap formen otra línea, también en tabletas
        // o al añadir comandos a una ficha, sin expulsar el título de la vista.
        final wideAction = action == null
            ? null
            : <Widget>[
                const SizedBox(width: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * .64,
                  ),
                  child: action!,
                ),
              ];

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [content, ...?compactAction],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: content),
            ...?wideAction,
          ],
        );
      },
    );
  }
}
