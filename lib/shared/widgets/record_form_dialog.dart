import 'package:flutter/material.dart';
import '../../core/utils/form_validators.dart';
import '../themes/app_palette.dart';
import 'form_dialog.dart';

/// Definición de campos reutilizable en contactos, caja, cobro e incidentes.
class RecordField {
  const RecordField(
    this.id,
    this.label, {
    this.initial = '',
    this.options,
    this.validator,
    this.optional = false,
    this.lines = 1,
    this.keyboard,
    this.firstDate,
    this.lastDate,
  });
  final String id, label, initial;
  final List<(String, String)>? options;
  final String? Function(String?)? validator;
  final bool optional;
  final int lines;
  final TextInputType? keyboard;
  final DateTime? firstDate, lastDate;
}

class RecordFormDialog extends StatefulWidget {
  const RecordFormDialog({
    required this.title,
    required this.description,
    required this.fields,
    required this.onSave,
    this.saveLabel = 'Guardar',
    super.key,
  });
  final String title, description, saveLabel;
  final List<RecordField> fields;
  final String? Function(Map<String, String>) onSave;
  @override
  State<RecordFormDialog> createState() => _RecordFormDialogState();
}

class _RecordFormDialogState extends State<RecordFormDialog> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _text;
  String? _error;
  @override
  void initState() {
    super.initState();
    _text = {
      for (final f in widget.fields)
        f.id: TextEditingController(text: f.initial),
    };
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormDialog(
    title: widget.title,
    description: widget.description,
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          final error = widget.onSave({
            for (final entry in _text.entries)
              entry.key: entry.value.text.trim(),
          });
          if (error != null) {
            setState(() => _error = error);
          } else {
            Navigator.pop(context, true);
          }
        },
        child: Text(widget.saveLabel),
      ),
    ],
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormFieldsGrid(
            fields: [
              for (final field in widget.fields.where((f) => f.lines == 1))
                _field(field),
            ],
          ),
          for (final field in widget.fields.where((f) => f.lines > 1))
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: _field(field),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.red),
              ),
            ),
        ],
      ),
    ),
  );
  Future<void> _pickDate(RecordField field) async {
    final first = field.firstDate!, last = field.lastDate!;
    var initial = parseCalendarDate(_text[field.id]!.text) ?? DateTime.now();
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (date != null && mounted) {
      _text[field.id]!.text = date.toIso8601String().substring(0, 10);
    }
  }

  Widget _field(RecordField field) => field.options == null
      ? TextFormField(
          key: Key(field.id),
          controller: _text[field.id],
          maxLines: field.lines,
          keyboardType: field.keyboard,
          decoration: InputDecoration(
            labelText: field.label,
            suffixIcon: field.firstDate != null && field.lastDate != null
                ? IconButton(
                    tooltip: 'Elegir fecha',
                    onPressed: () => _pickDate(field),
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  )
                : null,
          ),
          validator:
              field.validator ?? (field.optional ? (_) => null : requiredText),
        )
      : DropdownButtonFormField<String>(
          key: Key(field.id),
          isExpanded: true,
          initialValue: field.options!.any((o) => o.$1 == field.initial)
              ? field.initial
              : null,
          decoration: InputDecoration(labelText: field.label),
          items: [
            for (final option in field.options!)
              DropdownMenuItem(
                value: option.$1,
                child: Text(option.$2, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (value) => _text[field.id]!.text = value ?? '',
          validator: field.optional ? (_) => null : requiredText,
        );
}

/// Confirmaciones y mensajes comunes, con resultado real del comando de dominio.
Future<void> confirmCommand(
  BuildContext context,
  String title,
  String description,
  String? Function() command,
) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(description),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
  if (accepted == true && context.mounted) {
    showCommandResult(context, command());
  }
}

void showCommandResult(BuildContext context, String? error) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Operación aplicada a los datos locales.'),
      ),
    );
