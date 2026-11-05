import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../../../shared/widgets/record_detail.dart';
import '../widgets/purchase_actions.dart';
import '../../products/widgets/product_thumbnail.dart';

/// El desglose se consulta bajo demanda y conserva las acciones de la orden.
class PurchaseDetailsPage extends StatelessWidget {
  const PurchaseDetailsPage({
    required this.controller,
    required this.purchaseId,
    required this.onBack,
    this.onProduct,
    this.backLabel = 'Volver al listado',
    super.key,
  });
  final PharmacyController controller;
  final String purchaseId;
  final VoidCallback onBack;
  final ValueChanged<String>? onProduct;
  final String backLabel;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final order = controller.purchases
          .where((p) => p.id == purchaseId)
          .firstOrNull;
      if (order == null) {
        return RecordDetail(
          title: 'Compra no disponible',
          onBack: onBack,
          fields: const [],
        );
      }
      return RecordDetail(
        title: order.id,
        subtitle: 'Detalle de compra',
        onBack: onBack,
        backLabel: backLabel,
        actions: [
          for (final action in purchaseActions(context, controller, order))
            OutlinedButton(onPressed: action.$2, child: Text(action.$1)),
        ],
        fields: [
          ('Proveedor', order.supplierName),
          ('Fecha', formatDate(order.createdAt)),
          ('Estado', purchaseStatusLabel(order.status)),
          ('Total', formatCordobas(order.total)),
          (
            'Recepción',
            order.receivedAt == null
                ? 'Sin recibir'
                : formatDate(order.receivedAt!),
          ),
          (
            'Pago',
            order.paidAt == null
                ? 'Sin pago registrado'
                : '${order.paymentMethod} · ${formatDate(order.paidAt!)}',
          ),
          if (order.reason.isNotEmpty) ('Motivo', order.reason),
        ],
        children: [
          const Text(
            'Productos de la orden',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(
            height: 380,
            child: CompactRecords(
              itemCount: order.lines.length,
              resetKey: order.id,
              columns: const [
                RecordColumn('Producto', flex: 3),
                RecordColumn('Cantidad'),
                RecordColumn('Costo'),
                RecordColumn('Total'),
              ],
              rowBuilder: (i) {
                final line = order.lines[i];
                final picture = ProductThumbnail(
                  illustrationKey:
                      controller.productById(line.productId)?.illustrationKey ??
                      '',
                  width: 36,
                  height: 36,
                );
                return RecordRow(
                  onOpen: onProduct == null
                      ? null
                      : () => onProduct!(line.productId),
                  cells: [
                    RecordIdentity(
                      title: line.productName,
                      subtitle: '${line.dosage} · ${line.presentation}',
                      leading: picture,
                    ),
                    RecordText('${line.quantity} ${line.unit}'),
                    RecordText(formatCordobas(line.unitCost)),
                    RecordText(formatCordobas(line.total)),
                  ],
                  mobile: RecordTile(
                    leading: picture,
                    onOpen: onProduct == null
                        ? null
                        : () => onProduct!(line.productId),
                    title: line.productName,
                    subtitle:
                        '${line.quantity} ${line.unit} × ${formatCordobas(line.unitCost)}',
                    metadata: formatCordobas(line.total),
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
