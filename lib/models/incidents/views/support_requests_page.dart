import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../../../shared/widgets/record_detail.dart';
import '../../../shared/widgets/workspace_sections.dart';
import '../../../shared/widgets/record_form_dialog.dart';
import '../models/support_case.dart';

/// Registro, prioridad, seguimiento y cierre con una solución obligatoria.
class SupportRequestsPage extends StatefulWidget {
  const SupportRequestsPage({
    required this.controller,
    this.recordId,
    this.onOpen,
    this.onBack,
    super.key,
  });
  final String? recordId;
  final ValueChanged<String>? onOpen;
  final VoidCallback? onBack;
  final PharmacyController controller;
  @override
  State<SupportRequestsPage> createState() => _SupportRequestsPageState();
}

class _SupportRequestsPageState extends State<SupportRequestsPage> {
  String _query = '', _filter = 'Todos';
  String? _localId;
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(String id) {
    if (widget.onOpen != null) {
      widget.onOpen!(id);
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

  String _status(SupportCase i) => switch (i.status) {
    IncidentStatus.open => 'Abierto',
    IncidentStatus.inProgress => 'En atención',
    IncidentStatus.resolved => 'Resuelto',
  };
  void _edit(SupportCase record) => showDialog<bool>(
    context: context,
    builder: (_) => RecordFormDialog(
      title: 'Actualizar solicitud',
      description: '${record.id} · ${record.title}',
      fields: [
        RecordField(
          'incident-priority',
          'Prioridad',
          initial: record.priority,
          options: const [
            ('Baja', 'Baja'),
            ('Media', 'Media'),
            ('Alta', 'Alta'),
          ],
        ),
        RecordField(
          'incident-status',
          'Estado',
          initial: record.status.name,
          options: const [
            ('open', 'Abierto'),
            ('inProgress', 'En atención'),
            ('resolved', 'Resuelto'),
          ],
        ),
        RecordField(
          'incident-resolution',
          'Solución (obligatoria al resolver)',
          initial: record.resolution,
          optional: true,
          lines: 3,
        ),
      ],
      onSave: (v) => widget.controller.saveIncident(
        id: record.id,
        title: record.title,
        description: record.description,
        priority: v['incident-priority']!,
        status: IncidentStatus.values.byName(v['incident-status']!),
        resolution: v['incident-resolution']!,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final data = widget.controller;
      final id = widget.recordId ?? _localId;
      if (id != null) {
        final record = data.incidents.where((i) => i.id == id).firstOrNull;
        return RecordDetail(
          title: record?.title ?? 'Solicitud no disponible',
          onBack: _back,
          subtitle: record?.id ?? '',
          actions: [
            if (record != null)
              FilledButton(
                onPressed: () => _edit(record),
                child: const Text('Actualizar solicitud'),
              ),
          ],
          fields: record == null
              ? []
              : [
                  ('Estado', _status(record)),
                  ('Prioridad', record.priority),
                  ('Enviada por', record.requestedBy),
                  ('Creación', formatDate(record.createdAt)),
                  ('Descripción', record.description),
                  ('Solución', record.resolution),
                  if (record.resolvedAt != null)
                    ('Resuelto', formatDate(record.resolvedAt!)),
                ],
        );
      }
      final cases = data.incidents.reversed
          .where(
            (i) =>
                '${i.title} ${i.id} ${i.description} ${i.requestedBy}'
                    .toLowerCase()
                    .contains(_query) &&
                (_filter == 'Todos' ||
                    (_filter == 'Resueltos'
                        ? i.status == IncidentStatus.resolved
                        : i.status != IncidentStatus.resolved)),
          )
          .toList();
      final resolved = data.incidents
          .where((i) => i.resolvedAt != null)
          .toList();
      final average = resolved.isEmpty
          ? null
          : resolved.fold<int>(
                  0,
                  (n, i) => n + i.resolvedAt!.difference(i.createdAt).inMinutes,
                ) /
                resolved.length;
      return CompactWorkspace(
        title: 'Solicitudes de soporte',
        subtitle: 'Revisa, atiende y resuelve las solicitudes del personal.',
        toolbar: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SummaryStrip(
              values: [
                ('Pendientes', '${data.incidents.length - resolved.length}'),
                ('Resueltos', '${resolved.length}'),
                (
                  'Tiempo medio de resolución',
                  average == null
                      ? 'Sin datos'
                      : '${average.toStringAsFixed(0)} min',
                ),
              ],
            ),
            const SizedBox(height: 16),
            RecordToolbar(
              search: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Buscar solicitud de soporte',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              filters: [
                RecordFilter(
                  label: 'Estado',
                  value: _filter,
                  options: const ['Todos', 'Pendientes', 'Resueltos'],
                  onChanged: (v) => setState(() => _filter = v),
                ),
              ],
            ),
          ],
        ),
        child: CompactRecords(
          resetKey: (_query, _filter),
          itemCount: cases.length,
          emptyText: 'No hay solicitudes para este filtro.',
          columns: const [
            RecordColumn('Solicitud', flex: 2.5),
            RecordColumn('Prioridad'),
            RecordColumn('Estado'),
            RecordColumn('Creación'),
            RecordColumn(''),
          ],
          rowBuilder: (i) {
            final r = cases[i];
            final edit = IconButton(
              tooltip: 'Actualizar solicitud',
              onPressed: () => _edit(r),
              icon: const Icon(Icons.edit_outlined, size: 18),
            );
            return RecordRow(
              onOpen: () => _open(r.id),
              cells: [
                RecordIdentity(
                  title: r.title,
                  subtitle: [
                    r.id,
                    if (r.requestedBy.isNotEmpty) r.requestedBy,
                  ].join(' · '),
                ),
                RecordText(r.priority),
                RecordText(_status(r)),
                RecordText(formatDate(r.createdAt)),
                edit,
              ],
              mobile: RecordTile(
                title: r.title,
                subtitle: '${r.id} · ${_status(r)}',
                metadata: '${r.priority} · ${formatDate(r.createdAt)}',
                trailing: edit,
                onOpen: () => _open(r.id),
              ),
            );
          },
        ),
      );
    },
  );
}
