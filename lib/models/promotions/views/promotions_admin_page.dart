import 'package:flutter/material.dart';
import '../widgets/promotion_artwork.dart';
import '../../../core/services/promotions_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../../../shared/widgets/record_detail.dart';
import '../../../shared/widgets/record_form_dialog.dart';
import '../../../shared/widgets/status_pill.dart';
import '../models/promotion.dart';
import '../widgets/promotion_form_dialog.dart';

/// Campañas editoriales: listado breve y contenido completo bajo demanda.
class PromotionsAdminPage extends StatefulWidget {
  const PromotionsAdminPage({
    required this.controller,
    required this.onPublicPage,
    this.promotionId,
    this.onOpen,
    this.onBack,
    super.key,
  });
  final PromotionsController controller;
  final VoidCallback onPublicPage;
  final String? promotionId;
  final ValueChanged<String>? onOpen;
  final VoidCallback? onBack;
  @override
  State<PromotionsAdminPage> createState() => _PromotionsAdminPageState();
}

class _PromotionsAdminPageState extends State<PromotionsAdminPage> {
  String _query = '', _status = 'Todas';
  String? _localId;
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.controller.loadEditor();
  }

  Future<void> _edit([Promotion? p]) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        PromotionFormDialog(controller: widget.controller, promotion: p),
  ).then((_) {});
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

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final data = widget.controller;
      if (!data.canManage) {
        return const Center(
          child: Text('Solo administración puede gestionar promociones.'),
        );
      }
      final id = widget.promotionId ?? _localId;
      if (id != null && data.editorLoaded) {
        final p = data.entries.where((p) => p.id == id).firstOrNull;
        return RecordDetail(
          title: p?.title ?? 'Promoción no disponible',
          onBack: _back,
          subtitle: 'Contenido editorial de la presentación.',
          media: p == null || p.illustrationKey.isEmpty
              ? null
              : PromotionArtwork(imageKey: p.illustrationKey, height: 120),
          actions: [
            if (p != null)
              FilledButton.icon(
                onPressed: data.isSaving ? null : () => _edit(p),
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Editar campaña'),
              ),
          ],
          fields: p == null
              ? []
              : [
                  ('Estado', p.phase(data.today)),
                  ('Etiqueta', p.badge),
                  ('Inicio', formatDate(p.startsAt)),
                  ('Finalización', formatDate(p.endsAt)),
                  ('Descripción', p.description),
                  ('Condiciones', p.conditions),
                ],
        );
      }
      final entries =
          data.entries
              .where(
                (p) =>
                    (_status == 'Todas' || p.status.label == _status) &&
                    '${p.title} ${p.description}'.toLowerCase().contains(
                      _query,
                    ),
              )
              .toList()
            ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
      return CompactWorkspace(
        title: 'Promociones',
        subtitle:
            'Publicación local: los cambios se muestran en este navegador.',
        actions: [
          OutlinedButton.icon(
            onPressed: widget.onPublicPage,
            icon: const Icon(Icons.open_in_new, size: 17),
            label: const Text('Ver página pública de promociones'),
          ),
          FilledButton.icon(
            key: const Key('promotion-create'),
            onPressed: data.editorLoaded && !data.isSaving
                ? () => _edit()
                : null,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nueva promoción'),
          ),
        ],
        toolbar: RecordToolbar(
          search: TextField(
            key: const Key('promotions-search'),
            controller: _search,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar campaña',
            ),
          ),
          filters: [
            RecordFilter(
              label: 'Estado',
              value: _status,
              options: [
                'Todas',
                for (final s in PromotionStatus.values) s.label,
              ],
              onChanged: (v) => setState(() => _status = v),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (data.editorError != null)
              _error(
                data.editorError!,
                'Reintentar carga',
                () => data.loadEditor(retry: true),
              ),
            if (data.storageError != null)
              _error(
                data.storageError!,
                'Reintentar publicación',
                data.publishPending && !data.isSaving
                    ? () async {
                        final error = await data.retryPublication();
                        if (context.mounted) showCommandResult(context, error);
                      }
                    : null,
              ),
            if (!data.editorLoaded && data.editorError == null)
              const Center(child: CircularProgressIndicator()),
            if (data.editorLoaded)
              Expanded(
                child: CompactRecords(
                  resetKey: (_query, _status),
                  itemCount: entries.length,
                  emptyText:
                      'Sin promociones para mostrar. Crea una campaña para comenzar.',
                  columns: const [
                    RecordColumn('Campaña', flex: 2.5),
                    RecordColumn('Estado'),
                    RecordColumn('Inicio'),
                    RecordColumn('Finalización'),
                    RecordColumn(''),
                  ],
                  rowBuilder: (i) {
                    final p = entries[i];
                    final edit = IconButton(
                      key: Key('promotion-edit-${p.id}'),
                      tooltip: 'Editar campaña',
                      onPressed: data.isSaving ? null : () => _edit(p),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    );
                    return RecordRow(
                      onOpen: () => _open(p.id),
                      cells: [
                        RecordIdentity(
                          title: p.title,
                          subtitle: p.badge,
                          leading: p.illustrationKey.isEmpty
                              ? null
                              : SizedBox(
                                  width: 44,
                                  height: 32,
                                  child: PromotionArtwork(
                                    imageKey: p.illustrationKey,
                                    height: 32,
                                    width: 44,
                                  ),
                                ),
                        ),
                        StatusPill(
                          text: p.phase(data.today),
                          color: context.palette.blue,
                        ),
                        RecordText(formatDate(p.startsAt)),
                        RecordText(formatDate(p.endsAt)),
                        edit,
                      ],
                      mobile: RecordTile(
                        title: p.title,
                        leading: p.illustrationKey.isEmpty
                            ? null
                            : SizedBox(
                                width: 48,
                                height: 40,
                                child: PromotionArtwork(
                                  imageKey: p.illustrationKey,
                                  height: 40,
                                  width: 48,
                                ),
                              ),
                        subtitle: p.phase(data.today),
                        metadata:
                            '${formatDate(p.startsAt)} — ${formatDate(p.endsAt)}',
                        trailing: edit,
                        onOpen: () => _open(p.id),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
  Widget _error(String text, String label, VoidCallback? retry) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      children: [
        Text(text),
        if (retry != null) TextButton(onPressed: retry, child: Text(label)),
      ],
    ),
  );
}
