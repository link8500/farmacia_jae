import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../themes/app_palette.dart';

/// Marco de listas: cabecera y filtros breves, área de trabajo acotada al alto
/// disponible. El scroll pertenece al listado, no a una página de fichas largas.
class CompactWorkspace extends StatelessWidget {
  const CompactWorkspace({
    required this.title,
    required this.child,
    this.subtitle = '',
    this.actions = const [],
    this.toolbar,
    super.key,
  });
  final String title, subtitle;
  final List<Widget> actions;
  final Widget? toolbar;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 24),
    child: LayoutBuilder(
      builder: (context, box) {
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (_, header) {
                final heading = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.muted,
                        ),
                      ),
                    ],
                  ],
                );
                final buttons = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: actions,
                );
                return header.maxWidth >= 760 &&
                        MediaQuery.textScalerOf(context).scale(1) < 1.4
                    ? Row(
                        children: [
                          Expanded(child: heading),
                          const SizedBox(width: 16),
                          buttons,
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          heading,
                          if (actions.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            buttons,
                          ],
                        ],
                      );
              },
            ),
            if (toolbar != null) ...[const SizedBox(height: 16), toolbar!],
            const SizedBox(height: 14),
          ],
        );
        // El encabezado se mide antes de reservar el área del listado. Con
        // texto ampliado o una ventana baja, el conjunto puede desplazarse sin
        // comprimir controles ni provocar desbordamientos de Column.
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: heading),
            SliverLayoutBuilder(
              builder: (context, sliver) => SliverToBoxAdapter(
                child: SizedBox(
                  height: math.max(
                    320,
                    sliver.viewportMainAxisExtent -
                        sliver.precedingScrollExtent,
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class RecordColumn {
  const RecordColumn(this.label, {this.flex = 1});
  final String label;
  final double flex;
}

class RecordRow {
  const RecordRow({required this.cells, required this.mobile, this.onOpen});
  final List<Widget> cells;
  final Widget mobile;
  final VoidCallback? onOpen;
}

/// Tabla paginada reutilizable. En móvil conserva filas planas de altura
/// natural. Búsquedas y filtros reinician la página mediante resetKey.
class CompactRecords extends StatefulWidget {
  const CompactRecords({
    required this.columns,
    required this.itemCount,
    required this.rowBuilder,
    required this.resetKey,
    this.emptyText = 'No hay resultados.',
    this.pageSize = 8,
    this.minimumTableWidth = 720,
    super.key,
  });
  final List<RecordColumn> columns;
  final int itemCount, pageSize;
  final RecordRow Function(int index) rowBuilder;
  final Object resetKey;
  final String emptyText;
  final double minimumTableWidth;
  @override
  State<CompactRecords> createState() => _CompactRecordsState();
}

class _CompactRecordsState extends State<CompactRecords> {
  int _page = 0;
  @override
  void didUpdateWidget(covariant CompactRecords oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetKey != widget.resetKey) _page = 0;
    _page = _page.clamp(
      0,
      (widget.itemCount / widget.pageSize).ceil().clamp(1, 100000) - 1,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, area) {
      // En escritorio la página se ajusta al alto: el pie no oculta filas y no
      // obliga a recorrer una segunda barra de scroll para llegar a las acciones.
      final desktop =
          area.maxWidth >= 680 &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.3;
      final pageSize = desktop
          ? math.min(
              widget.pageSize,
              math.max(1, ((area.maxHeight - 104) / 52).floor()),
            )
          : widget.pageSize;
      final pages = (widget.itemCount / pageSize).ceil().clamp(1, 100000);
      _page = _page.clamp(0, pages - 1);
      final from = _page * pageSize;
      final end = math.min(from + pageSize, widget.itemCount);
      final rows = [for (var i = from; i < end; i++) widget.rowBuilder(i)];
      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: area.maxWidth,
          height: desktop
              ? math.min(area.maxHeight, math.max(180, 104 + rows.length * 52))
              : area.maxHeight,
          child: Container(
            decoration: BoxDecoration(
              color: context.palette.surface,
              border: Border.all(color: context.palette.border),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: widget.itemCount == 0
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              widget.emptyText,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, box) {
                            if (box.maxWidth < 680 ||
                                MediaQuery.textScalerOf(context).scale(1) >
                                    1.3) {
                              return ListView.separated(
                                key: const Key('compact-record-list'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                itemCount: rows.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: 1,
                                  color: context.palette.border,
                                ),
                                itemBuilder: (_, index) => rows[index].mobile,
                              );
                            }
                            final width = math.max(
                              box.maxWidth,
                              widget.minimumTableWidth,
                            );
                            final sum = widget.columns.fold<double>(
                              0,
                              (n, c) => n + c.flex,
                            );
                            final available =
                                width - 32 - 16 * (widget.columns.length - 1);
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: width,
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    showCheckboxColumn: false,
                                    horizontalMargin: 16,
                                    columnSpacing: 16,
                                    headingRowHeight: 40,
                                    dataRowMinHeight: 52,
                                    dataRowMaxHeight: 52,
                                    headingRowColor: WidgetStatePropertyAll(
                                      context.palette.canvas,
                                    ),
                                    dividerThickness: .6,
                                    columns: [
                                      for (final column in widget.columns)
                                        DataColumn(
                                          label: SizedBox(
                                            width:
                                                available * column.flex / sum,
                                            child: Text(
                                              column.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: context.palette.muted,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                    rows: [
                                      for (final row in rows)
                                        DataRow(
                                          onSelectChanged: row.onOpen == null
                                              ? null
                                              : (_) => row.onOpen!(),
                                          cells: [
                                            for (
                                              var i = 0;
                                              i < row.cells.length;
                                              i++
                                            )
                                              DataCell(
                                                SizedBox(
                                                  width:
                                                      available *
                                                      widget.columns[i].flex /
                                                      sum,
                                                  child: row.cells[i],
                                                ),
                                              ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Divider(height: 1, color: context.palette.border),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        widget.itemCount == 0
                            ? '0 resultados'
                            : '${from + 1}–$end de ${widget.itemCount}',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.palette.muted,
                        ),
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Página anterior',
                            onPressed: _page > 0
                                ? () => setState(() => _page--)
                                : null,
                            icon: const Icon(Icons.chevron_left, size: 20),
                          ),
                          Text(
                            '${_page + 1} / $pages',
                            style: const TextStyle(fontSize: 11),
                          ),
                          IconButton(
                            tooltip: 'Página siguiente',
                            onPressed: _page + 1 < pages
                                ? () => setState(() => _page++)
                                : null,
                            icon: const Icon(Icons.chevron_right, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Identificación de una fila: en escritorio la misma pieza cabe en una celda.
class RecordIdentity extends StatelessWidget {
  const RecordIdentity({
    required this.title,
    this.subtitle = '',
    this.leading,
    super.key,
  });
  final String title, subtitle;
  final Widget? leading;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (leading != null) ...[leading!, const SizedBox(width: 10)],
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecordText(title, bold: true),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 3),
              RecordText(subtitle, muted: true),
            ],
          ],
        ),
      ),
    ],
  );
}

class RecordText extends StatelessWidget {
  const RecordText(
    this.text, {
    this.bold = false,
    this.muted = false,
    super.key,
  });
  final String text;
  final bool bold, muted;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: text,
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: muted ? context.palette.muted : context.palette.ink,
      ),
    ),
  );
}

class RecordTile extends StatelessWidget {
  const RecordTile({
    required this.title,
    this.subtitle = '',
    this.metadata = '',
    this.leading,
    this.trailing,
    this.onOpen,
    super.key,
  });
  final String title, subtitle, metadata;
  final Widget? leading, trailing;
  final VoidCallback? onOpen;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onOpen,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.palette.muted,
                      ),
                    ),
                  ),
                if (metadata.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      metadata,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.palette.blue,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 4), trailing!],
        ],
      ),
    ),
  );
}

class RecordActions extends StatelessWidget {
  const RecordActions({required this.actions, this.recordKey, super.key});
  final List<(String label, VoidCallback action)> actions;
  final String? recordKey;
  @override
  Widget build(BuildContext context) => PopupMenuButton<int>(
    key: recordKey == null ? null : Key(recordKey!),
    tooltip: 'Acciones del registro',
    icon: const Icon(Icons.more_horiz, size: 20),
    onSelected: (i) => actions[i].$2(),
    itemBuilder: (_) => [
      for (var i = 0; i < actions.length; i++)
        PopupMenuItem(value: i, child: Text(actions[i].$1)),
    ],
  );
}

/// Búsqueda y filtros alineados en una sola barra, con ajuste natural en móvil.
class RecordToolbar extends StatelessWidget {
  const RecordToolbar({
    required this.search,
    this.filters = const [],
    super.key,
  });
  final Widget search;
  final List<Widget> filters;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, box) => Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: box.maxWidth < 600
              ? box.maxWidth
              : math.max(240, box.maxWidth - filters.length * 180),
          child: search,
        ),
        for (final filter in filters)
          SizedBox(
            width: box.maxWidth < 380 ? box.maxWidth : 170,
            child: filter,
          ),
      ],
    ),
  );
}

class RecordFilter extends StatelessWidget {
  const RecordFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });
  final String label, value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    key: ValueKey('$label-$value'),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label, isDense: true),
    items: [
      for (final option in options)
        DropdownMenuItem(
          value: option,
          child: Text(
            option,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
    ],
    onChanged: (next) {
      if (next != null) onChanged(next);
    },
  );
}
