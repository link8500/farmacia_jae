import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/json_value.dart';
import '../../purchases/models/purchase_order.dart';
import '../../sales/models/sale_receipt.dart';
import 'local_report.dart';
import 'sales_analytics.dart';

enum ReportChartType { line, bars, donut }

/// Punto independiente de Flutter: identidad, etiqueta, unidad y referencia opcional.
class ChartValue {
  const ChartValue(
    this.key,
    this.label,
    this.value, {
    this.unit = '',
    this.reference,
  });
  final String key, label, unit;
  final double value;
  final double? reference;
}

/// Contrato visual compartido por líneas, barras y distribución porcentual.
class ReportChartSpec {
  const ReportChartSpec({
    required this.id,
    required this.title,
    required this.description,
    required this.explanation,
    required this.type,
    required this.values,
    this.currency = false,
    this.referenceLabel,
    this.unit = 'Registros',
  });
  final String id, title, description, explanation, unit;
  final ReportChartType type;
  final List<ChartValue> values;
  final bool currency;
  final String? referenceLabel;
  bool get hasData =>
      values.any((p) => p.value != 0 || (p.reference ?? 0) != 0);
  double get total => values.fold(0, (sum, p) => sum + p.value);
  String format(double value, {String? unit}) => currency
      ? formatCordobas(value)
      : '${value == value.roundToDouble() ? value.toInt() : value.toStringAsFixed(2)}${(unit ?? this.unit).isEmpty ? '' : ' ${unit ?? this.unit}'}';
}

class ReportMetric {
  const ReportMetric(this.label, this.value, this.explanation);
  final String label, value, explanation;
}

/// Proyección calculada y de solo lectura. No cambia operaciones ni usa series demo.
class ReportVisuals {
  const ReportVisuals(this.metrics, this.charts);
  final List<ReportMetric> metrics;
  final List<ReportChartSpec> charts;

  static bool isSales(LocalReportKind kind) => const [
    LocalReportKind.sales,
    LocalReportKind.salesDetails,
    LocalReportKind.salesByOperator,
  ].contains(kind);
  static bool includes(DateTime value, DateTime start, DateTime end) =>
      !DateTime.utc(
        value.year,
        value.month,
        value.day,
      ).isBefore(DateTime.utc(start.year, start.month, start.day)) &&
      !DateTime.utc(
        value.year,
        value.month,
        value.day,
      ).isAfter(DateTime.utc(end.year, end.month, end.day));

  /// Acota el número de puntos sin perder operaciones: días, semanas, meses o
  /// años según el período. Los intervalos sin actividad conservan valor cero.
  static List<ChartValue> timeline(
    List<(DateTime, double)> entries,
    DateTime start,
    DateTime end,
  ) {
    final first = DateTime.utc(start.year, start.month, start.day);
    final last = DateTime.utc(end.year, end.month, end.day);
    if (last.isBefore(first)) return [];
    final days = last.difference(first).inDays + 1;
    final months = (last.year - first.year) * 12 + last.month - first.month + 1;
    final mode = days <= 31
        ? 0
        : days <= 186
        ? 1
        : months <= 36
        ? 2
        : 3;
    final count = mode == 0
        ? days
        : mode == 1
        ? (days / 7).ceil()
        : mode == 2
        ? months
        : last.year - first.year + 1;
    final totals = List<double>.filled(count, 0);
    for (final entry in entries) {
      final date = DateTime.utc(entry.$1.year, entry.$1.month, entry.$1.day);
      if (date.isBefore(first) || date.isAfter(last)) continue;
      final index = switch (mode) {
        0 => date.difference(first).inDays,
        1 => date.difference(first).inDays ~/ 7,
        2 => (date.year - first.year) * 12 + date.month - first.month,
        _ => date.year - first.year,
      };
      totals[index] += entry.$2;
    }
    return [
      for (var i = 0; i < count; i++)
        ChartValue('$i', switch (mode) {
          0 => formatDate(first.add(Duration(days: i))),
          1 =>
            'Semana ${i + 1} · ${formatDate(first.add(Duration(days: i * 7)))}',
          2 =>
            '${DateTime(first.year, first.month + i).month.toString().padLeft(2, '0')}/${DateTime(first.year, first.month + i).year}',
          _ => '${first.year + i}',
        }, money(totals[i])),
    ];
  }

  /// Agrupa por identificadores estables; nunca mezcla operadores o sucursales
  /// distintos solo porque comparten nombre. Los rankings muestran los seis mayores.
  static List<ChartValue> grouped(
    Iterable<(String, String, double, String)> source, {
    int limit = 6,
  }) {
    final totals = <String, double>{},
        labels = <String, String>{},
        units = <String, String>{};
    for (final item in source) {
      totals.update(item.$1, (v) => v + item.$3, ifAbsent: () => item.$3);
      labels.putIfAbsent(item.$1, () => item.$2);
      units[item.$1] = item.$4;
    }
    final values = [
      for (final key in totals.keys)
        ChartValue(key, labels[key]!, money(totals[key]!), unit: units[key]!),
    ];
    values.sort((a, b) {
      final order = b.value.compareTo(a.value);
      return order != 0 ? order : a.key.compareTo(b.key);
    });
    return values.take(limit).toList();
  }

  static ReportVisuals build(
    PharmacyController data,
    LocalReportKind kind,
    DateTime start,
    DateTime end, {
    SalesReportFilter filter = const SalesReportFilter(),
  }) {
    if (isSales(kind)) {
      final all = filter.apply(data, start, end);
      final totals = SalesTotals(all);
      final valid = all.where((s) => !s.cancelled).toList();
      return ReportVisuals(
        [
          ReportMetric(
            'Ventas netas',
            formatCordobas(totals.net),
            'Suma de facturas vigentes; no es utilidad.',
          ),
          ReportMetric(
            'Facturas vigentes',
            '${totals.count}',
            'Comprobantes no anulados del filtro.',
          ),
          ReportMetric(
            'Ticket promedio',
            formatCordobas(totals.average),
            'Ventas netas ÷ facturas vigentes.',
          ),
          ReportMetric(
            'Unidades vendidas',
            '${totals.units}',
            'Unidades de venta, no tabletas equivalentes.',
          ),
          ReportMetric(
            'Facturas anuladas',
            '${totals.cancelledCount}',
            '${formatCordobas(totals.cancelled)} excluidos de ventas netas.',
          ),
        ],
        [
          ReportChartSpec(
            id: 'sales-trend',
            title: 'Evolución de las ventas',
            description: 'Importe neto por intervalo del período.',
            currency: true,
            type: ReportChartType.line,
            values: timeline(
              [for (final s in valid) (s.createdAt, s.total)],
              start,
              end,
            ),
            explanation:
                'Cada punto suma facturas vigentes por fecha de emisión. El intervalo se agrupa automáticamente según el período; los días sin actividad cuentan como cero. No mide utilidad ni reembolsos por fecha de devolución.',
          ),
          ReportChartSpec(
            id: 'sales-payments',
            title: 'Métodos de pago',
            description: 'Participación en las ventas netas.',
            currency: true,
            type: ReportChartType.donut,
            values: [
              for (final method in PaymentMethod.values)
                ChartValue(method.name, method.label, totals.byMethod(method)),
            ],
            explanation:
                'El porcentaje representa importe cobrado en facturas vigentes, no cantidad de transacciones. Tarjeta y transferencia son registros locales, no autorizaciones bancarias.',
          ),
          ReportChartSpec(
            id: 'sales-products',
            title: 'Productos más vendidos',
            description: 'Hasta seis productos por cantidad facturada.',
            type: ReportChartType.bars,
            unit: 'Unidades de venta',
            values: grouped([
              for (final s in valid)
                for (final l in s.lines)
                  (
                    '${l.productId}|${l.unit}',
                    l.name,
                    l.quantity.toDouble(),
                    l.unit,
                  ),
            ]),
            explanation:
                'Las barras cuentan presentaciones vendidas. Cajas, frascos y tubos mantienen su propia unidad y no equivalen a una cantidad de tabletas. El ranking no representa todo el catálogo.',
          ),
          ReportChartSpec(
            id: 'sales-branches',
            title: 'Ventas por sucursal',
            description: 'Hasta seis sucursales con mayor facturación neta.',
            type: ReportChartType.bars,
            currency: true,
            values: grouped([
              for (final s in valid)
                (
                  s.branchId,
                  s.branchId.isEmpty
                      ? 'Sin asignación histórica'
                      : s.branchName,
                  s.total,
                  '',
                ),
            ]),
            explanation:
                'Se usa la sucursal guardada al emitir cada factura. Cambiar la asignación de un empleado no traslada ventas anteriores. Las ventas antiguas sin identificador se muestran separadas.',
          ),
          ReportChartSpec(
            id: 'sales-registers',
            title: 'Ventas por caja de facturación',
            description: 'Hasta seis puestos por importe neto.',
            type: ReportChartType.bars,
            currency: true,
            values: grouped([
              for (final s in valid)
                (
                  '${s.branchId}|${s.registerId}',
                  s.registerId.isEmpty
                      ? 'Sin asignación histórica'
                      : '${s.branchName} · ${s.registerName}',
                  s.total,
                  '',
                ),
            ]),
            explanation:
                'Cada puesto conserva la sucursal y caja de emisión. No suma efectivo disponible ni requiere apertura de caja. Las cajas con el mismo nombre en sedes distintas se mantienen separadas.',
          ),
          ReportChartSpec(
            id: 'sales-operators',
            title: 'Ventas por operador',
            description: 'Hasta seis operadores por importe neto.',
            type: ReportChartType.bars,
            currency: true,
            values: grouped([
              for (final s in valid)
                (
                  s.actorId,
                  s.actorId.isEmpty
                      ? 'Sin identificador histórico'
                      : s.actorName,
                  s.total,
                  '',
                ),
            ]),
            explanation:
                'Se agrupa por ID del operador, no por su caja actual. Solo se incluyen facturas vigentes dentro de los filtros superiores; no es una evaluación laboral ni un reporte de horas.',
          ),
          ReportChartSpec(
            id: 'sales-state',
            title: 'Estado de las facturas',
            description: 'Cantidad de comprobantes, no su importe.',
            type: ReportChartType.donut,
            unit: 'Facturas',
            values: [
              ChartValue('valid', 'Vigentes', totals.count.toDouble()),
              ChartValue(
                'cancelled',
                'Anuladas',
                totals.cancelledCount.toDouble(),
              ),
            ],
            explanation:
                'La proporción se calcula por número de facturas del filtro. Una anulación conserva su comprobante, pero no suma a ventas netas. Si filtras solo anuladas, esta distribución también lo refleja.',
          ),
        ],
      );
    }
    if (kind == LocalReportKind.inventory) {
      var fresh = 0, soon = 0, expired = 0, inactive = 0;
      for (final lot in data.lots.where((l) => l.quantity > 0)) {
        if (data.productById(lot.productId)?.active != true ||
            !data.productEnabled(lot.branchId, lot.productId)) {
          inactive += lot.quantity;
        } else if (lot.isExpired(data.today)) {
          expired += lot.quantity;
        } else if (lot.isExpiring(data.today)) {
          soon += lot.quantity;
        } else {
          fresh += lot.quantity;
        }
      }
      final stock = data.inventory.where((s) => s.product.active).toList()
        ..sort(
          (a, b) => (a.availableQuantity - a.product.minimum).compareTo(
            b.availableQuantity - b.product.minimum,
          ),
        );
      return ReportVisuals(
        [
          ReportMetric(
            'Existencias físicas',
            '${data.stockTotal}',
            'Saldo actual de lotes, incluidos no vendibles.',
          ),
          ReportMetric(
            'Disponibles para vender',
            '${data.availableTotal}',
            'Productos activos y lotes no vencidos.',
          ),
          ReportMetric(
            'Productos bajo mínimo',
            '${data.lowStockCount}',
            'Disponibilidad menor o igual al mínimo.',
          ),
          ReportMetric(
            'Lotes por vencer',
            '${data.expiringCount}',
            'Con saldo y vencimiento en próximos 90 días.',
          ),
        ],
        [
          ReportChartSpec(
            id: 'stock-state',
            title: 'Estado de las existencias',
            description: 'Distribución del saldo físico actual.',
            type: ReportChartType.donut,
            unit: 'Unidades de venta',
            values: [
              ChartValue('fresh', 'Vigentes: más de 90 días', fresh.toDouble()),
              ChartValue('soon', 'Por vencer: hasta 90 días', soon.toDouble()),
              ChartValue('expired', 'Vencidas', expired.toDouble()),
              ChartValue(
                'inactive',
                'Producto archivado o no habilitado',
                inactive.toDouble(),
              ),
            ],
            explanation:
                'Cada unidad se cuenta una sola vez. Las archivadas/no habilitadas se separan primero, luego vencidas, próximas a vencer y vigentes. Es una foto actual: el filtro de fechas no reconstruye inventario pasado.',
          ),
          ReportChartSpec(
            id: 'stock-minimum',
            title: 'Disponibilidad frente al mínimo',
            description: 'Hasta seis productos con menor margen de stock.',
            type: ReportChartType.bars,
            unit: 'Unidades de venta',
            referenceLabel: 'Mínimo',
            values: [
              for (final s in stock.take(6))
                ChartValue(
                  s.product.id,
                  s.product.name,
                  s.availableQuantity.toDouble(),
                  unit: s.product.unit,
                  reference: s.product.minimum.toDouble(),
                ),
            ],
            explanation:
                'Azul: unidades disponibles. Naranja: mínimo registrado. Se priorizan los productos con menor disponibilidad menos mínimo. No es una orden automática de compra y no mezcla cajas con tabletas.',
          ),
        ],
      );
    }
    if (kind == LocalReportKind.purchases) {
      final orders = data.purchases
          .where((p) => includes(p.createdAt, start, end))
          .toList();
      final received = orders
          .where((p) => p.status == PurchaseStatus.received)
          .fold<double>(0, (n, p) => n + p.total);
      return ReportVisuals(
        [
          ReportMetric(
            'Órdenes del período',
            '${orders.length}',
            'Por fecha de creación, en la sucursal de consulta.',
          ),
          ReportMetric(
            'Órdenes recibidas',
            formatCordobas(received),
            'Valor de las órdenes recibidas; no es un flujo de pagos.',
          ),
        ],
        [
          ReportChartSpec(
            id: 'purchases-state',
            title: 'Estado de las compras',
            description: 'Cantidad de órdenes por estado actual.',
            type: ReportChartType.donut,
            unit: 'Órdenes',
            values: [
              for (final status in PurchaseStatus.values)
                ChartValue(
                  status.name,
                  switch (status) {
                    PurchaseStatus.pending => 'Pendientes',
                    PurchaseStatus.received => 'Recibidas',
                    PurchaseStatus.cancelled => 'Canceladas',
                  },
                  orders.where((p) => p.status == status).length.toDouble(),
                ),
            ],
            explanation:
                'Se consideran órdenes creadas en el período. Pendiente no significa mercancía recibida; cancelada no suma existencias. Los porcentajes se calculan por cantidad de órdenes.',
          ),
          ReportChartSpec(
            id: 'purchases-suppliers',
            title: 'Compras recibidas por proveedor',
            description:
                'Hasta seis proveedores por importe de órdenes recibidas.',
            type: ReportChartType.bars,
            currency: true,
            values: grouped([
              for (final p in orders.where(
                (p) => p.status == PurchaseStatus.received,
              ))
                (p.supplierId, p.supplierName, p.total, ''),
            ]),
            explanation:
                'Solo órdenes recibidas de esta sucursal creadas en el período. El importe expresa compras documentadas, no pagos efectivamente realizados ni deuda pendiente.',
          ),
        ],
      );
    }
    final events = switch (kind) {
      LocalReportKind.audit => [for (final e in data.audit) (e.at, 1.0)],
      LocalReportKind.movements => [
        for (final e in data.movements) (e.at, 1.0),
      ],
      LocalReportKind.incidents => [
        for (final e in data.incidents) (e.createdAt, 1.0),
      ],
      LocalReportKind.cash => [
        for (final e in data.cashSessions) (e.openedAt, 1.0),
      ],
      _ => <(DateTime, double)>[],
    };
    final count = events.where((e) => includes(e.$1, start, end)).length;
    return ReportVisuals(
      [
        ReportMetric(
          'Registros del período',
          '$count',
          'Cada evento se cuenta una sola vez por su fecha de creación.',
        ),
      ],
      [
        ReportChartSpec(
          id: 'activity-${kind.name}',
          title: 'Actividad en el período',
          description: 'Cantidad de registros por intervalo.',
          type: ReportChartType.line,
          values: timeline(events, start, end),
          explanation:
              'Cuenta registros del tipo seleccionado. No suma importes ni unidades movidas. Caja conserva solo su historial anterior y soporte se cuenta por fecha de creación.',
        ),
      ],
    );
  }
}
