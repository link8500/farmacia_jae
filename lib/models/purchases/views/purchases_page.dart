import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../models/purchase_order.dart';
import '../widgets/purchase_actions.dart';
import '../widgets/purchase_dialogs.dart';
import 'purchase_details_page.dart';

/// Resumen de órdenes paginado. Las líneas y fechas completas van en el detalle.
class PurchasesPage extends StatefulWidget {
  const PurchasesPage({required this.controller, this.onOpen, super.key});
  final PharmacyController controller;
  final ValueChanged<String>? onOpen;
  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends State<PurchasesPage> {
  String _query = '', _filter = 'Todas';
  String? _selected;
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(PurchaseOrder order) {
    if (widget.onOpen != null) {
      widget.onOpen!(order.id);
    } else {
      setState(() => _selected = order.id);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final data = widget.controller;
      if (_selected != null) {
        return PurchaseDetailsPage(
          controller: data,
          purchaseId: _selected!,
          onBack: () => setState(() => _selected = null),
        );
      }
      final orders = data.purchases.reversed
          .where(
            (p) =>
                '${p.id} ${p.supplierName}'.toLowerCase().contains(_query) &&
                (_filter == 'Todas' ||
                    _filter == 'Pendientes' &&
                        p.status == PurchaseStatus.pending ||
                    _filter == 'Recibidas' &&
                        p.status == PurchaseStatus.received ||
                    _filter == 'Canceladas' &&
                        p.status == PurchaseStatus.cancelled),
          )
          .toList();
      return CompactWorkspace(
        title: 'Compras',
        subtitle: '${orders.length} órdenes',
        actions: [
          FilledButton.icon(
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => PurchaseFormDialog(controller: data),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nueva compra'),
          ),
        ],
        toolbar: RecordToolbar(
          search: TextField(
            key: const Key('purchases-search'),
            controller: _search,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'Buscar orden o proveedor',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
          filters: [
            RecordFilter(
              label: 'Estado',
              value: _filter,
              options: const ['Todas', 'Pendientes', 'Recibidas', 'Canceladas'],
              onChanged: (v) => setState(() => _filter = v),
            ),
          ],
        ),
        child: CompactRecords(
          itemCount: orders.length,
          resetKey: '$_query|$_filter|${data.workingBranchId}',
          emptyText: 'No hay órdenes para este filtro.',
          columns: const [
            RecordColumn('Orden', flex: 1.5),
            RecordColumn('Proveedor', flex: 2),
            RecordColumn('Fecha'),
            RecordColumn('Estado'),
            RecordColumn('Total'),
            RecordColumn('', flex: .5),
          ],
          rowBuilder: (i) {
            final order = orders[i];
            final actions = RecordActions(
              recordKey: 'purchase-actions-${order.id}',
              actions: [
                ('Ver detalle', () => _open(order)),
                ...purchaseActions(context, data, order),
              ],
            );
            return RecordRow(
              onOpen: () => _open(order),
              cells: [
                RecordText(order.id, bold: true),
                RecordText(order.supplierName),
                RecordText(formatDate(order.createdAt)),
                RecordText(purchaseStatusLabel(order.status)),
                RecordText(formatCordobas(order.total)),
                actions,
              ],
              mobile: RecordTile(
                title: order.id,
                subtitle: order.supplierName,
                metadata:
                    '${purchaseStatusLabel(order.status)} · ${formatCordobas(order.total)}',
                trailing: actions,
                onOpen: () => _open(order),
              ),
            );
          },
        ),
      );
    },
  );
}
