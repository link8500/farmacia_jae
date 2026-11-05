import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/form_validators.dart';
import '../../../shared/widgets/form_dialog.dart';
import '../../contacts/models/contact.dart';

/// Registra una recepción física con el código impreso por el fabricante.
/// Las fechas se transcriben del envase; el código no tiene un formato universal.
class LotFormDialog extends StatefulWidget {
  const LotFormDialog({required this.controller, this.productId, super.key});
  final PharmacyController controller;
  final String? productId;
  @override
  State<LotFormDialog> createState() => _LotFormDialogState();
}

class _LotFormDialogState extends State<LotFormDialog> {
  final _form = GlobalKey<FormState>();
  final _text = {
    for (final k in [
      'code',
      'quantity',
      'manufactured',
      'expiry',
      'location',
      'cost',
      'price',
    ])
      k: TextEditingController(),
  };
  String? _productId, _supplierId, _error;
  bool _packages = false;
  @override
  void initState() {
    super.initState();
    _text['cost']!.text = '0';
    if (widget.controller.products.any(
      (p) => p.id == widget.productId && p.active,
    )) {
      _productId = widget.productId;
    }
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(
    String key,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboard,
  }) => TextFormField(
    key: Key('lot-$key'),
    controller: _text[key],
    validator: validator ?? requiredText,
    keyboardType: keyboard,
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: key == 'manufactured' || key == 'expiry'
          ? IconButton(
              tooltip: 'Elegir fecha',
              onPressed: () => _pickDate(key),
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
            )
          : null,
    ),
  );

  Future<void> _pickDate(String key) async {
    final today = widget.controller.today;
    final first = key == 'manufactured' ? DateTime(1900) : today;
    final last = key == 'manufactured'
        ? today
        : DateTime(today.year + 50, 12, 31);
    var initial = parseCalendarDate(_text[key]!.text) ?? today;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (date != null && mounted) {
      _text[key]!.text = date.toIso8601String().substring(0, 10);
    }
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final product = widget.controller.productById(_productId!)!;
    final amount =
        int.parse(_text['quantity']!.text.trim()) *
        (_packages ? product.packageUnits : 1);
    final error = widget.controller.receiveLot(
      productId: product.id,
      code: _text['code']!.text,
      quantity: amount,
      supplierId: _supplierId!,
      manufacturedAt: parseCalendarDate(_text['manufactured']!.text)!,
      expiry: parseCalendarDate(_text['expiry']!.text)!,
      location: _text['location']!.text,
      unitCost: parseAmount(_text['cost']!.text)!,
      salePrice:
          widget.controller.isAdministrator &&
              _text['price']!.text.trim().isNotEmpty
          ? parseAmount(_text['price']!.text)!
          : null,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.controller;
    final product = data.productById(_productId ?? '');
    final suppliers = data.contacts
        .where((c) => c.kind == ContactKind.supplier && c.active)
        .toList();
    return FormDialog(
      title: 'Recibir lote',
      description:
          'Transcribe el lote del proveedor y su ubicación en la sucursal. Las existencias se registran por unidad de venta.',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('lot-save'),
          onPressed: _save,
          child: const Text('Guardar lote'),
        ),
      ],
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormFieldsGrid(
              fields: [
                DropdownButtonFormField<String>(
                  key: const Key('lot-product'),
                  initialValue: _productId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Producto registrado',
                  ),
                  validator: requiredText,
                  items: [
                    for (final p in data.products.where((p) => p.active))
                      DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          '${p.code} · ${p.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    _productId = v;
                    _packages = false;
                  }),
                ),
                DropdownButtonFormField<String>(
                  key: const Key('lot-supplier'),
                  initialValue: _supplierId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Proveedor de la recepción',
                  ),
                  validator: requiredText,
                  items: [
                    for (final c in suppliers)
                      DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _supplierId = v),
                ),
                _field('code', 'Código del lote del fabricante'),
                _field('location', 'Ubicación: estante / nivel / sección'),
                _field(
                  'manufactured',
                  'Fabricación (AAAA-MM-DD)',
                  keyboard: TextInputType.datetime,
                  validator: (v) {
                    final date = parseCalendarDate(v ?? '');
                    return date == null || date.isAfter(data.today)
                        ? 'Fecha de fabricación válida, no futura.'
                        : null;
                  },
                ),
                _field(
                  'expiry',
                  'Vencimiento (AAAA-MM-DD)',
                  keyboard: TextInputType.datetime,
                  validator: (v) {
                    final date = parseCalendarDate(v ?? '');
                    return date == null || date.isBefore(data.today)
                        ? 'Indica una fecha válida, no vencida.'
                        : null;
                  },
                ),
                _field(
                  'quantity',
                  _packages
                      ? 'Cantidad de envases'
                      : 'Cantidad (${product?.unit ?? 'unidades'})',
                  validator: positiveInteger,
                  keyboard: TextInputType.number,
                ),
                _field(
                  'cost',
                  'Costo por ${product?.unit ?? 'unidad'} (C\$)',
                  validator: (v) => (parseAmount(v ?? '') ?? -1) < 0
                      ? 'Indica un costo desde cero.'
                      : null,
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                if (data.isAdministrator)
                  _field(
                    'price',
                    'Precio de venta por ${product?.unit ?? 'unidad'} (opcional)',
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? null : positiveAmount(v),
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
              ],
            ),
            if (product != null) ...[
              const SizedBox(height: 12),
              Text(
                '${product.presentation} · ${product.dosage} · ${product.packageUnits} ${product.unit} por envase.',
                style: const TextStyle(fontSize: 12),
              ),
              if (product.packageUnits > 1)
                SwitchListTile.adaptive(
                  key: const Key('lot-packages'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Recibir por envases completos'),
                  subtitle: Text(
                    'Cada envase suma ${product.packageUnits} ${product.unit}. Los precios siguen siendo unitarios.',
                  ),
                  value: _packages,
                  onChanged: (v) => setState(() => _packages = v),
                ),
            ],
            if (suppliers.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Registra primero un proveedor desde el directorio.',
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
