import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../shared/widgets/record_form_dialog.dart';
import '../models/contact.dart';

/// Editor compartido entre el listado y la vista de detalle del contacto.
Future<bool?> editContact(
  BuildContext context,
  PharmacyController controller,
  ContactKind kind, [
  Contact? contact,
]) => showDialog<bool>(
  context: context,
  builder: (_) => RecordFormDialog(
    title: kind == ContactKind.supplier
        ? (contact == null ? 'Registrar proveedor' : 'Editar proveedor')
        : (contact == null ? 'Registrar cliente' : 'Editar cliente'),
    description: kind == ContactKind.customer
        ? 'Información del cliente.'
        : 'Información del proveedor.',
    fields: [
      if (kind == ContactKind.supplier) ...[
        RecordField(
          'supplier-code',
          'Código del proveedor',
          initial: contact?.code ?? '',
          optional: true,
        ),
        RecordField(
          'supplier-type',
          'Tipo de proveedor',
          initial: contact?.supplierType ?? 'Distribuidor',
          options: const [
            ('Distribuidor', 'Distribuidor'),
            ('Laboratorio', 'Laboratorio'),
            ('Mayorista', 'Mayorista'),
            ('Importador', 'Importador'),
            ('Otros', 'Otros'),
          ],
        ),
        RecordField(
          'supplier-origin',
          'País / ciudad de origen',
          initial: contact?.origin ?? '',
        ),
      ],
      RecordField(
        'contact-name',
        kind == ContactKind.supplier
            ? 'Razón social / nombre comercial'
            : 'Nombre',
        initial: contact?.name ?? '',
      ),
      RecordField(
        'contact-identification',
        'Cédula / identificación',
        initial: contact?.identification ?? '',
        optional: true,
      ),
      if (kind == ContactKind.supplier)
        RecordField(
          'contact-representative',
          'Representante',
          initial: contact?.representative ?? '',
          optional: true,
        ),
      RecordField(
        'contact-phone',
        'Teléfono',
        initial: contact?.phone ?? '',
        optional: true,
      ),
      RecordField(
        'contact-email',
        'Correo',
        initial: contact?.email ?? '',
        optional: true,
      ),
      RecordField(
        'contact-address',
        'Dirección',
        initial: contact?.address ?? '',
        optional: true,
        lines: 2,
      ),
      if (kind == ContactKind.supplier)
        RecordField(
          'supplier-description',
          'Descripción / condiciones comerciales',
          initial: contact?.description ?? '',
          optional: true,
          lines: 2,
        ),
    ],
    onSave: (v) => controller.saveContact(
      id: contact?.id,
      code: v['supplier-code'],
      supplierType: v['supplier-type'],
      origin: v['supplier-origin'],
      description: v['supplier-description'],
      kind: kind,
      name: v['contact-name']!,
      identification: v['contact-identification'],
      representative: v['contact-representative'],
      phone: v['contact-phone']!,
      email: v['contact-email']!,
      address: v['contact-address']!,
    ),
  ),
);
