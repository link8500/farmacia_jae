import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../inventory/models/inventory_lot.dart';
import '../../purchases/models/purchase_order.dart';
import 'sales_analytics.dart';
import '../../sales/models/sale_receipt.dart';

enum LocalReportKind {
  sales,
  salesDetails,
  salesByOperator,
  inventory,
  purchases,
  cash,
  audit,
  movements,
  incidents,
}

class LocalReport {
  const LocalReport(this.title, this.headers, this.rows);
  final String title;
  final List<String> headers;
  final List<List<Object?>> rows;
}

/// Reportes calculados sobre registros locales; nunca series inventadas.
class LocalReportBuilder {
  static LocalReport build(
    PharmacyController data,
    LocalReportKind kind,
    DateTime start,
    DateTime end, {
    SalesReportFilter filter = const SalesReportFilter(),
  }) {
    final sales = filter.apply(data, start, end);
    // Los grupos usan IDs estables, no nombres que pueden repetirse entre sedes.
    final groupKeys = sales
        .map((s) => (s.branchId, s.registerId, s.actorId))
        .toSet();
    bool includes(DateTime date) {
      final day = InventoryLot.dayOnly(date);
      return !day.isBefore(InventoryLot.dayOnly(start)) &&
          !day.isAfter(InventoryLot.dayOnly(end));
    }

    return switch (kind) {
      LocalReportKind.sales => LocalReport(
        'Ventas por período',
        [
          'Comprobante',
          'Fecha',
          'Hora',
          'Sucursal',
          'Caja',
          'Operador',
          'ID operador',
          'Cliente',
          'Método',
          'Unidades',
          'Total',
          'Estado',
          'Fecha anulación',
          'Motivo',
        ],
        [
          for (final sale in sales)
            [
              sale.id,
              formatDate(sale.createdAt),
              '${sale.createdAt.hour.toString().padLeft(2, '0')}:${sale.createdAt.minute.toString().padLeft(2, '0')}',
              sale.branchName.isEmpty
                  ? 'Sin asignación histórica'
                  : sale.branchName,
              sale.registerName.isEmpty
                  ? 'Sin asignación histórica'
                  : sale.registerName,
              sale.actorName,
              sale.actorId,
              sale.customerName,
              sale.method.label,
              sale.lines.fold<int>(0, (n, l) => n + l.quantity),
              sale.total,
              sale.cancelled ? 'Anulada' : 'Vigente',
              sale.cancelledAt == null ? '' : formatDate(sale.cancelledAt!),
              sale.reason,
            ],
        ],
      ),
      LocalReportKind.salesDetails => LocalReport(
        'Productos facturados',
        [
          'Comprobante',
          'Fecha',
          'Sucursal',
          'Caja',
          'Operador',
          'Producto',
          'Unidad',
          'Cantidad',
          'Precio unitario',
          'Subtotal',
          'Método',
          'Estado',
          'Lotes',
        ],
        [
          for (final sale in sales)
            for (final line in sale.lines)
              [
                sale.id,
                formatDate(sale.createdAt),
                sale.branchName.isEmpty
                    ? 'Sin asignación histórica'
                    : sale.branchName,
                sale.registerName.isEmpty
                    ? 'Sin asignación histórica'
                    : sale.registerName,
                sale.actorName,
                line.name,
                line.unit,
                line.quantity,
                line.unitPrice,
                line.total,
                sale.method.label,
                sale.cancelled ? 'Anulada' : 'Vigente',
                line.allocations
                    .map(
                      (a) =>
                          '${data.lotById(a.lotId)?.code ?? a.lotId}: ${a.quantity}',
                    )
                    .join(' · '),
              ],
        ],
      ),
      LocalReportKind.salesByOperator => LocalReport(
        'Ventas por sucursal, caja y operador',
        [
          'Sucursal',
          'Caja',
          'Operador',
          'ID operador',
          'Facturas vigentes',
          'Anuladas',
          'Unidades netas',
          'Ventas netas',
          'Importe anulado',
          'Ticket promedio',
          'Efectivo',
          'Tarjeta',
          'Transferencia',
        ],
        [
          for (final key in groupKeys)
            _operatorRow(
              sales
                  .where((s) => (s.branchId, s.registerId, s.actorId) == key)
                  .toList(),
            ),
        ],
      ),
      LocalReportKind.inventory => LocalReport(
        'Inventario actual a costo',
        [
          'Producto',
          'Sucursal',
          'Lote',
          'Cantidad',
          'Unidad',
          'Vencimiento',
          'Proveedor',
          'Fabricación',
          'Ubicación',
          'Costo unitario',
          'Valor',
        ],
        [
          for (final lot in data.lots)
            [
              data.productById(lot.productId)!.name,
              data.branchById(lot.branchId)?.name ?? lot.branchId,
              lot.code,
              lot.quantity,
              data.productById(lot.productId)!.unit,
              formatDate(lot.expiry),
              data.contactById(lot.supplierId)?.name ?? '',
              lot.manufacturedAt == null ? '' : formatDate(lot.manufacturedAt!),
              lot.location,
              lot.unitCost,
              lot.quantity * lot.unitCost,
            ],
        ],
      ),
      LocalReportKind.purchases => LocalReport(
        'Compras y proveedores',
        ['Orden', 'Sucursal', 'Fecha', 'Proveedor', 'Total', 'Estado', 'Pago'],
        [
          for (final order in data.purchases.where(
            (p) => includes(p.createdAt),
          ))
            [
              order.id,
              data.branchById(order.branchId)?.name ?? order.branchId,
              formatDate(order.createdAt),
              order.supplierName,
              order.total,
              switch (order.status) {
                PurchaseStatus.pending => 'Pendiente',
                PurchaseStatus.received => 'Recibida',
                PurchaseStatus.cancelled => 'Cancelada',
              },
              order.paidAt == null
                  ? 'Sin pago registrado'
                  : order.paymentMethod,
            ],
        ],
      ),
      LocalReportKind.cash => LocalReport(
        'Arqueos de caja',
        [
          'Caja',
          'Apertura',
          'Responsable',
          'Esperado',
          'Contado',
          'Diferencia',
          'Estado',
        ],
        [
          for (final session in data.cashSessions.where(
            (s) => includes(s.openedAt),
          ))
            [
              session.id,
              formatDate(session.openedAt),
              session.actorName,
              data.expectedCash(session),
              session.counted,
              session.counted == null
                  ? null
                  : session.counted! - data.expectedCash(session),
              session.isOpen ? 'Abierta' : 'Cerrada',
            ],
        ],
      ),
      LocalReportKind.audit => LocalReport(
        'Historial de operaciones',
        ['Fecha', 'Operador', 'Acción', 'Detalle'],
        [
          for (final entry
              in data.audit.where((a) => includes(a.at)).toList().reversed)
            [formatDate(entry.at), entry.actorName, entry.action, entry.detail],
        ],
      ),
      LocalReportKind.movements => LocalReport(
        'Movimientos de inventario',
        [
          'Fecha',
          'Sucursal',
          'Producto',
          'Lote',
          'Variación',
          'Saldo posterior',
          'Motivo',
        ],
        [
          for (final movement
              in data.movements.where((m) => includes(m.at)).toList().reversed)
            [
              formatDate(movement.at),
              data
                      .branchById(data.lotById(movement.lotId)?.branchId ?? '')
                      ?.name ??
                  'Sin sucursal',
              data.productById(movement.productId)!.name,
              data.lots.firstWhere((l) => l.id == movement.lotId).code,
              movement.delta,
              movement.balance,
              movement.reason,
            ],
        ],
      ),
      LocalReportKind.incidents => LocalReport(
        'Solicitudes de soporte',
        [
          'Código',
          'Título',
          'Prioridad',
          'Estado',
          'Creado',
          'Resuelto',
          'Minutos de resolución',
        ],
        [
          for (final incident in data.incidents.where(
            (i) => includes(i.createdAt),
          ))
            [
              incident.id,
              incident.title,
              incident.priority,
              incident.status.name,
              formatDate(incident.createdAt),
              incident.resolvedAt == null
                  ? ''
                  : formatDate(incident.resolvedAt!),
              incident.resolvedAt?.difference(incident.createdAt).inMinutes,
            ],
        ],
      ),
    };
  }

  static List<Object?> _operatorRow(List<SaleReceipt> sales) {
    // La lista no está vacía: se origina de una clave presente en la consulta.
    final first = sales.first;
    final totals = SalesTotals(sales);
    return [
      first.branchName.isEmpty ? 'Sin asignación histórica' : first.branchName,
      first.registerName.isEmpty
          ? 'Sin asignación histórica'
          : first.registerName,
      first.actorName,
      first.actorId,
      totals.count,
      totals.cancelledCount,
      totals.units,
      totals.net,
      totals.cancelled,
      totals.average,
      ...PaymentMethod.values.map(totals.byMethod),
    ];
  }
}
