import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../shared/widgets/workspace_sections.dart';
import '../../reports/models/sales_analytics.dart';
import '../../sales/models/sale_receipt.dart';
import '../../sales/widgets/receipt_dialog.dart';

/// Consulta de productividad: una fila por caja. El detalle tiene su propia
/// ubicación; editar puestos y permisos sigue centralizado en Personal.
class RegistersPage extends StatefulWidget {
  const RegistersPage({
    required this.controller,
    this.onManage,
    this.registerId,
    this.onOpen,
    this.onBack,
    this.start,
    this.end,
    super.key,
  });
  final PharmacyController controller;
  final VoidCallback? onManage, onBack;
  final String? registerId;
  final void Function(String id, DateTime start, DateTime end)? onOpen;
  final DateTime? start, end;
  @override
  State<RegistersPage> createState() => _RegistersPageState();
}

class _RegistersPageState extends State<RegistersPage> {
  late DateTime _start, _end;
  String _branch = '*', _query = '', _detailQuery = '';
  String? _localId;
  int _detailTab = 0;
  final _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    _end = widget.controller.today;
    _start = DateTime(_end.year, _end.month, 1);
    final start = widget.start, end = widget.end;
    if (start != null &&
        end != null &&
        !start.isBefore(DateTime(2000)) &&
        !end.isAfter(DateTime(_end.year + 5, 12, 31)) &&
        !end.isBefore(start)) {
      _start = start;
      _end = end;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _dates() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(widget.controller.today.year + 5, 12, 31),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (range != null && mounted) {
      setState(() {
        _start = range.start;
        _end = range.end;
      });
    }
  }

  void _open(String id) {
    _detailQuery = '';
    _detailTab = 0;
    if (widget.onOpen != null) {
      widget.onOpen!(id, _start, _end);
    } else {
      setState(() => _localId = id);
    }
  }

  void _back() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      setState(() => _localId = null);
    }
  }

  Widget get _period => OutlinedButton.icon(
    onPressed: _dates,
    icon: const Icon(Icons.date_range, size: 17),
    label: Text('${formatDate(_start)} — ${formatDate(_end)}'),
  );
  List<SaleReceipt> _sales(String id) =>
      SalesReportFilter(registerId: id).apply(widget.controller, _start, _end);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final data = widget.controller;
      final id = widget.registerId ?? _localId;
      if (id != null) {
        return _detail(id);
      }
      final registers = data.registers
          .where(
            (r) =>
                (_branch == '*' || r.branchId == _branch) &&
                '${r.name} ${data.branchById(r.branchId)?.name} ${data.operatorFor(r.id)?.name}'
                    .toLowerCase()
                    .contains(_query),
          )
          .toList();
      return CompactWorkspace(
        title: 'Cajas de facturación',
        subtitle:
            'Ventas por puesto y operador durante el período seleccionado.',
        actions: [
          _period,
          if (data.isAdministrator && widget.onManage != null)
            OutlinedButton.icon(
              onPressed: widget.onManage,
              icon: const Icon(Icons.manage_accounts_outlined, size: 17),
              label: const Text('Personal y asignaciones'),
            ),
        ],
        toolbar: RecordToolbar(
          search: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar caja, sucursal u operador',
            ),
          ),
          filters: [
            if (data.isAdministrator)
              DropdownButtonFormField<String>(
                initialValue: _branch,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Sucursal',
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: '*', child: Text('Todas')),
                  for (final b in data.branches)
                    DropdownMenuItem(
                      value: b.id,
                      child: Text(b.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _branch = v ?? '*'),
              ),
          ],
        ),
        child: CompactRecords(
          resetKey: (_branch, _query, _start, _end),
          itemCount: registers.length,
          minimumTableWidth: 1000,
          emptyText: 'No hay cajas asignadas o registradas para este filtro.',
          columns: const [
            RecordColumn('Caja'),
            RecordColumn('Sucursal', flex: 1.5),
            RecordColumn('Operador actual', flex: 1.5),
            RecordColumn('Estado'),
            RecordColumn('Facturas'),
            RecordColumn('Ventas netas'),
            RecordColumn(''),
          ],
          rowBuilder: (i) {
            final r = registers[i], t = SalesTotals(_sales(registers[i].id));
            final operator = data.operatorFor(r.id)?.name ?? 'Sin asignar';
            final branch = data.branchById(r.branchId)?.name ?? 'Sin sucursal';
            final status = StatusPill(
              text: r.active ? 'Activa' : 'Inactiva',
              color: r.active ? context.palette.blue : context.palette.muted,
            );
            final open = IconButton(
              key: Key('register-open-${r.id}'),
              tooltip: 'Ver ventas y productos',
              onPressed: () => _open(r.id),
              icon: const Icon(Icons.arrow_forward, size: 18),
            );
            return RecordRow(
              onOpen: () => _open(r.id),
              cells: [
                RecordText(r.name, bold: true),
                RecordText(branch),
                RecordText(operator),
                status,
                RecordText('${t.count}'),
                RecordText(formatCordobas(t.net), bold: true),
                open,
              ],
              mobile: RecordTile(
                title: '${r.name} · $branch',
                subtitle: 'Operador actual: $operator',
                metadata:
                    '${t.count} facturas · ${formatCordobas(t.net)} · ${r.active ? 'Activa' : 'Inactiva'}',
                trailing: open,
                onOpen: () => _open(r.id),
              ),
            );
          },
        ),
      );
    },
  );

  /// Solo se resuelve entre las cajas autorizadas, incluso con un enlace escrito
  /// a mano. El historial mantiene al operador que emitió cada comprobante.
  Widget _detail(String id) {
    final data = widget.controller;
    final register = data.registers.where((r) => r.id == id).firstOrNull;
    final back = TextButton.icon(
      onPressed: _back,
      icon: const Icon(Icons.arrow_back, size: 17),
      label: const Text('Volver al listado'),
    );
    if (register == null) {
      return CompactWorkspace(
        title: 'Caja no disponible',
        actions: [back],
        child: const Text('No tienes acceso a esta caja.'),
      );
    }
    final sales = _sales(id);
    final totals = SalesTotals(sales);
    final branch = data.branchById(register.branchId)?.name ?? 'Sin sucursal';
    final rows = sales
        .where(
          (s) => '${s.id} ${s.customerName} ${s.actorName}'
              .toLowerCase()
              .contains(_detailQuery),
        )
        .toList();
    // Agrupa por producto y unidad histórica. Nunca cuenta unidades anuladas.
    final products = <String, (String, String, int, double)>{};
    for (final sale in sales.where((s) => !s.cancelled)) {
      for (final line in sale.lines) {
        final key = '${line.productId}|${line.unit}';
        final old = products[key];
        products[key] = (
          line.name,
          line.unit,
          (old?.$3 ?? 0) + line.quantity,
          (old?.$4 ?? 0) + line.total,
        );
      }
    }
    final lines =
        products.values
            .where((p) => p.$1.toLowerCase().contains(_detailQuery))
            .toList()
          ..sort((a, b) => b.$4.compareTo(a.$4));
    return CompactWorkspace(
      title: '${register.name} · $branch',
      subtitle:
          'Operador actual: ${data.operatorFor(id)?.name ?? 'Sin asignar'}',
      actions: [back, _period],
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SummaryStrip(
            values: [
              ('Ventas netas', formatCordobas(totals.net)),
              ('Facturas vigentes', '${totals.count}'),
              ('Unidades', '${totals.units}'),
              ('Ticket promedio', formatCordobas(totals.average)),
              ('Anuladas', '${totals.cancelledCount}'),
            ],
          ),
          const SizedBox(height: 16),
          WorkspaceTabs(
            labels: const ['Facturas', 'Productos vendidos', 'Medios de pago'],
            selected: _detailTab,
            onSelected: (v) => setState(() {
              _detailTab = v;
              _detailQuery = '';
            }),
          ),
          if (_detailTab < 2)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextField(
                key: ValueKey('register-detail-search-$_detailTab'),
                onChanged: (v) =>
                    setState(() => _detailQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: _detailTab == 0
                      ? 'Buscar factura, cliente u operador'
                      : 'Buscar producto',
                ),
              ),
            ),
        ],
      ),
      child: _detailTab == 0
          ? CompactRecords(
              resetKey: (id, _start, _end, _detailTab, _detailQuery),
              itemCount: rows.length,
              columns: const [
                RecordColumn('Factura'),
                RecordColumn('Fecha'),
                RecordColumn('Cliente', flex: 1.5),
                RecordColumn('Operador', flex: 1.5),
                RecordColumn('Total'),
                RecordColumn('Estado'),
                RecordColumn(''),
              ],
              rowBuilder: (i) {
                final s = rows[i];
                final open = IconButton(
                  tooltip: 'Ver comprobante',
                  onPressed: () => showReceipt(context, s, controller: data),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                );
                return RecordRow(
                  onOpen: () => showReceipt(context, s, controller: data),
                  cells: [
                    RecordText(s.id, bold: true),
                    RecordText(formatDate(s.createdAt)),
                    RecordText(s.customerName),
                    RecordText(s.actorName),
                    RecordText(formatCordobas(s.total), bold: true),
                    RecordText(s.cancelled ? 'Anulada' : 'Vigente'),
                    open,
                  ],
                  mobile: RecordTile(
                    title: '${s.id} · ${formatCordobas(s.total)}',
                    subtitle: '${s.customerName} · ${s.actorName}',
                    metadata:
                        '${formatDate(s.createdAt)} · ${s.cancelled ? 'Anulada' : s.method.label}',
                    trailing: open,
                  ),
                );
              },
            )
          : _detailTab == 1
          ? CompactRecords(
              resetKey: (id, _start, _end, _detailTab, _detailQuery),
              itemCount: lines.length,
              columns: const [
                RecordColumn('Producto', flex: 2),
                RecordColumn('Unidad'),
                RecordColumn('Cantidad vendida'),
                RecordColumn('Importe neto'),
              ],
              rowBuilder: (i) {
                final p = lines[i];
                return RecordRow(
                  cells: [
                    RecordText(p.$1, bold: true),
                    RecordText(p.$2),
                    RecordText('${p.$3}'),
                    RecordText(formatCordobas(p.$4), bold: true),
                  ],
                  mobile: RecordTile(
                    title: p.$1,
                    subtitle: '${p.$3} ${p.$2}',
                    metadata: formatCordobas(p.$4),
                  ),
                );
              },
            )
          : CompactRecords(
              resetKey: (id, _start, _end, _detailTab),
              itemCount: PaymentMethod.values.length,
              columns: const [
                RecordColumn('Medio de pago', flex: 2),
                RecordColumn('Facturas vigentes'),
                RecordColumn('Importe neto'),
              ],
              rowBuilder: (i) {
                final m = PaymentMethod.values[i];
                final count = sales
                    .where((s) => !s.cancelled && s.method == m)
                    .length;
                return RecordRow(
                  cells: [
                    RecordText(m.label),
                    RecordText('$count'),
                    RecordText(formatCordobas(totals.byMethod(m)), bold: true),
                  ],
                  mobile: RecordTile(
                    title: m.label,
                    subtitle: '$count facturas vigentes',
                    metadata: formatCordobas(totals.byMethod(m)),
                  ),
                );
              },
            ),
    );
  }
}
