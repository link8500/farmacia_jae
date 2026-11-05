import 'package:flutter/material.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/section_card.dart';
import '../models/local_report.dart';

/// Tabla paginada en escritorio y detalles plegables en móvil. El límite de
/// filas es de la vista; la exportación sigue recibiendo TODAS las coincidencias.
class ReportResults extends StatelessWidget {
  const ReportResults({
    required this.report,
    required this.rows,
    required this.page,
    required this.onPage,
    super.key,
  });
  final LocalReport report;
  final List<List<Object?>> rows;
  final int page;
  final ValueChanged<int> onPage;
  static String text(Object? value) =>
      value is double ? value.toStringAsFixed(2) : value?.toString() ?? '—';
  @override
  Widget build(BuildContext context) {
    final pages = (rows.length / 20).ceil().clamp(1, 1000000),
        selected = page.clamp(
          0,
          (rows.length / 20).ceil().clamp(1, 1000000) - 1,
        );
    final visible = rows.skip(selected * 20).take(20).toList();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${report.title} · ${rows.length} resultados',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Importes monetarios en C\$. Desliza la tabla para consultar todas las columnas.',
            style: TextStyle(color: context.palette.muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No hay registros en este período o búsqueda.'),
            )
          else
            LayoutBuilder(
              builder: (context, box) {
                if (box.maxWidth >= 800 &&
                    MediaQuery.textScalerOf(context).scale(1) <= 1.3) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowColor: WidgetStatePropertyAll(
                        context.palette.canvas,
                      ),
                      dataRowMinHeight: 52,
                      dataRowMaxHeight: 78,
                      columns: [
                        for (final header in report.headers)
                          DataColumn(
                            label: Text(
                              header,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                      rows: [
                        for (final row in visible)
                          DataRow(
                            cells: [
                              for (var i = 0; i < report.headers.length; i++)
                                DataCell(
                                  Tooltip(
                                    message: text(row[i]),
                                    child: SizedBox(
                                      width: i == 0 ? 160 : 145,
                                      child: Text(
                                        text(row[i]),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final row in visible)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(
                          text(row.first),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: row.length < 2
                            ? null
                            : Text(
                                '${report.headers[1]}: ${text(row[1])}',
                                style: TextStyle(
                                  color: context.palette.muted,
                                  fontSize: 12,
                                ),
                              ),
                        children: [
                          for (var i = 1; i < report.headers.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: SelectableText(
                                  '${report.headers[i]}: ${text(row[i])}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            spacing: 8,
            children: [
              Text(
                'Página ${selected + 1} de $pages',
                style: TextStyle(color: context.palette.muted, fontSize: 12),
              ),
              Wrap(
                children: [
                  TextButton(
                    onPressed: selected > 0 ? () => onPage(selected - 1) : null,
                    child: const Text('Anterior'),
                  ),
                  TextButton(
                    onPressed: selected + 1 < pages
                        ? () => onPage(selected + 1)
                        : null,
                    child: const Text('Siguiente'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
