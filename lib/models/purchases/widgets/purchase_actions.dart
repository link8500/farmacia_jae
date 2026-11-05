import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/record_form_dialog.dart';
import '../../sales/models/sale_receipt.dart';
import '../models/purchase_order.dart';
import 'purchase_dialogs.dart';

String purchaseStatusLabel(PurchaseStatus status) => switch (status) {
  PurchaseStatus.pending => 'Pendiente',
  PurchaseStatus.received => 'Recibida',
  PurchaseStatus.cancelled => 'Cancelada',
};

/// El listado y el detalle comparten las acciones; las validaciones siguen
/// perteneciendo al controlador, incluida la recepción completa de los lotes.
List<(String, VoidCallback)> purchaseActions(
  BuildContext context,
  PharmacyController data,
  PurchaseOrder order,
) => [
  if (order.status == PurchaseStatus.pending) ...[
    ('Recibir lotes', () => receivePurchaseDialog(context, data, order)),
    (
      'Cancelar orden',
      () => showDialog<bool>(
        context: context,
        builder: (_) => RecordFormDialog(
          title: 'Cancelar orden',
          description:
              'Solo se cancelan órdenes que aún no incorporaron existencias.',
          fields: const [RecordField('reason', 'Motivo', lines: 2)],
          onSave: (v) => data.cancelPurchase(order.id, v['reason']!),
        ),
      ),
    ),
  ],
  if (order.status == PurchaseStatus.received && order.paidAt == null)
    (
      'Registrar pago',
      () => showDialog<bool>(
        context: context,
        builder: (_) => RecordFormDialog(
          title: 'Registrar pago completo',
          description:
              '${formatCordobas(order.total)}. Es un registro interno: no se procesa ningún pago bancario.',
          fields: [
            RecordField(
              'method',
              'Método',
              initial: PaymentMethod.cash.name,
              options: [
                for (final m in PaymentMethod.values) (m.name, m.label),
              ],
            ),
          ],
          onSave: (v) => data.payPurchase(
            order.id,
            PaymentMethod.values.byName(v['method']!),
          ),
        ),
      ),
    ),
];
