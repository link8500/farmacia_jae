import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../../../shared/widgets/record_detail.dart';
import '../../../shared/widgets/form_dialog.dart';
import '../../../shared/widgets/workspace_sections.dart';
import '../../../shared/widgets/record_form_dialog.dart';
import '../models/support_case.dart';

/// Registro, prioridad, seguimiento y cierre con una solución obligatoria.
class IncidentsPage extends StatefulWidget {
  const IncidentsPage({
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
  State<IncidentsPage> createState() => _IncidentsPageState();
}

class _IncidentsPageState extends State<IncidentsPage> {
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
  void _help() => showDialog<void>(
    context: context,
    builder: (_) => const FormDialog(
      title: 'Guía rápida',
      description: 'Uso del espacio de trabajo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Apariencia y texto',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Text('Mi cuenta → Preferencias. Los ajustes son personales.'),
          SizedBox(height: 16),
          Text(
            'Asignación para facturar',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            'Necesitas una sucursal activa y una caja asignada. El administrador gestiona tu puesto en Personal y asignaciones.',
          ),
          SizedBox(height: 16),
          Text(
            'Disponibilidad de productos',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            'El producto debe estar habilitado en la sucursal y tener lotes vigentes para poder venderse.',
          ),
        ],
      ),
    ),
  );
  void _edit([SupportCase? record]) => showDialog<bool>(
    context: context,
    builder: (_) => RecordFormDialog(
      title: record == null ? 'Reportar un problema' : 'Actualizar solicitud',
      description:
          'Historial local de soporte. No genera tickets ni envía mensajes externos.',
      fields: [
        RecordField('incident-title', 'Título', initial: record?.title ?? ''),
        RecordField(
          'incident-description',
          'Descripción',
          initial: record?.description ?? '',
          lines: 3,
        ),
        RecordField(
          'incident-priority',
          'Prioridad',
          initial: record?.priority ?? 'Media',
          options: const [
            ('Baja', 'Baja'),
            ('Media', 'Media'),
            ('Alta', 'Alta'),
          ],
        ),
        RecordField(
          'incident-status',
          'Estado',
          initial: record?.status.name ?? 'open',
          options: const [
            ('open', 'Abierto'),
            ('inProgress', 'En atención'),
            ('resolved', 'Resuelto'),
          ],
        ),
        RecordField(
          'incident-resolution',
          'Solución (obligatoria al resolver)',
          initial: record?.resolution ?? '',
          optional: true,
          lines: 3,
        ),
      ],
      onSave: (v) => widget.controller.saveIncident(
        id: record?.id,
        title: v['incident-title']!,
        description: v['incident-description']!,
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
                child: const Text('Actualizar estado / editar'),
              ),
          ],
          fields: record == null
              ? []
              : [
                  ('Estado', _status(record)),
                  ('Prioridad', record.priority),
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
                '${i.title} ${i.id} ${i.description}'.toLowerCase().contains(
                  _query,
                ) &&
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
        title: 'Ayuda y soporte',
        subtitle: 'Consulta y da seguimiento a las solicitudes de ayuda.',
        actions: [
          OutlinedButton.icon(
            onPressed: _help,
            icon: const Icon(Icons.help_outline, size: 18),
            label: const Text('Guía rápida'),
          ),
          FilledButton.icon(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Reportar un problema'),
          ),
        ],
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
              tooltip: 'Actualizar estado / editar',
              onPressed: () => _edit(r),
              icon: const Icon(Icons.edit_outlined, size: 18),
            );
            return RecordRow(
              onOpen: () => _open(r.id),
              cells: [
                RecordIdentity(title: r.title, subtitle: r.id),
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
