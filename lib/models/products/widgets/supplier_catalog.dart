import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../../../shared/widgets/record_form_dialog.dart';
import '../models/product_supplier.dart';
import '../../contacts/models/contact.dart';

/// La misma relación comercial se administra desde la ficha del medicamento o
/// desde el proveedor. No se mantienen dos listas independientes.
class SupplierCatalog extends StatelessWidget {
  const SupplierCatalog({
    required this.controller,
    this.productId,
    this.supplierId,
    super.key,
  });
  final PharmacyController controller;
  final String? productId, supplierId;

  void _edit(BuildContext context, [ProductSupplier? record]) {
    showDialog<bool>(
      context: context,
      builder: (_) => RecordFormDialog(
        title: record == null
            ? 'Vincular producto y proveedor'
            : 'Editar vínculo comercial',
        description:
            'Costo de referencia por unidad de venta. No modifica compras anteriores ni existencias.',
        fields: [
          RecordField(
            'link-product',
            'Producto',
            initial: record?.productId ?? productId ?? '',
            options: [
              for (final p in controller.products.where(
                (p) =>
                    p.active &&
                    (productId == null || p.id == productId) &&
                    (record == null || p.id == record.productId),
              ))
                (p.id, '${p.name} · ${p.dosage} · ${p.presentation}'),
            ],
          ),
          RecordField(
            'link-supplier',
            'Proveedor',
            initial: record?.supplierId ?? supplierId ?? '',
            options: [
              for (final c in controller.contacts.where(
                (c) =>
                    c.active &&
                    c.kind == ContactKind.supplier &&
                    (supplierId == null || c.id == supplierId) &&
                    (record == null || c.id == record.supplierId),
              ))
                (c.id, '${c.code} · ${c.name}'),
            ],
          ),
          RecordField(
            'link-code',
            'Código en catálogo del proveedor',
            initial: record?.supplierCode ?? '',
            optional: true,
          ),
          RecordField(
            'link-cost',
            'Costo unitario de referencia (C\$)',
            initial: '${record?.referenceCost ?? 0}',
            validator: (s) => (parseAmount(s ?? '') ?? -1) < 0
                ? 'Indica un costo desde cero.'
                : null,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
          RecordField(
            'link-days',
            'Plazo de entrega (días)',
            initial: '${record?.leadDays ?? 0}',
            validator: nonNegativeInteger,
            keyboard: TextInputType.number,
          ),
          RecordField(
            'link-state',
            'Estado comercial',
            initial: record?.active == false ? 'inactive' : 'active',
            options: const [
              ('active', 'Disponible para compra'),
              ('inactive', 'Suspendido'),
            ],
          ),
        ],
        onSave: (v) => controller.saveProductSupplier(
          productId: v['link-product']!,
          supplierId: v['link-supplier']!,
          supplierCode: v['link-code']!,
          referenceCost: parseAmount(v['link-cost']!)!,
          leadDays: int.parse(v['link-days']!),
          active: v['link-state'] == 'active',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = controller.productSuppliers
        .where(
          (r) =>
              (productId == null || r.productId == productId) &&
              (supplierId == null || r.supplierId == supplierId) &&
              controller.products.any((p) => p.id == r.productId),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              productId != null
                  ? 'Proveedores del producto'
                  : 'Catálogo del proveedor',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            OutlinedButton.icon(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.link, size: 17),
              label: const Text('Vincular producto'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 320,
          child: CompactRecords(
            itemCount: list.length,
            resetKey: '$productId|$supplierId',
            emptyText:
                'Vincula el catálogo para sugerir proveedores al preparar una compra.',
            columns: [
              RecordColumn(
                productId != null ? 'Proveedor' : 'Producto',
                flex: 2.5,
              ),
              const RecordColumn('Referencia'),
              const RecordColumn('Costo / unidad'),
              const RecordColumn('Entrega'),
              const RecordColumn('Estado'),
            ],
            rowBuilder: (i) {
              final r = list[i];
              final label = productId != null
                  ? controller.contactById(r.supplierId)?.name ?? ''
                  : controller.productById(r.productId)?.name ?? '';
              return RecordRow(
                onOpen: () => _edit(context, r),
                cells: [
                  RecordText(label, bold: true),
                  RecordText(r.supplierCode),
                  RecordText(formatCordobas(r.referenceCost)),
                  RecordText('${r.leadDays} días'),
                  RecordText(r.active ? 'Disponible' : 'Suspendido'),
                ],
                mobile: RecordTile(
                  title: label,
                  subtitle:
                      '${formatCordobas(r.referenceCost)} / unidad · ${r.leadDays} días',
                  metadata: r.active ? 'Disponible' : 'Suspendido',
                  onOpen: () => _edit(context, r),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
