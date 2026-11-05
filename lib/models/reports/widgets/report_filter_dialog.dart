import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/form_dialog.dart';
import '../models/sales_analytics.dart';
import 'sales_filters.dart';

typedef ReportFilterSelection = ({
  DateTime start,
  DateTime end,
  SalesReportFilter filter,
});

/// Los filtros se preparan y se aplican juntos, sin ocupar el panel de gráficos.
class ReportFilterDialog extends StatefulWidget {
  const ReportFilterDialog({
    required this.controller,
    required this.initial,
    required this.sales,
    required this.inventory,
    super.key,
  });
  final PharmacyController controller;
  final ReportFilterSelection initial;
  final bool sales, inventory;
  @override
  State<ReportFilterDialog> createState() => _ReportFilterDialogState();
}

class _ReportFilterDialogState extends State<ReportFilterDialog> {
  late DateTime _start = widget.initial.start, _end = widget.initial.end;
  late SalesReportFilter _filter = widget.initial.filter;
  Future<void> _dates() async {
    final value = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(widget.controller.today.year + 5, 12, 31),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (value != null && mounted) {
      setState(() {
        _start = value.start;
        _end = value.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) => FormDialog(
    title: 'Filtros del reporte',
    description: 'Se aplican a indicadores, gráfico, detalle y exportación.',
    actions: [
      if (widget.sales)
        TextButton(
          onPressed: () => setState(() => _filter = const SalesReportFilter()),
          child: const Text('Restablecer filtros de ventas'),
        ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () =>
            Navigator.pop(context, (start: _start, end: _end, filter: _filter)),
        child: const Text('Aplicar filtros'),
      ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.inventory) ...[
          OutlinedButton.icon(
            onPressed: _dates,
            icon: const Icon(Icons.date_range),
            label: Text('${formatDate(_start)} — ${formatDate(_end)}'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: [
              for (final preset in [
                (1, 'Hoy'),
                (7, '7 días'),
                (30, '30 días'),
                (0, 'Este mes'),
              ])
                TextButton(
                  onPressed: () => setState(() {
                    final now = widget.controller.today;
                    _end = now;
                    _start = preset.$1 == 0
                        ? DateTime(now.year, now.month, 1)
                        : DateTime(
                            now.year,
                            now.month,
                            now.day - preset.$1 + 1,
                          );
                  }),
                  child: Text(preset.$2),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (widget.sales)
          SalesFilters(
            controller: widget.controller,
            value: _filter,
            onChanged: (v) => setState(() => _filter = v),
          ),
        const SizedBox(height: 16),
      ],
    ),
  );
}
