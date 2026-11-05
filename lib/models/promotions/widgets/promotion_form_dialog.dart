import 'package:flutter/material.dart';
import '../../../core/services/promotions_controller.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/form_dialog.dart';
import '../../products/models/product_illustration.dart';
import '../models/promotion.dart';
import '../models/promotion_image.dart';
import 'promotion_artwork.dart';

/// Editor de contenido y vigencia; no calcula precios ni descuentos fiscales.
class PromotionFormDialog extends StatefulWidget {
  const PromotionFormDialog({
    required this.controller,
    this.promotion,
    super.key,
  });
  final PromotionsController controller;
  final Promotion? promotion;
  @override
  State<PromotionFormDialog> createState() => _PromotionFormDialogState();
}

class _PromotionFormDialogState extends State<PromotionFormDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title, _description, _badge, _conditions;
  late DateTime _start, _end;
  late String _image;
  late String _id;
  late PromotionStatus _status;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final p = widget.promotion;
    _id = p?.id ?? '';
    _title = TextEditingController(text: p?.title ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _badge = TextEditingController(text: p?.badge ?? 'Novedad');
    _conditions = TextEditingController(text: p?.conditions ?? '');
    _start = p?.startsAt ?? widget.controller.today;
    _end = p?.endsAt ?? _start.add(const Duration(days: 30));
    _status = p?.status ?? PromotionStatus.draft;
    _image = p?.illustrationKey ?? '';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _badge.dispose();
    _conditions.dispose();
    super.dispose();
  }

  Future<void> _dates() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(widget.controller.today.year + 10, 12, 31),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (range != null && mounted) {
      setState(() {
        _start = range.start;
        _end = range.end;
      });
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await widget.controller.save(
      Promotion(
        id: _id,
        title: _title.text,
        description: _description.text,
        badge: _badge.text,
        conditions: _conditions.text,
        startsAt: _start,
        endsAt: _end,
        status: _status,
        illustrationKey: _image,
      ),
    );
    if (!mounted) return;
    if (result.id != null) _id = result.id!;
    if (result.error != null) {
      setState(() {
        _saving = false;
        _error = result.error;
      });
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) => FormDialog(
    canClose: !_saving,
    title: widget.promotion == null ? 'Nueva promoción' : 'Editar promoción',
    description:
        'Publica solo contenido confirmado. Las promociones son informativas; no cambian los precios de facturación.',
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const Key('promotion-save'),
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Guardando…' : 'Guardar promoción'),
      ),
    ],
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('promotion-title'),
            controller: _title,
            maxLength: 100,
            enabled: !_saving,
            validator: requiredText,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('promotion-description'),
            controller: _description,
            maxLength: 600,
            maxLines: 3,
            enabled: !_saving,
            validator: requiredText,
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('promotion-badge'),
            controller: _badge,
            maxLength: 32,
            enabled: !_saving,
            validator: requiredText,
            decoration: const InputDecoration(labelText: 'Etiqueta visible'),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _saving ? null : _dates,
            icon: const Icon(Icons.date_range_outlined),
            label: Text('${formatDate(_start)} — ${formatDate(_end)}'),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<PromotionStatus>(
            key: const Key('promotion-status'),
            initialValue: _status,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Estado de publicación',
            ),
            items: [
              for (final status in PromotionStatus.values)
                DropdownMenuItem(value: status, child: Text(status.label)),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() => _status = value!),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            key: const Key('promotion-image'),
            initialValue: _image,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Imagen de la campaña',
            ),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('Icono de promoción'),
              ),
              for (final entry in PromotionImages.values.entries)
                DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value.name),
                ),
              for (final image in ProductIllustrations.values)
                DropdownMenuItem(
                  value: image.key,
                  child: Text(image.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() => _image = value!),
          ),
          const SizedBox(height: 18),
          if (_image.isNotEmpty) ...[
            PromotionArtwork(imageKey: _image, height: 140),
            const SizedBox(height: 18),
          ],
          TextFormField(
            key: const Key('promotion-conditions'),
            controller: _conditions,
            maxLines: 3,
            maxLength: 1500,
            enabled: !_saving,
            decoration: const InputDecoration(
              labelText: 'Condiciones y restricciones (opcional)',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Solo se muestran publicaciones vigentes. Los borradores, las archivadas y las promociones fuera de fecha no aparecen en la vista pública.',
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 18),
        ],
      ),
    ),
  );
}
