import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../shared/widgets/record_form_dialog.dart';
import '../models/inventory_lot.dart';

Future<bool?> adjustInventoryLot(
  BuildContext context,
  PharmacyController controller,
  InventoryLot lot,
) => showDialog<bool>(
  context: context,
  builder: (_) => RecordFormDialog(
    title: 'Ajustar ${lot.code}',
    description:
        'Saldo: ${lot.quantity}. Introduce una variación con signo y su motivo.',
    fields: [
      RecordField(
        'adjust-delta',
        'Variación de unidades',
        validator: (value) =>
            int.tryParse(value ?? '') == null || int.tryParse(value ?? '') == 0
            ? 'Entero distinto de cero.'
            : null,
      ),
      const RecordField('adjust-reason', 'Motivo del ajuste', lines: 2),
    ],
    onSave: (v) => controller.adjustLot(
      lot.id,
      int.parse(v['adjust-delta']!),
      v['adjust-reason']!,
    ),
  ),
);
