import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/form_validators.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/form_dialog.dart';
import '../../../shared/widgets/workspace_sections.dart';
import '../models/product.dart';
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
      'category',
      'ingredient',
      'presentation',
      'unit',
      'barcode',
      'dosage',
      'measure',
      'origin',
      'manufacturer',
      'description',
      'indications',
      'contraindications',
      'packageUnits',
      'minimum',
    ])
      name: TextEditingController(),
  };
  String? _error;
  int _section = 0;
  bool _prescription = false;
  String _illustrationKey = '';

  @override
  void initState() {
    super.initState();
    _fields['minimum']!.text = '0';
    _fields['packageUnits']!.text = '1';
    final p = widget.product;
    if (p != null) {
      _prescription = p.requiresPrescription;
      _illustrationKey =
          ProductIllustrations.find(p.illustrationKey)?.key ?? '';
      final values = {
        'code': p.code,
        'name': p.name,
        'category': p.category,
        'ingredient': p.activeIngredient,
        'presentation': p.presentation,
        'unit': p.unit,
        'barcode': p.barcode,
        'dosage': p.dosage,
        'measure': p.measurementUnit,
        'origin': p.origin,
        'manufacturer': p.manufacturer,
        'description': p.description,
        'indications': p.indications,
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
    int lines = 1,
  }) => TextFormField(
    key: Key('product-$id'),
    controller: _fields[id],
    validator: validator ?? requiredText,
    keyboardType: keyboard,
    maxLines: lines,
    decoration: InputDecoration(labelText: label),
  );

  void _save() {
    if (!_form.currentState!.validate()) {
      setState(() => _section = 0);
      return;
    }
    final error = widget.controller.registerProduct(
      id: widget.product?.id,
      code: _fields['code']!.text,
      name: _fields['name']!.text,
      category: _fields['category']!.text,
      activeIngredient: _fields['ingredient']!.text,
      presentation: _fields['presentation']!.text,
      unit: _fields['unit']!.text,
      barcode: _fields['barcode']!.text,
      dosage: _fields['dosage']!.text,
      measurementUnit: _fields['measure']!.text,
      origin: _fields['origin']!.text,
      manufacturer: _fields['manufacturer']!.text,
      description: _fields['description']!.text,
      indications: _fields['indications']!.text,
      contraindications: _fields['contraindications']!.text,
      requiresPrescription: _prescription,
      packageUnits: int.parse(_fields['packageUnits']!.text.trim()),
      minimum: int.parse(_fields['minimum']!.text.trim()),
      illustrationKey: _illustrationKey,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => FormDialog(
    title: widget.product == null ? 'Registrar producto' : 'Editar producto',
    description:
        'Ficha maestra del catálogo. Recibe sus lotes y define el precio unitario en una operación posterior.',
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const Key('product-save'),
        onPressed: _save,
        child: const Text('Guardar ficha'),
      ),
    ],
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
                _field('category', 'Categoría'),
                _field(
                  'ingredient',
                  'Principio activo (opcional)',
                  validator: (_) => null,
                ),
                _field('presentation', 'Presentación: caja de 10, frasco…'),
                _field('unit', 'Unidad mínima de venta: tableta, frasco…'),
                _field('measure', 'Unidad de medida: mg, ml, g…'),
                _field('origin', 'País de origen'),
                _field('manufacturer', 'Laboratorio / fabricante'),
                _field(
                  'packageUnits',
                  'Unidades de venta por envase',
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
                _field(
                  'dosage',
                  'Concentración / dosis declarada (ej. 500 mg)',
                  validator: (_) => null,
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
                  'indications',
                  'Indicaciones del fabricante',
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
                // La selección es explícita y se guarda con la ficha; no cambia los
                // datos médicos ni crea lotes o existencias para el producto.
                DropdownButtonFormField<String>(
                  key: const Key('product-illustration'),
                  initialValue: _illustrationKey,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Imagen del producto (opcional)',
                    prefixIcon: Icon(Icons.photo_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Sin imagen'),
                    ),
                    for (final image in ProductIllustrations.values)
                      DropdownMenuItem(
                        value: image.key,
                        child: Text(
                          image.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _illustrationKey = value ?? ''),
                ),
                if (_illustrationKey.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: ProductThumbnail(
                      illustrationKey: _illustrationKey,
                      width: 180,
                      height: 130,
                      showCaption: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.product == null || widget.product!.price == 0
                ? 'Precio pendiente: se define después de la recepción del lote.'
                : 'El precio unitario se administra desde el detalle y la recepción de lotes.',
            style: TextStyle(color: context.palette.muted, fontSize: 12),
          ),
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
  );
}
