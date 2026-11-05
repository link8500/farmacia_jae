import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../shared/widgets/adaptive_grid.dart';
import '../../sales/models/sale_receipt.dart';
import '../models/sales_analytics.dart';

/// Filtros tipados reutilizados por reportes y consulta de cajas. Los nombres
/// históricos se conservan en las filas; aquí se seleccionan IDs estables.
class SalesFilters extends StatelessWidget {
  const SalesFilters({
    required this.controller,
    required this.value,
    required this.onChanged,
    super.key,
  });
  final PharmacyController controller;
  final SalesReportFilter value;
  final ValueChanged<SalesReportFilter> onChanged;
  @override
  Widget build(BuildContext context) {
    Widget select(
      String label,
      String selected,
      List<(String, String)> options,
      ValueChanged<String> change,
    ) => DropdownButtonFormField<String>(
      key: ValueKey('$label-$selected'),
      isExpanded: true,
      initialValue: options.any((o) => o.$1 == selected) ? selected : '*',
      decoration: InputDecoration(labelText: label),
      items: [
        for (final o in options)
          DropdownMenuItem(
            value: o.$1,
            child: Text(o.$2, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) {
        if (v != null) change(v);
      },
    );
    String? optional(String id) => id == '*' ? null : id;
    final sales = controller.sales;
    return AdaptiveGrid(
      minItemWidth: 200,
      maxColumns: 5,
      gap: 12,
      children: [
        select(
          'Sucursal del reporte',
          value.branchId ?? '*',
          [
            ('*', 'Todas las sucursales accesibles'),
            for (final b in controller.branches) (b.id, b.name),
            if (sales.any((s) => s.branchId.isEmpty))
              ('', 'Sin asignación histórica'),
          ],
          (id) => onChanged(
            SalesReportFilter(
              branchId: optional(id),
              method: value.method,
              state: value.state,
            ),
          ),
        ),
        select(
          'Caja del reporte',
          value.registerId ?? '*',
          [
            ('*', 'Todas las cajas'),
            for (final r in controller.registers.where(
              (r) => value.branchId == null || r.branchId == value.branchId,
            ))
              (r.id, '${controller.branchById(r.branchId)?.name} · ${r.name}'),
            if (sales.any((s) => s.registerId.isEmpty) &&
                (value.branchId == null || value.branchId == ''))
              ('', 'Sin asignación histórica'),
          ],
          (id) => onChanged(
            SalesReportFilter(
              branchId: value.branchId,
              registerId: optional(id),
              actorId: value.actorId,
              method: value.method,
              state: value.state,
            ),
          ),
        ),
        select(
          'Operador del reporte',
          value.actorId ?? '*',
          [
            ('*', 'Todos los operadores'),
            for (final s in controller.staff)
              (s.id, '${s.name} (${s.username})'),
            if (sales.any((s) => s.actorId.isEmpty))
              ('', 'Sin identificador histórico'),
          ],
          (id) => onChanged(
            SalesReportFilter(
              branchId: value.branchId,
              registerId: value.registerId,
              actorId: optional(id),
              method: value.method,
              state: value.state,
            ),
          ),
        ),
        select(
          'Método de pago',
          value.method?.name ?? '*',
          [
            ('*', 'Todos los métodos'),
            for (final m in PaymentMethod.values) (m.name, m.label),
          ],
          (id) => onChanged(
            SalesReportFilter(
              branchId: value.branchId,
              registerId: value.registerId,
              actorId: value.actorId,
              method: id == '*' ? null : PaymentMethod.values.byName(id),
              state: value.state,
            ),
          ),
        ),
        select(
          'Estado de venta',
          value.state.name,
          [
            for (final s in SaleReportState.values)
              (
                s.name,
                switch (s) {
                  SaleReportState.all => 'Vigentes y anuladas',
                  SaleReportState.valid => 'Solo vigentes',
                  SaleReportState.cancelled => 'Solo anuladas',
                },
              ),
          ],
          (id) => onChanged(
            SalesReportFilter(
              branchId: value.branchId,
              registerId: value.registerId,
              actorId: value.actorId,
              method: value.method,
              state: SaleReportState.values.byName(id),
            ),
          ),
        ),
      ],
    );
  }
}
