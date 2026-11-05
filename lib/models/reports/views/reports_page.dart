import 'package:flutter/material.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/services/local_files.dart';
import '../../../core/utils/csv.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../../../shared/widgets/form_dialog.dart';
import '../../../shared/widgets/record_form_dialog.dart';
import '../models/local_report.dart';
import '../models/report_visuals.dart';
import '../models/sales_analytics.dart';
import '../widgets/report_chart_card.dart';
import '../widgets/report_metrics.dart';
import '../widgets/report_filter_dialog.dart';

/// Un gráfico por vez y una vista separada de detalle. Los filtros y el CSV
/// conservan el mismo conjunto completo de datos, sin depender de la paginación.
class ReportsPage extends StatefulWidget {
  const ReportsPage({
    required this.controller,
    this.detailsView = false,
    this.onView,
    super.key,
  });
  final PharmacyController controller;
  final bool detailsView;
  final ValueChanged<bool>? onView;
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  LocalReportKind _kind = LocalReportKind.sales;
  late DateTime _start, _end;
  late bool _details;
  int _chart = 0;
  final _search = TextEditingController();
  SalesReportFilter _filter = const SalesReportFilter();
  static const _options = [
    (LocalReportKind.sales, 'Ventas'),
    (LocalReportKind.salesDetails, 'Productos vendidos'),
    (LocalReportKind.salesByOperator, 'Ventas por puesto y operador'),
    (LocalReportKind.inventory, 'Inventario'),
    (LocalReportKind.purchases, 'Compras'),
    (LocalReportKind.cash, 'Historial de caja'),
    (LocalReportKind.audit, 'Auditoría'),
    (LocalReportKind.movements, 'Movimientos de inventario'),
    (LocalReportKind.incidents, 'Soporte'),
  ];
  @override
  void initState() {
    super.initState();
    _end = widget.controller.today;
    _start = DateTime(_end.year, _end.month, 1);
    _details = widget.detailsView;
  }

  @override
  void didUpdateWidget(covariant ReportsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detailsView != widget.detailsView) {
      _details = widget.detailsView;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _view(bool value) {
    if (widget.onView != null) {
      widget.onView!(value);
    } else {
      setState(() => _details = value);
    }
  }

  Future<void> _filters() async {
    final next = await showDialog<ReportFilterSelection>(
      context: context,
      builder: (_) => ReportFilterDialog(
        controller: widget.controller,
        initial: (start: _start, end: _end, filter: _filter),
        sales: ReportVisuals.isSales(_kind),
        inventory: _kind == LocalReportKind.inventory,
      ),
    );
    if (next != null && mounted) {
      setState(() {
        _start = next.start;
        _end = next.end;
        _filter = next.filter;
      });
    }
  }

  Future<void> _dates() async {
    final next = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(widget.controller.today.year + 5, 12, 31),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (next != null && mounted) {
      setState(() {
        _start = next.start;
        _end = next.end;
      });
    }
  }

  String _text(Object? value) =>
      value is double ? value.toStringAsFixed(2) : value?.toString() ?? '—';
  String _cell(String label, Object? value) =>
      value is num &&
          const {
            'Total',
            'Subtotal',
            'Precio unitario',
            'Costo unitario',
            'Valor',
            'Ventas netas',
            'Importe anulado',
            'Ticket promedio',
            'Efectivo',
            'Tarjeta',
            'Transferencia',
            'Esperado',
            'Contado',
            'Diferencia',
          }.contains(label)
      ? formatCordobas(value.toDouble())
      : _text(value);
  void _record(LocalReport report, List<Object?> row) => showDialog<void>(
    context: context,
    builder: (dialogContext) => FormDialog(
      title: _text(row.first),
      description: report.title,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cerrar'),
        ),
      ],
      child: FormFieldsGrid(
        fields: [
          for (var i = 0; i < report.headers.length; i++)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.headers[i],
                  style: TextStyle(fontSize: 11, color: context.palette.muted),
                ),
                const SizedBox(height: 5),
                SelectableText(
                  _cell(report.headers[i], row[i]),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final data = widget.controller;
      final report = LocalReportBuilder.build(
        data,
        _kind,
        _start,
        _end,
        filter: _filter,
      );
      final visuals = ReportVisuals.build(
        data,
        _kind,
        _start,
        _end,
        filter: _filter,
      );
      final query = _search.text.trim().toLowerCase();
      final rows = report.rows
          .where(
            (row) => row.any((v) => _text(v).toLowerCase().contains(query)),
          )
          .toList();
      final selected = _chart.clamp(0, visuals.charts.length - 1);
      // Priorizar campos operativos: compactar nunca debe esconder el total
      // de una venta detrás de las columnas técnicas de la exportación.
      final columns = switch (_kind) {
        LocalReportKind.sales => [0, 1, 7, 3, 10, 11],
        LocalReportKind.salesDetails => [0, 5, 7, 8, 9, 11],
        LocalReportKind.salesByOperator => [0, 1, 2, 4, 7, 9],
        LocalReportKind.inventory => [0, 2, 3, 5, 6, 7],
        LocalReportKind.purchases => [0, 2, 3, 4, 5, 6],
        LocalReportKind.cash => [0, 1, 2, 3, 5, 6],
        LocalReportKind.movements => [0, 2, 3, 4, 5, 6],
        LocalReportKind.incidents => [0, 1, 2, 3, 4, 5],
        LocalReportKind.audit => [0, 1, 2, 3],
      };
      return CompactWorkspace(
        title: 'Reportes y análisis',
        subtitle: _kind == LocalReportKind.inventory
            ? 'Inventario actual · ${data.workingBranch?.name ?? ''}'
            : '${formatDate(_start)} — ${formatDate(_end)}',
        actions: [
          OutlinedButton.icon(
            key: const Key('report-filters'),
            onPressed: _filters,
            icon: const Icon(Icons.filter_alt_outlined, size: 17),
            label: const Text('Filtros'),
          ),
          FilledButton.icon(
            key: const Key('report-export'),
            onPressed: () {
              if (!downloadText(
                'farmacia-jae-${_kind.name}.csv',
                buildCsv(report.headers, rows),
                type: 'text/csv;charset=utf-8',
              )) {
                showCommandResult(
                  context,
                  'La descarga CSV está disponible en web.',
                );
              }
            },
            icon: const Icon(Icons.download_outlined, size: 17),
            label: const Text('Exportar CSV'),
          ),
        ],
        toolbar: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 250,
              child: DropdownButtonFormField<LocalReportKind>(
                key: const Key('report-kind'),
                initialValue: _kind,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Reporte',
                  isDense: true,
                ),
                items: [
                  for (final o in _options)
                    DropdownMenuItem(
                      value: o.$1,
                      child: Text(
                        o.$2,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _kind = v;
                      _chart = 0;
                      _search.clear();
                    });
                  }
                },
              ),
            ),
            OutlinedButton.icon(
              key: const Key('report-dates'),
              onPressed: _kind == LocalReportKind.inventory ? null : _dates,
              icon: const Icon(Icons.date_range_outlined, size: 17),
              label: const Text('Período'),
            ),
            ChoiceChip(
              label: const Text('Gráficos'),
              selected: !_details,
              onSelected: (_) => _view(false),
            ),
            ChoiceChip(
              key: const Key('report-detail-view'),
              label: const Text('Detalle de registros'),
              selected: _details,
              onSelected: (_) => _view(true),
            ),
          ],
        ),
        child: _details
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const Key('report-search'),
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Buscar solo en el detalle',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'La búsqueda filtra el detalle y el CSV. Abre una fila para consultar todos sus campos.',
                    style: TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: CompactRecords(
                      itemCount: rows.length,
                      resetKey: '$_kind|$_start|$_end|$_filter|$query',
                      emptyText: 'No hay registros en este período o búsqueda.',
                      columns: [
                        for (final index in columns)
                          RecordColumn(
                            report.headers[index],
                            flex: index == 0 ? 2 : 1,
                          ),
                        const RecordColumn('', flex: .5),
                      ],
                      rowBuilder: (i) => RecordRow(
                        onOpen: () => _record(report, rows[i]),
                        cells: [
                          for (final index in columns)
                            RecordText(
                              _cell(report.headers[index], rows[i][index]),
                              bold: index == 0,
                            ),
                          IconButton(
                            tooltip: 'Ver registro completo',
                            onPressed: () => _record(report, rows[i]),
                            icon: const Icon(Icons.open_in_new, size: 17),
                          ),
                        ],
                        mobile: RecordTile(
                          title: _text(rows[i].first),
                          subtitle:
                              '${report.headers[columns[1]]}: ${_text(rows[i][columns[1]])}',
                          metadata: _kind == LocalReportKind.audit
                              ? ''
                              : '${report.headers[columns[4]]}: ${_cell(report.headers[columns[4]], rows[i][columns[4]])} · ${_cell(report.headers[columns.last], rows[i][columns.last])}',
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onOpen: () => _record(report, rows[i]),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ReportMetrics(values: visuals.metrics, compact: true),
                    const SizedBox(height: 12),
                    RecordFilter(
                      key: const Key('report-chart-select'),
                      label: 'Gráfico',
                      value: visuals.charts[selected].title,
                      options: visuals.charts.map((s) => s.title).toList(),
                      onChanged: (title) => setState(
                        () => _chart = visuals.charts.indexWhere(
                          (s) => s.title == title,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ReportChartCard(
                      key: ValueKey(visuals.charts[selected].id),
                      spec: visuals.charts[selected],
                      compact: true,
                    ),
                  ],
                ),
              ),
      );
    },
  );
}
