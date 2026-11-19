import 'package:flutter/material.dart';

import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/form_validators.dart';
import '../../../shared/widgets/administration_page.dart';
import '../../../shared/widgets/form_dialog.dart';
import '../../../shared/widgets/section_card.dart';

/// Entrada del personal. El seguimiento se realiza en la bandeja administrativa.
class SupportSubmissionPage extends StatefulWidget {
  const SupportSubmissionPage({required this.controller, super.key});

  final PharmacyController controller;

  @override
  State<SupportSubmissionPage> createState() => _SupportSubmissionPageState();
}

class _SupportSubmissionPageState extends State<SupportSubmissionPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _priority = 'Media';
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _send() {
    if (!_form.currentState!.validate()) return;
    final error = widget.controller.saveIncident(
      title: _title.text,
      description: _description.text,
      priority: _priority,
    );
    setState(() => _error = error);
    if (error != null) return;
    _form.currentState!.reset();
    _title.clear();
    _description.clear();
    _priority = 'Media';
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Solicitud enviada al panel de soporte de este navegador.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AdministrationPage(
    title: 'Ayuda y soporte',
    description: 'Envía una solicitud al equipo que administra la farmacia.',
    children: [
      Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SectionCard(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nueva solicitud',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  FormFieldsGrid(
                    fields: [
                      TextFormField(
                        key: const Key('support-title'),
                        controller: _title,
                        decoration: const InputDecoration(labelText: 'Asunto'),
                        validator: requiredText,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: 'Media',
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Prioridad',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Baja', child: Text('Baja')),
                          DropdownMenuItem(
                            value: 'Media',
                            child: Text('Media'),
                          ),
                          DropdownMenuItem(value: 'Alta', child: Text('Alta')),
                        ],
                        onChanged: (value) => _priority = value ?? 'Media',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('support-description'),
                    controller: _description,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      hintText:
                          'Indica en qué pantalla ocurrió y qué estabas intentando hacer.',
                      alignLabelWithHint: true,
                    ),
                    validator: requiredText,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _send,
                      icon: const Icon(Icons.send_outlined, size: 17),
                      label: const Text('Enviar solicitud'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
