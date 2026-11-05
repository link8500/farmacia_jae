import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../shared/widgets/record_form_dialog.dart';
import '../models/organization.dart';

/// Formularios del centro de personal. No trasladan cajas existentes entre
/// sedes: conservar su identidad permite consultar correctamente las ventas.
Future<bool?> showBranchForm(
  BuildContext context,
  PharmacyController data, [
  PharmacyBranch? branch,
]) => showDialog<bool>(
  context: context,
  builder: (_) => RecordFormDialog(
    title: branch == null ? 'Crear sucursal' : 'Editar sucursal',
    description:
        'Crear una sede no copia inventario. Habilita su catálogo, crea sus cajas y asigna al personal desde esta vista.',
    fields: [
      RecordField('branch-name', 'Nombre', initial: branch?.name ?? ''),
      RecordField(
        'branch-address',
        'Dirección',
        initial: branch?.address ?? '',
        optional: true,
      ),
      RecordField(
        'branch-active',
        'Estado',
        initial: (branch?.active ?? true) ? 'true' : 'false',
        options: const [('true', 'Activa'), ('false', 'Inactiva')],
      ),
    ],
    onSave: (values) => data.saveBranch(
      id: branch?.id,
      name: values['branch-name']!,
      address: values['branch-address']!,
      active: values['branch-active'] == 'true',
    ),
  ),
);

Future<bool?> showRegisterForm(
  BuildContext context,
  PharmacyController data, {
  BillingRegister? register,
  String? branchId,
}) => showDialog<bool>(
  context: context,
  builder: (_) => RecordFormDialog(
    title: register == null
        ? 'Crear caja de facturación'
        : 'Editar caja de facturación',
    description:
        'Una caja pertenece a una sucursal y admite un operador activo. Cambia su operador editando la asignación de la persona en el directorio.',
    fields: [
      RecordField(
        'register-branch',
        'Sucursal',
        initial: register?.branchId ?? branchId ?? data.workingBranchId,
        options: [
          for (final b in data.branches.where(
            (b) => register == null ? b.active : b.id == register.branchId,
          ))
            (b.id, b.name),
        ],
      ),
      RecordField(
        'register-name',
        'Nombre de caja',
        initial: register?.name ?? '',
      ),
      RecordField(
        'register-active',
        'Estado',
        initial: (register?.active ?? true) ? 'true' : 'false',
        options: const [('true', 'Activa'), ('false', 'Inactiva')],
      ),
    ],
    onSave: (values) => data.saveRegister(
      id: register?.id,
      branchId: values['register-branch']!,
      name: values['register-name']!,
      active: values['register-active'] == 'true',
    ),
  ),
);
