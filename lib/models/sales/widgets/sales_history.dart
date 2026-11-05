import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../../../shared/widgets/record_form_dialog.dart';
import '../../../shared/widgets/workspace_sections.dart';
import 'receipt_dialog.dart';

/// Historial acotado: buscar, paginar y consultar el comprobante. Las
/// anulaciones conservan el comando de dominio y su motivo obligatorio.
class SalesHistory extends StatefulWidget {
  const SalesHistory({
    required this.controller,
    required this.onNew,
    super.key,
  });
  final PharmacyController controller;
  final VoidCallback onNew;
  @override
  State<SalesHistory> createState() => _SalesHistoryState();
}

class _SalesHistoryState extends State<SalesHistory> {
  String _query = '', _status = 'Vigentes';
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final data = widget.controller;
      final sales = data.sales.reversed
          .where(
            (s) =>
                s.cancelled == (_status == 'Anulados') &&
                '${s.id} ${s.customerName} ${s.actorName}'
                    .toLowerCase()
                    .contains(_query),
          )
          .toList();
      return CompactWorkspace(
        title: 'Facturación',
        subtitle: 'Comprobantes registrados y sus datos de emisión.',
        toolbar: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WorkspaceTabs(
              labels: const ['Nueva factura', 'Historial de facturas'],
              selected: 1,
              onSelected: (i) {
                if (i == 0) widget.onNew();
              },
            ),
            const SizedBox(height: 14),
            RecordToolbar(
              search: TextField(
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Buscar comprobante, cliente u operador',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              filters: [
                RecordFilter(
                  label: 'Estado',
                  value: _status,
                  options: const ['Vigentes', 'Anulados'],
                  onChanged: (v) => setState(() => _status = v),
                ),
              ],
            ),
          ],
        ),
        child: CompactRecords(
          resetKey: (_query, _status),
          itemCount: sales.length,
          minimumTableWidth: 1000,
          columns: const [
            RecordColumn('Factura / fecha', flex: 1.3),
            RecordColumn('Cliente', flex: 1.5),
            RecordColumn('Operador / puesto', flex: 1.8),
            RecordColumn('Pago'),
            RecordColumn('Total'),
            RecordColumn(''),
          ],
          rowBuilder: (i) {
            final s = sales[i];
            final actions = RecordActions(
              actions: [
                (
                  'Ver comprobante',
                  () => showReceipt(context, s, controller: data),
                ),
                if (!s.cancelled && data.isAdministrator)
                  (
                    'Anular venta',
                    () => showDialog<bool>(
                      context: context,
                      builder: (_) => RecordFormDialog(
                        title: 'Anular venta',
                        description: data.hasRecordedCashPayment(s)
                            ? 'Se reintegrarán las cantidades a los lotes originales. Este cobro se registró en Caja y su devolución requiere reactivar Caja con saldo suficiente.'
                            : 'Se reintegrarán las cantidades a los lotes originales y se conservará el comprobante anulado. No se generará ningún movimiento de Caja.',
                        fields: const [
                          RecordField('cancel-reason', 'Motivo', lines: 2),
                        ],
                        onSave: (v) =>
                            data.cancelSale(s.id, v['cancel-reason']!),
                      ),
                    ),
                  ),
              ],
            );
            final place = [
              s.branchName,
              s.registerName,
            ].where((v) => v.isNotEmpty).join(' · ');
            return RecordRow(
              onOpen: () => showReceipt(context, s, controller: data),
              cells: [
                RecordIdentity(title: s.id, subtitle: formatDate(s.createdAt)),
                RecordText(s.customerName),
                RecordIdentity(
                  title: s.actorName,
                  subtitle: place.isEmpty ? 'Sin asignación histórica' : place,
                ),
                RecordText(s.method.label),
                RecordText(formatCordobas(s.total), bold: true),
                actions,
              ],
              mobile: RecordTile(
                title: '${s.id} · ${formatCordobas(s.total)}',
                subtitle: '${s.customerName} · ${s.actorName}',
                metadata:
                    '${formatDate(s.createdAt)} · ${s.method.label} · $place',
                trailing: actions,
                onOpen: () => showReceipt(context, s, controller: data),
              ),
            );
          },
        ),
      );
    },
  );
}
