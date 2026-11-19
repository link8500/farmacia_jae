import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/form_dialog.dart';
import '../../contacts/models/contact.dart';
import '../../products/models/product.dart';
import '../../products/widgets/product_thumbnail.dart';
import '../models/purchase_order.dart';
import 'purchase_receipt_dialog.dart';

/// Compra por medicamento: la búsqueda muestra presentación y concentración,
/// después filtra proveedores por la tabla comercial N:M.
class PurchaseFormDialog extends StatefulWidget {
  const PurchaseFormDialog({required this.controller, super.key});
  final PharmacyController controller;
  @override
  State<PurchaseFormDialog> createState() => _PurchaseFormDialogState();
}

class _PurchaseFormDialogState extends State<PurchaseFormDialog> {
  final _lineForm = GlobalKey<FormState>();
  final _search = TextEditingController(),
      _quantity = TextEditingController(text: '12'),
      _cost = TextEditingController();
  final List<PurchaseLine> _lines = [];
  String? _supplier, _product, _error;
  bool _packages = false, _allSuppliers = false;
  @override
  void dispose() {
    _search.dispose();
    _quantity.dispose();
    _cost.dispose();
    super.dispose();
  }

  void _select(String? id) {
    setState(() {
      _product = id;
      _packages = false;
      _allSuppliers = false;
      _error = null;
      final linked = id == null
          ? <Contact>[]
          : widget.controller.suppliersForProduct(id);
      if (_lines.isEmpty && !linked.any((s) => s.id == _supplier)) {
        _supplier = linked.length == 1 ? linked.single.id : null;
      }
      _loadReferenceCost();
    });
  }

  void _loadReferenceCost() {
    final terms = widget.controller.supplierTerms(
      _product ?? '',
      _supplier ?? '',
    );
    final cost = terms?.referenceCost ?? 0;
    _cost.text = cost > 0 ? '$cost' : '';
  }

  String _productLabel(Product product) => [
    product.name,
    if (product.dosage.isNotEmpty) product.dosage,
    product.presentation,
  ].join(' · ');

  bool _addLine() {
    final p = widget.controller.productById(_product ?? '');
    if (p == null || _search.text != _productLabel(p)) {
      setState(() => _error = 'Selecciona un medicamento de los resultados.');
      return false;
    }
    if (!_lineForm.currentState!.validate() || _supplier == null) return false;
    if (_lines.any((l) => l.productId == _product)) {
      setState(
        () => _error =
            'El producto ya está en la orden. Quita la línea para cambiarla.',
      );
      return false;
    }
    final quantity =
        int.parse(_quantity.text.trim()) * (_packages ? p.packageUnits : 1);
    if (quantity > 1000000) {
      setState(
        () => _error = 'La cantidad convertida supera el límite de unidades.',
      );
      return false;
    }
    setState(() {
      _lines.add(
        PurchaseLine(
          productId: p.id,
          productName: p.name,
          quantity: quantity,
          unitCost: parseAmount(_cost.text)!,
          dosage: p.dosage,
          presentation: p.presentation,
          unit: p.unit,
          packageUnits: p.packageUnits,
        ),
      );
      _error = null;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.controller;
    final p = data.productById(_product ?? '');
    final linked = p == null ? <Contact>[] : data.suppliersForProduct(p.id);
    final selectedSupplier = data.contactById(_supplier ?? '');
    final suppliers = data.contacts
        .where(
          (c) =>
              c.kind == ContactKind.supplier &&
              c.active &&
              data.supplierTerms(p?.id ?? '', c.id)?.active != false &&
              (_allSuppliers ||
                  linked.isEmpty ||
                  linked.any((s) => s.id == c.id) ||
                  (_lines.isNotEmpty && c.id == _supplier)),
        )
        .toList();
    return FormDialog(
      title: 'Nueva orden de compra',
      description:
          'Selecciona un medicamento y compara sus proveedores. La recepción posterior incorpora los lotes y sus fechas.',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('purchase-save'),
          onPressed: () {
            if (_lines.isEmpty && !_addLine()) return;
            final error = data.createPurchase(_supplier ?? '', _lines);
            if (error != null) {
              setState(() => _error = error);
            } else {
              Navigator.pop(context, true);
            }
          },
          child: const Text('Guardar orden'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Form(
            key: _lineForm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, box) => DropdownMenu<String>(
                    key: const Key('purchase-product'),
                    controller: _search,
                    width: box.maxWidth,
                    menuHeight: 240,
                    enableFilter: true,
                    enableSearch: true,
                    requestFocusOnTap: true,
                    label: const Text(
                      'Buscar medicamento, dosis o presentación',
                    ),
                    leadingIcon: const Icon(Icons.search),
                    dropdownMenuEntries: [
                      for (final item in data.products.where(
                        (item) =>
                            item.active &&
                            (_lines.isEmpty ||
                                data
                                        .supplierTerms(item.id, _supplier ?? '')
                                        ?.active !=
                                    false),
                      ))
                        DropdownMenuEntry(
                          value: item.id,
                          label: _productLabel(item),
                          labelWidget: Text(
                            _productLabel(item),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onSelected: _select,
                  ),
                ),
                if (p != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Dosis / concentración: ${p.dosage.isEmpty ? 'No especificada' : p.dosage}\n${p.presentation} · ${p.packageUnits} ${p.unit} por envase',
                      style: const TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ),
                if (p != null) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                      'purchase-supplier-${_product ?? ''}-$_allSuppliers-${_lines.isNotEmpty}',
                    ),
                    initialValue: suppliers.any((s) => s.id == _supplier)
                        ? _supplier
                        : null,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: linked.isEmpty
                          ? 'Proveedor de la orden'
                          : 'Proveedores de este medicamento',
                    ),
                    items: [
                      for (final c in suppliers)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            [
                              c.code,
                              c.name,
                              if (c.origin.isNotEmpty) c.origin,
                            ].join(' · '),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _lines.isNotEmpty
                        ? null
                        : (v) => setState(() {
                            _supplier = v;
                            _loadReferenceCost();
                          }),
                    validator: requiredText,
                  ),
                  if (_lines.isEmpty && linked.isNotEmpty)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text(
                        'Consultar otros proveedores del directorio',
                      ),
                      value: _allSuppliers,
                      onChanged: (v) => setState(() {
                        _allSuppliers = v ?? false;
                        if (!_allSuppliers &&
                            !linked.any((c) => c.id == _supplier)) {
                          _supplier = null;
                          _loadReferenceCost();
                        }
                      }),
                    ),
                  if (linked.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Sin proveedores vinculados. La primera compra guardará la relación comercial.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  if (_lines.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Proveedor de la orden: ${selectedSupplier?.name ?? ''}. Para comprar a otro proveedor, crea otra orden.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 18),
                  FormFieldsGrid(
                    fields: [
                      TextFormField(
                        key: const Key('purchase-quantity'),
                        controller: _quantity,
                        validator: positiveInteger,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _packages
                              ? 'Cantidad de envases'
                              : 'Cantidad (${p.unit})',
                        ),
                      ),
                      TextFormField(
                        key: const Key('purchase-cost'),
                        controller: _cost,
                        validator: positiveAmount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Costo por ${p.unit} (C\$)',
                        ),
                      ),
                    ],
                  ),
                  if (p.packageUnits > 1)
                    SwitchListTile.adaptive(
                      key: const Key('purchase-packages'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Comprar por envases completos'),
                      subtitle: Text(
                        'Cada envase suma ${p.packageUnits} ${p.unit}. El costo se captura por unidad.',
                      ),
                      value: _packages,
                      onChanged: (v) => setState(() => _packages = v),
                    ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: const Key('purchase-add-line'),
                      onPressed: _addLine,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Añadir a la orden'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_lines.isNotEmpty) const Divider(height: 28),
          for (final line in _lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ProductThumbnail.forProduct(
                    data.productById(line.productId),
                    width: 36,
                    height: 36,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${line.productName}\n${line.quantity} ${line.unit} × ${formatCordobas(line.unitCost)} · ${formatCordobas(line.total)}',
                      style: const TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _lines.remove(line)),
                    tooltip: 'Quitar línea',
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Text(
            'Total de la orden: ${formatCordobas(_lines.fold<double>(0, (n, l) => n + l.total))}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

/// Abre la recepción vinculada a una orden existente.
Future<void> receivePurchaseDialog(
  BuildContext context,
  PharmacyController controller,
  PurchaseOrder order,
) async {
  await showDialog<bool>(
    context: context,
    builder: (_) => PurchaseReceiptDialog(controller: controller, order: order),
  );
}
