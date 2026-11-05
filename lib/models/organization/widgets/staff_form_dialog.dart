import 'package:flutter/material.dart';
import '../../../shared/widgets/person_avatar.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/form_validators.dart';
import '../../../shared/widgets/form_dialog.dart';
import '../models/organization.dart';
import '../../auth/models/session_user.dart';

/// Formulario dependiente: cambiar la sucursal limpia la caja anterior y solo
/// ofrece cajas de la nueva sede, sin perder los datos personales escritos.
class StaffFormDialog extends StatefulWidget {
  const StaffFormDialog({required this.controller, this.member, super.key});
  final PharmacyController controller;
  final StaffMember? member;
  @override
  State<StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends State<StaffFormDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _username, _job;
  late String _branch, _register;
  late bool _active;
  late UserRole _role;
  bool get _protected =>
      widget.member?.id == 'demo-admin' ||
      widget.member?.id == widget.controller.actorId;
  String? _error;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.member?.name ?? '');
    _username = TextEditingController(text: widget.member?.username ?? '');
    _job = TextEditingController(
      text: widget.member?.jobTitle ?? 'Dependiente',
    );
    _branch = widget.member?.branchId ?? widget.controller.workingBranchId;
    _register = widget.member?.registerId ?? '';
    _active = widget.member?.active ?? true;
    _role = widget.member?.role ?? UserRole.employee;
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _job.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final data = widget.controller;
    if (widget.member?.id == data.actorId &&
        data.cart.isNotEmpty &&
        (widget.member?.branchId != _branch ||
            widget.member?.registerId != _register)) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('¿Cambiar tu asignación?'),
          content: const Text(
            'Se vaciará tu venta pendiente. El inventario y las facturas anteriores no se modifican.',
          ),
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
      if (!mounted || accepted != true) return;
    }
    final error = widget.controller.saveStaff(
      id: widget.member?.id,
      name: _name.text,
      username: _username.text,
      jobTitle: _job.text,
      branchId: _branch,
      registerId: _register,
      active: _active,
      role: _role,
    );
    if (error != null) {
      setState(() => _error = error);
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) => FormDialog(
    title: widget.member == null
        ? 'Añadir empleado'
        : 'Editar personal y asignación',
    description:
        'Configura el acceso y el puesto en un solo paso. El rol define permisos; el puesto es descriptivo. Las cuentas locales usan 1234.',
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const Key('staff-save'),
        onPressed: _save,
        child: const Text('Guardar asignación'),
      ),
    ],
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.member case final member?) ...[
            Row(
              children: [
                PersonAvatar(
                  name: member.name,
                  asset: member.photoAsset,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    member.identification.isEmpty
                        ? 'Personal de la farmacia'
                        : member.identification,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          const Text(
            'Cuenta y permisos',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 14),
          FormFieldsGrid(
            fields: [
              TextFormField(
                key: const Key('staff-name'),
                controller: _name,
                validator: requiredText,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
              ),
              TextFormField(
                key: const Key('staff-username'),
                controller: _username,
                readOnly: widget.member != null,
                validator: requiredText,
                decoration: const InputDecoration(
                  labelText: 'Usuario de acceso',
                ),
              ),
              DropdownButtonFormField<UserRole>(
                key: const Key('staff-role'),
                isExpanded: true,
                initialValue: _role,
                decoration: InputDecoration(
                  labelText: 'Rol de acceso',
                  helperText: _protected
                      ? 'Se conserva el acceso de la cuenta principal y de tu sesión.'
                      : 'Empleado: operación de su sede. Administrador: gestión global.',
                  helperMaxLines: 3,
                ),
                items: [
                  for (final role in UserRole.values)
                    DropdownMenuItem(value: role, child: Text(role.label)),
                ],
                onChanged: _protected
                    ? null
                    : (role) => setState(() => _role = role!),
              ),
              TextFormField(
                key: const Key('staff-job'),
                controller: _job,
                validator: requiredText,
                decoration: const InputDecoration(
                  labelText: 'Puesto de trabajo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Puesto de trabajo',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 14),
          FormFieldsGrid(
            fields: [
              DropdownButtonFormField<String>(
                key: const Key('staff-branch'),
                isExpanded: true,
                initialValue:
                    widget.controller.branches.any((b) => b.id == _branch)
                    ? _branch
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Sucursal asignada',
                ),
                validator: requiredText,
                items: [
                  for (final b in widget.controller.branches)
                    DropdownMenuItem(
                      value: b.id,
                      enabled: b.active,
                      child: Text(
                        '${b.name}${b.active ? '' : ' (inactiva)'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) => setState(() {
                  _branch = id ?? '';
                  _register = '';
                }),
              ),
              DropdownButtonFormField<String>(
                key: ValueKey('staff-register-$_branch-$_register'),
                isExpanded: true,
                initialValue: _register,
                decoration: const InputDecoration(
                  labelText: 'Caja de facturación',
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Sin caja (no puede facturar)'),
                  ),
                  for (final r in widget.controller.registers.where(
                    (r) => r.branchId == _branch && r.active,
                  ))
                    DropdownMenuItem(
                      value: r.id,
                      enabled:
                          widget.controller.operatorFor(r.id) == null ||
                          widget.controller.operatorFor(r.id)?.id ==
                              widget.member?.id,
                      child: Text(
                        '${r.name}${widget.controller.operatorFor(r.id) == null || widget.controller.operatorFor(r.id)?.id == widget.member?.id ? '' : ' · Ocupada por ${widget.controller.operatorFor(r.id)!.name}'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _active
                    ? (id) => setState(() => _register = id ?? '')
                    : null,
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Empleado activo'),
            value: _active,
            onChanged: _protected
                ? null
                : (v) => setState(() {
                    _active = v;
                    if (!v) _register = '';
                  }),
          ),
          const Text(
            'Los cambios de rol se aplican al próximo inicio de sesión. Sin caja asignada no podrá facturar. Las facturas anteriores no se modifican.',
            style: TextStyle(fontSize: 12),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
  );
}
