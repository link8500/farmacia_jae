import 'package:flutter/material.dart';
import '../themes/app_palette.dart';

/// Formulario con jerarquía común: cabecera, campos y acciones al pie. En una
/// ventana baja o con teclado, el conjunto se desplaza para conservar el acceso.
class FormDialog extends StatelessWidget {
  const FormDialog({
    required this.title,
    required this.description,
    required this.child,
    this.actions = const [],
    this.maxWidth = 640,
    this.canClose = true,
    super.key,
  });
  final String title, description;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;
  final bool canClose;

  @override
  Widget build(BuildContext context) {
    final height =
        (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom -
                40)
            .clamp(120.0, 900.0);
    final pinActions =
        height >= (MediaQuery.textScalerOf(context).scale(1) > 1.4 ? 600 : 420);
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: context.palette.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Cerrar ventana',
            onPressed: canClose ? () => Navigator.maybePop(context) : null,
            icon: const Icon(Icons.close, size: 19),
          ),
        ],
      ),
    );
    final body = Padding(padding: const EdgeInsets.all(20), child: child);
    final footer = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 10,
        runSpacing: 8,
        children: actions,
      ),
    );
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const Divider(height: 1),
        if (pinActions)
          Flexible(child: SingleChildScrollView(child: body))
        else
          body,
        if (actions.isNotEmpty) ...[const Divider(height: 1), footer],
      ],
    );
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.palette.border),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: height),
        child: pinActions ? content : SingleChildScrollView(child: content),
      ),
    );
  }
}

/// Los campos pasan de dos columnas a una según el ancho REAL del diálogo.
class FormFieldsGrid extends StatelessWidget {
  const FormFieldsGrid({required this.fields, super.key});
  final List<Widget> fields;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width =
          constraints.maxWidth < 480 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3
          ? constraints.maxWidth
          : (constraints.maxWidth - 16) / 2;
      return Wrap(
        spacing: 16,
        runSpacing: 18,
        children: [
          for (final field in fields) SizedBox(width: width, child: field),
        ],
      );
    },
  );
}
