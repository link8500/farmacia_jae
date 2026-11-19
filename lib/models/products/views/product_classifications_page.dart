import 'package:flutter/material.dart';

import '../../../core/services/pharmacy_controller.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../../../shared/widgets/record_form_dialog.dart';
import '../../../shared/widgets/workspace_sections.dart';
import '../models/product_classification.dart';

class ProductClassificationsPage extends StatefulWidget {
  const ProductClassificationsPage({
    required this.controller,
    required this.onBack,
    super.key,
  });

  final PharmacyController controller;
  final VoidCallback onBack;

  @override
  State<ProductClassificationsPage> createState() =>
      _ProductClassificationsPageState();
}

class _ProductClassificationsPageState
    extends State<ProductClassificationsPage> {
  ProductClassification _type = ProductClassification.category;

  void _edit([String? name]) {
    final type = _type;
    final label = type.label.toLowerCase();
    showDialog<bool>(
      context: context,
      builder: (_) => RecordFormDialog(
        title: '${name == null ? 'Agregar' : 'Editar'} $label',
        description: name == null
            ? 'Quedará disponible en las fichas de producto de todas las sucursales.'
            : 'El nuevo nombre se aplicará también a los productos que usan esta opción.',
        fields: [
          RecordField(
            'classification-name',
            'Nombre de la $label',
            initial: name ?? '',
          ),
        ],
        onSave: (values) => widget.controller.saveClassificationOption(
          type,
          values['classification-name']!,
          previous: name,
        ),
      ),
    );
  }

  void _delete(String name) {
    final type = _type;
    confirmCommand(
      context,
      '¿Eliminar «$name»?',
      'La opción se retirará del catálogo si ningún producto la utiliza.',
      () => widget.controller.deleteClassificationOption(type, name),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final options = widget.controller.classificationOptions(_type);
      return CompactWorkspace(
        title: 'Categorías y presentaciones',
        subtitle:
            'Agrega, edita o elimina las opciones de las fichas de producto.',
        actions: [
          OutlinedButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back, size: 17),
            label: const Text('Volver a productos'),
          ),
          FilledButton.icon(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add, size: 18),
            label: Text('Agregar ${_type.label.toLowerCase()}'),
          ),
        ],
        toolbar: WorkspaceTabs(
          labels: [
            for (final type in ProductClassification.values) type.plural,
          ],
          selected: _type.index,
          onSelected: (index) =>
              setState(() => _type = ProductClassification.values[index]),
        ),
        child: CompactRecords(
          resetKey: _type,
          itemCount: options.length,
          columns: const [
            RecordColumn('Nombre', flex: 3),
            RecordColumn('Origen'),
            RecordColumn('Acciones'),
          ],
          rowBuilder: (index) {
            final name = options[index];
            final source = _type.defaults.contains(name)
                ? 'Preestablecido'
                : 'Personalizado';
            final actions = RecordActions(
              recordKey: 'classification-actions-$name',
              actions: [
                ('Editar', () => _edit(name)),
                ('Eliminar', () => _delete(name)),
              ],
            );
            return RecordRow(
              cells: [
                RecordText(name, bold: true),
                RecordText(source),
                actions,
              ],
              mobile: RecordTile(
                title: name,
                subtitle: source,
                trailing: actions,
              ),
            );
          },
        ),
      );
    },
  );
}
