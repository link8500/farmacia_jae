import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../../../shared/widgets/record_detail.dart';
import '../../../shared/widgets/record_form_dialog.dart';
import '../../../core/utils/form_validators.dart';
import '../../contacts/models/contact.dart';
import '../widgets/inventory_actions.dart';
import '../models/inventory_lot.dart';
import '../../products/widgets/product_thumbnail.dart';

class LotDetailsPage extends StatelessWidget {
  const LotDetailsPage({
    required this.controller,
    required this.lotId,
    required this.onBack,
    super.key,
  });
  final PharmacyController controller;
  final String lotId;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final lot = controller.lots.where((l) => l.id == lotId).firstOrNull;
      if (lot == null) {
        return RecordDetail(
          title: 'Lote no disponible',
          onBack: onBack,
          fields: const [],
        );
      }
      final product = controller.productById(lot.productId);
      final movements =
          controller.movements.where((m) => m.lotId == lot.id).toList()
            ..sort((a, b) => b.at.compareTo(a.at));
      return RecordDetail(
        title: lot.code,
        subtitle: product?.name ?? '',
        media: ProductThumbnail(
          illustrationKey: product?.illustrationKey ?? '',
          height: 150,
          showCaption: true,
        ),
        onBack: onBack,
        actions: [
          if (controller.isAdministrator)
            OutlinedButton.icon(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => RecordFormDialog(
                  title: 'Documentación del lote',
                  description:
                      '${lot.code} · ${product?.name ?? ''}. Conserva cantidad, costo y vencimiento. La corrección queda en el historial.',
                  fields: [
                    RecordField(
                      'lot-detail-supplier',
                      'Proveedor',
                      initial: lot.supplierId,
                      options: [
                        for (final s in controller.contacts.where(
                          (s) =>
                              s.kind == ContactKind.supplier &&
                              (s.active || s.id == lot.supplierId),
                        ))
                          (s.id, '${s.code} · ${s.name}'),
                      ],
                    ),
                    RecordField(
                      'lot-detail-manufactured',
                      'Fabricación (AAAA-MM-DD)',
                      initial:
                          lot.manufacturedAt?.toIso8601String().substring(
                            0,
                            10,
                          ) ??
                          '',
                      firstDate: DateTime(1900),
                      lastDate: InventoryLot.dayOnly(lot.receivedAt),
                      validator: (v) => parseCalendarDate(v ?? '') == null
                          ? 'Indica una fecha válida.'
                          : null,
                      keyboard: TextInputType.datetime,
                    ),
                    RecordField(
                      'lot-detail-location',
                      'Estante / nivel / sección',
                      initial: lot.location,
                    ),
                  ],
                  onSave: (v) => controller.documentLot(
                    lot.id,
                    supplierId: v['lot-detail-supplier']!,
                    manufacturedAt: parseCalendarDate(
                      v['lot-detail-manufactured']!,
                    )!,
                    location: v['lot-detail-location']!,
                  ),
                ),
              ),
              icon: const Icon(Icons.edit_note_outlined, size: 17),
              label: const Text('Editar trazabilidad'),
            ),

          if (controller.isAdministrator)
            OutlinedButton.icon(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => RecordFormDialog(
                  title: 'Ubicación del lote',
                  description:
                      'Sucursal: ${controller.workingBranch?.name ?? ''}. Cambiar ubicación conserva el saldo y la trazabilidad.',
                  fields: [
                    RecordField(
                      'lot-new-location',
                      'Estante / nivel / sección',
                      initial: lot.location,
                    ),
                  ],
                  onSave: (v) =>
                      controller.relocateLot(lot.id, v['lot-new-location']!),
                ),
              ),
              icon: const Icon(Icons.place_outlined, size: 17),
              label: const Text('Ubicar lote'),
            ),

          if (controller.isAdministrator)
            FilledButton.icon(
              onPressed: () => adjustInventoryLot(context, controller, lot),
              icon: const Icon(Icons.tune, size: 17),
              label: const Text('Ajustar existencias'),
            ),
        ],
        fields: [
          ('Producto', product?.name ?? ''),
          ('Cantidad', '${lot.quantity} ${product?.unit ?? ''}'),
          ('Código del fabricante', lot.code),
          (
            'Proveedor',
            controller.contactById(lot.supplierId)?.name ??
                'Pendiente de documentar',
          ),
          (
            'Fabricación',
            lot.manufacturedAt == null
                ? 'Pendiente de documentar'
                : formatDate(lot.manufacturedAt!),
          ),
          (
            'Ubicación física',
            lot.location.isEmpty ? 'Sin ubicar' : lot.location,
          ),
          ('Sucursal', controller.workingBranch?.name ?? ''),
          ('Vencimiento', formatDate(lot.expiry)),
          ('Recepción', formatDate(lot.receivedAt)),
          (
            'Estado',
            lot.isExpired(controller.today)
                ? 'Vencido'
                : lot.quantity == 0
                ? 'Agotado'
                : lot.isExpiring(controller.today)
                ? 'Por vencer'
                : 'Disponible',
          ),
          if (controller.isAdministrator)
            ('Costo unitario', formatCordobas(lot.unitCost)),
        ],
        children: [
          const Text(
            'Movimientos del lote',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(
            height: 380,
            child: CompactRecords(
              itemCount: movements.length,
              resetKey: lot.id,
              emptyText: 'No hay movimientos registrados para este lote.',
              columns: const [
                RecordColumn('Fecha'),
                RecordColumn('Movimiento', flex: 3),
                RecordColumn('Variación'),
                RecordColumn('Saldo'),
              ],
              rowBuilder: (i) {
                final m = movements[i];
                return RecordRow(
                  cells: [
                    RecordText(formatDate(m.at)),
                    RecordText(m.reason),
                    RecordText('${m.delta > 0 ? '+' : ''}${m.delta}'),
                    RecordText('${m.balance}'),
                  ],
                  mobile: RecordTile(
                    title: m.reason,
                    subtitle: formatDate(m.at),
                    metadata: 'Variación: ${m.delta} · Saldo: ${m.balance}',
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}
