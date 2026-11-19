import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/utils/local_image_data.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/draft_photo_actions.dart';
import '../../../shared/widgets/form_dialog.dart';
import '../../../shared/widgets/workspace_sections.dart';
import '../models/product.dart';
import '../models/product_classification.dart';
import '../models/product_illustration.dart';
import 'product_thumbnail.dart';

/// Registro de la ficha maestra. Intencionalmente NO pide cantidad o caducidad.
class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({required this.controller, this.product, super.key});
  final PharmacyController controller;
  final Product? product;

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{
    for (final name in [
      'code',
      'name',
      'ingredient',
      'unit',
      'barcode',
      'dosage',
      'measure',
      'description',
      'contraindications',
      'packageUnits',
      'minimum',
    ])
      name: TextEditingController(),
  };
  String? _error;
  String? _category, _presentation;
  int _section = 0;
  bool _prescription = false;
  bool _editingPhoto = false;
  bool _saving = false;
  String? _savedId;
  String _illustrationKey = '', _photo = '';

  @override
  void initState() {
    super.initState();
    _fields['minimum']!.text = '0';
    _fields['packageUnits']!.text = '1';
    final p = widget.product;
    if (p != null) {
      _category = p.category;
      _presentation = p.presentation;
      _prescription = p.requiresPrescription;
      _photo = p.photoData;
      _illustrationKey =
          ProductIllustrations.find(p.illustrationKey)?.key ?? '';
      final values = {
        'code': p.code,
        'name': p.name,
        'ingredient': p.activeIngredient,
        'unit': p.unit,
        'barcode': p.barcode,
        'dosage': p.dosage,
        'measure': p.measurementUnit,
        'description': p.description,
        'contraindications': p.contraindications,
        'packageUnits': '${p.packageUnits}',
        'minimum': '${p.minimum}',
      };
      for (final entry in values.entries) {
        _fields[entry.key]!.text = entry.value;
      }
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Widget _field(
    String id,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboard,
    String? hint,
    String? help,
    int lines = 1,
  }) => TextFormField(
    key: Key('product-$id'),
    controller: _fields[id],
    validator: validator ?? requiredText,
    keyboardType: keyboard,
    maxLines: lines,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: help,
      helperMaxLines: 2,
    ),
  );

  /// Conserva el valor de una ficha anterior al catálogo de opciones.
  Widget _choice(
    ProductClassification type,
    String? value,
    String? previous,
    ValueChanged<String?> onChanged, {
    String? help,
  }) => DropdownButtonFormField<String>(
    key: Key('product-${type.name}'),
    initialValue: value,
    isExpanded: true,
    menuMaxHeight: 320,
    decoration: InputDecoration(
      labelText: type.label,
      helperText: help,
      helperMaxLines: 2,
    ),
    items: [
      for (final option in {
        ...widget.controller.classificationOptions(type),
        ?previous,
      })
        DropdownMenuItem(
          value: option,
          child: Text(option, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: onChanged,
    validator: requiredText,
  );

  Future<void> _save() async {
    if (_editingPhoto || _saving) return;
    final invalid = _form.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      final needsMeasure =
          invalid.length == 1 &&
          invalid.single.widget.key == const Key('product-measure');
      setState(() => _section = needsMeasure ? 1 : 0);
      return;
    }
    final error = widget.controller.registerProduct(
      id: _savedId ?? widget.product?.id,
      code: _fields['code']!.text,
      name: _fields['name']!.text,
      category: _category!,
      activeIngredient: _fields['ingredient']!.text,
      presentation: _presentation!,
      unit: _fields['unit']!.text,
      barcode: _fields['barcode']!.text,
      dosage: _fields['dosage']!.text,
      measurementUnit: _fields['measure']!.text,
      description: _fields['description']!.text,
      contraindications: _fields['contraindications']!.text,
      requiresPrescription: _prescription,
      packageUnits: int.parse(_fields['packageUnits']!.text.trim()),
      minimum: int.parse(_fields['minimum']!.text.trim()),
      illustrationKey: _illustrationKey,
      photoData: _photo,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    // Una escritura rechazada puede reintentarse desde esta ficha sin
    // duplicar el producto que ya se registró en la sesión.
    final code = _fields['code']!.text.trim().toUpperCase();
    _savedId ??=
        widget.product?.id ??
        widget.controller.products.firstWhere((p) => p.code == code).id;
    setState(() {
      _saving = true;
      _error = null;
    });
    await widget.controller.flush();
    if (!mounted) return;
    final storageError = widget.controller.storageError;
    if (storageError != null) {
      setState(() {
        _saving = false;
        _error = storageError;
      });
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: FormDialog(
      canClose: !_saving,
      title: widget.product == null ? 'Registrar producto' : 'Editar producto',
      description:
          'Define el medicamento y cómo se vende. Los proveedores se vinculan desde la ficha y los lotes se incorporan al recibir compras.',
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('product-save'),
          onPressed: _editingPhoto || _saving ? null : _save,
          child: Text(_saving ? 'Guardando…' : 'Guardar ficha'),
        ),
      ],
      child: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WorkspaceTabs(
                labels: const [
                  'Ficha comercial',
                  'Información del producto',
                  'Imagen',
                ],
                selected: _section,
                keyPrefix: 'product-tab',
                onSelected: (i) => setState(() => _section = i),
              ),
              const SizedBox(height: 20),
              Offstage(
                offstage: _section != 0,
                child: FormFieldsGrid(
                  fields: [
                    _field('code', 'Código del producto'),
                    _field('name', 'Nombre comercial / genérico'),
                    _choice(
                      ProductClassification.category,
                      _category,
                      widget.product?.category,
                      (value) => _category = value,
                    ),
                    _field(
                      'ingredient',
                      'Principio activo (opcional)',
                      validator: (_) => null,
                    ),
                    _choice(
                      ProductClassification.presentation,
                      _presentation,
                      widget.product?.presentation,
                      (value) => _presentation = value,
                      help:
                          'Forma del producto, por ejemplo tabletas, jarabe o crema.',
                    ),
                    _field(
                      'unit',
                      'Unidad de venta',
                      hint: 'Tableta, caja, frasco…',
                      help: 'Es lo que se cuenta en inventario y se cobra.',
                    ),
                    _field(
                      'packageUnits',
                      'Unidades de venta por envase',
                      help:
                          'Ejemplo: 10 si vendes por tableta, 1 si vendes la caja completa.',
                      validator: positiveInteger,
                      keyboard: TextInputType.number,
                    ),
                    _field(
                      'minimum',
                      'Mínimo para reposición',
                      validator: nonNegativeInteger,
                      keyboard: TextInputType.number,
                    ),
                    _field(
                      'barcode',
                      'Código de barras (opcional)',
                      validator: (_) => null,
                    ),
                  ],
                ),
              ),
              Offstage(
                offstage: _section != 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormFieldsGrid(
                      fields: [
                        _field(
                          'dosage',
                          'Concentración declarada',
                          hint: '500 mg o 250 mg / 5 ml',
                          validator: (_) => null,
                        ),
                        _field(
                          'measure',
                          'Unidad de medida',
                          hint: 'mg, ml, g…',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _field(
                      'description',
                      'Descripción y características',
                      validator: (_) => null,
                      lines: 2,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      'contraindications',
                      'Contraindicaciones / advertencias',
                      validator: (_) => null,
                      lines: 2,
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Venta bajo receta'),
                      subtitle: const Text(
                        'Clasificación para la dispensación del producto.',
                      ),
                      value: _prescription,
                      onChanged: (v) => setState(() => _prescription = v),
                    ),
                  ],
                ),
              ),
              Offstage(
                offstage: _section != 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DraftPhotoActions(
                      id: 'product-photo',
                      kind: LocalImageKind.product,
                      photo: _photo,
                      hasAsset: _illustrationKey.isNotEmpty,
                      onBusyChanged: (busy) =>
                          setState(() => _editingPhoto = busy),
                      onChanged: (photo) => setState(() {
                        _photo = photo;
                        _illustrationKey = '';
                      }),
                    ),
                    if (_illustrationKey.isNotEmpty || _photo.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Center(
                        child: ProductThumbnail(
                          illustrationKey: _illustrationKey,
                          photoData: _photo,
                          width: 180,
                          height: 130,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_section == 0) ...[
                const SizedBox(height: 18),
                Text(
                  widget.product == null || widget.product!.price == 0
                      ? 'Precio pendiente: se define después de la recepción del lote.'
                      : 'El precio unitario se administra desde el detalle y la recepción de lotes.',
                  style: TextStyle(color: context.palette.muted, fontSize: 12),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.red),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}
