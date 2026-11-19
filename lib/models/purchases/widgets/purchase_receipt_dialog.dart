import 'package:flutter/material.dart';

import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/form_validators.dart';
import '../../../shared/widgets/form_dialog.dart';
import '../../inventory/models/inventory_lot.dart';
import '../models/purchase_order.dart';

/// Recibe físicamente lo que ya identifica la orden. Solo se capturan datos
/// de la entrega que aún no existen en la sucursal.
class PurchaseReceiptDialog extends StatefulWidget {
  const PurchaseReceiptDialog({
    required this.controller,
    required this.order,
    super.key,
  });

  final PharmacyController controller;
  final PurchaseOrder order;

  @override
  State<PurchaseReceiptDialog> createState() => _PurchaseReceiptDialogState();
}

class _PurchaseReceiptDialogState extends State<PurchaseReceiptDialog> {
  final _form = GlobalKey<FormState>();
  final _indications = <String, String>{};
  late final Map<String, List<_LotDraft>> _lots = {
    for (final line in widget.order.lines)
      line.productId: [_LotDraft(line.productId, '${line.quantity}')],
  };
  int _sequence = 1;
  String? _error;

  @override
  void dispose() {
    for (final draft in _lots.values.expand((drafts) => drafts)) {
      draft.dispose();
    }
    super.dispose();
  }

  void _selectCode(PurchaseLine line, _LotDraft draft, String code) {
    final known = widget.controller.supplierLot(
      line.productId,
      widget.order.supplierId,
      code,
    );
    if (draft.known?.id == known?.id) return;
    setState(() {
      draft.known = known;
      draft.manufactured.text = _dateText(known?.manufacturedAt);
      draft.expiry.text = _dateText(known?.expiry);
      draft.location.text = known?.location ?? '';
    });
  }

  void _remove(PurchaseLine line, _LotDraft draft) {
    setState(() {
      final drafts = _lots[line.productId]!;
      drafts.remove(draft);
      if (drafts.length == 1) drafts.single.quantity.text = '${line.quantity}';
    });
    // Flutter desmonta los campos antes de liberar sus controladores.
    WidgetsBinding.instance.addPostFrameCallback((_) => draft.dispose());
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final error = widget.controller.receivePurchase(widget.order.id, [
      for (final line in widget.order.lines)
        for (final draft in _lots[line.productId]!)
          LotReceipt(
            productId: line.productId,
            code: draft.code.text,
            quantity: int.parse(draft.quantity.text.trim()),
            manufacturedAt: parseCalendarDate(draft.manufactured.text.trim())!,
            expiry: parseCalendarDate(draft.expiry.text.trim())!,
            location: draft.location.text,
          ),
    ], manufacturerIndications: _indications);
    if (error != null) {
      setState(() => _error = error);
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final supplier = widget.controller.contactById(order.supplierId);
    final origin = supplier?.origin ?? '';
    return FormDialog(
      title: 'Recibir ${order.id}',
      description:
          '${order.supplierName}${origin.isEmpty ? '' : ' · $origin'}\n'
          'Usa el código y las fechas de la etiqueta o del documento de entrega. '
          'Si el lote ya existe para este proveedor, se completan sus datos.',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Confirmar recepción'),
        ),
      ],
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final line in order.lines) ...[
              _productLots(line),
              const Divider(height: 28),
            ],
            const Text(
              'Si el producto aún no tiene precio de venta, defínelo por unidad desde su ficha después de recibirlo.',
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _productLots(PurchaseLine line) {
    final drafts = _lots[line.productId]!;
    final unit = line.unit.isEmpty ? 'unidades' : line.unit;
    final split = drafts.length > 1;
    final assigned = drafts.fold<int>(
      0,
      (sum, draft) => sum + (int.tryParse(draft.quantity.text.trim()) ?? 0),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(line.productName, style: Theme.of(context).textTheme.titleSmall),
        Text(
          split
              ? '$assigned de ${line.quantity} $unit asignadas a lotes'
              : '${line.quantity} $unit en la orden',
        ),
        for (final draft in drafts)
          Padding(
            key: ValueKey(draft.id),
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (split)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Lote ${drafts.indexOf(draft) + 1}'),
                      IconButton(
                        tooltip: 'Quitar lote de la recepción',
                        onPressed: () => _remove(line, draft),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                FormFieldsGrid(fields: _fields(line, draft, split: split)),
              ],
            ),
          ),
        if (drafts.length < line.quantity)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () => setState(() {
                drafts.add(_LotDraft('${line.productId}-${++_sequence}', ''));
              }),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Añadir otro lote'),
            ),
          ),
        const SizedBox(height: 12),
        TextFormField(
          key: Key('manufacturer-indications-${line.productId}'),
          minLines: 1,
          maxLines: 3,
          maxLength: PurchaseOrder.maxManufacturerIndicationsLength,
          decoration: const InputDecoration(
            labelText: 'Indicaciones del fabricante (opcional)',
            hintText: 'Texto del prospecto recibido con esta compra',
            alignLabelWithHint: true,
          ),
          onChanged: (value) => _indications[line.productId] = value,
        ),
      ],
    );
  }

  List<Widget> _fields(
    PurchaseLine line,
    _LotDraft draft, {
    required bool split,
  }) {
    final today = widget.controller.today;
    final known = draft.known;
    return [
      TextFormField(
        key: Key('batch-${draft.id}'),
        controller: draft.code,
        textCapitalization: TextCapitalization.characters,
        onChanged: (code) => _selectCode(line, draft, code),
        decoration: InputDecoration(
          labelText: 'Código de lote del proveedor',
          helperText: known == null ? null : 'Lote encontrado en la sucursal',
        ),
        validator: requiredText,
      ),
      if (split)
        TextFormField(
          key: Key('quantity-${draft.id}'),
          controller: draft.quantity,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Unidades en este lote'),
          validator: positiveInteger,
        ),
      _dateField(
        id: 'manufactured-${draft.id}',
        label: 'Fabricación',
        controller: draft.manufactured,
        first: DateTime(1900),
        last: known?.receivedAt ?? today,
        readOnly: known?.manufacturedAt != null,
        error: 'Indica la fecha de fabricación de la etiqueta.',
      ),
      _dateField(
        id: 'expiry-${draft.id}',
        label: 'Vencimiento',
        controller: draft.expiry,
        first: today,
        last: DateTime(today.year + 50, 12, 31),
        readOnly: known != null,
        error: 'Indica un vencimiento válido y vigente.',
      ),
      TextFormField(
        key: Key('location-${draft.id}'),
        controller: draft.location,
        readOnly: known?.location.isNotEmpty ?? false,
        decoration: const InputDecoration(
          labelText: 'Ubicación en farmacia',
          hintText: 'Estante / nivel / sección',
        ),
        validator: requiredText,
      ),
    ];
  }

  Widget _dateField({
    required String id,
    required String label,
    required TextEditingController controller,
    required DateTime first,
    required DateTime last,
    required bool readOnly,
    required String error,
  }) => TextFormField(
    key: Key(id),
    controller: controller,
    readOnly: readOnly,
    keyboardType: TextInputType.datetime,
    decoration: InputDecoration(
      labelText: label,
      hintText: 'AAAA-MM-DD',
      suffixIcon: readOnly
          ? const Icon(Icons.lock_outline, size: 16)
          : IconButton(
              tooltip: 'Elegir fecha de ${label.toLowerCase()}',
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              onPressed: () async {
                final entered = parseCalendarDate(controller.text.trim());
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      entered == null ||
                          entered.isBefore(first) ||
                          entered.isAfter(last)
                      ? (widget.controller.today.isAfter(last)
                            ? last
                            : widget.controller.today)
                      : entered,
                  firstDate: first,
                  lastDate: last,
                );
                if (date != null && mounted) controller.text = _dateText(date);
              },
            ),
    ),
    validator: (value) {
      final date = parseCalendarDate(value?.trim() ?? '');
      return date == null || date.isBefore(first) || date.isAfter(last)
          ? error
          : null;
    },
  );
}

String _dateText(DateTime? date) =>
    date?.toIso8601String().split('T').first ?? '';

class _LotDraft {
  _LotDraft(this.id, String units)
    : quantity = TextEditingController(text: units);

  final String id;
  final TextEditingController quantity;
  final code = TextEditingController();
  final manufactured = TextEditingController();
  final expiry = TextEditingController();
  final location = TextEditingController();
  InventoryLot? known;

  void dispose() {
    for (final field in [quantity, code, manufactured, expiry, location]) {
      field.dispose();
    }
  }
}
