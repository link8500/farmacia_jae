import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../../../shared/widgets/form_dialog.dart';
import '../../../shared/widgets/record_form_dialog.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../shared/widgets/workspace_sections.dart';
import '../../auth/models/session_user.dart';
import '../models/organization.dart';
import '../widgets/organization_dialogs.dart';
import '../widgets/staff_form_dialog.dart';
import '../../../shared/widgets/person_avatar.dart';

/// Un único centro para personas, roles y puestos completos. Las pestañas
/// muestran una lista a la vez, sin apilar directorios y catálogos en la página.
class OrganizationPage extends StatefulWidget {
  const OrganizationPage({
    required this.controller,
    this.selectedSection,
    this.onSection,
    super.key,
  });
  final PharmacyController controller;
  final int? selectedSection;
  final ValueChanged<int>? onSection;
  @override
  State<OrganizationPage> createState() => _OrganizationPageState();
}

class _OrganizationPageState extends State<OrganizationPage> {
  String _query = '', _branch = '*', _role = '*', _status = '*';
  int _localTab = 0;
  int get _tab => widget.selectedSection ?? _localTab;
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _staff([StaffMember? member]) => showDialog<bool>(
    context: context,
    builder: (_) =>
        StaffFormDialog(controller: widget.controller, member: member),
  );

  /// La sucursal de consulta no altera los puestos del personal.
  void _selectBranch(String id) {
    final data = widget.controller;
    if (data.workingBranchId == id) return;
    if (data.cart.isNotEmpty) {
      confirmCommand(
        context,
        '¿Cambiar de sucursal?',
        'Se vaciará la venta pendiente sin modificar el inventario ni las asignaciones del personal.',
        () => data.selectBranch(id),
      );
    } else {
      showCommandResult(context, data.selectBranch(id));
    }
  }

  Widget _state(bool active) => StatusPill(
    text: active ? 'Activo' : 'Inactivo',
    color: active ? context.palette.blue : context.palette.muted,
  );

  Future<void> _filters() async {
    var role = _role, status = _status;
    final apply = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => FormDialog(
          title: 'Filtrar personal',
          description: 'Combina rol y estado con la sucursal seleccionada.',
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Aplicar'),
            ),
          ],
          child: FormFieldsGrid(
            fields: [
              DropdownButtonFormField<String>(
                initialValue: role,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: [
                  const DropdownMenuItem(
                    value: '*',
                    child: Text('Todos los roles'),
                  ),
                  for (final r in UserRole.values)
                    DropdownMenuItem(value: r.name, child: Text(r.label)),
                ],
                onChanged: (v) => update(() => role = v ?? '*'),
              ),
              DropdownButtonFormField<String>(
                initialValue: status,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(value: '*', child: Text('Todos')),
                  DropdownMenuItem(value: 'active', child: Text('Activos')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactivos')),
                ],
                onChanged: (v) => update(() => status = v ?? '*'),
              ),
            ],
          ),
        ),
      ),
    );
    if (apply == true && mounted) {
      setState(() {
        _role = role;
        _status = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final data = widget.controller;
      if (!data.isAdministrator) {
        return const Center(
          child: Text(
            'Solo administración puede gestionar sucursales y personal.',
          ),
        );
      }
      return CompactWorkspace(
        title: 'Personal y asignaciones',
        subtitle: _tab == 3
            ? 'Catálogo de ${data.workingBranch?.name ?? 'la sucursal de consulta'}. Habilitar artículos no añade existencias.'
            : 'Personas, roles, sucursales y cajas en un mismo lugar.',
        actions: [
          if (_tab == 0)
            FilledButton.icon(
              key: const Key('staff-add'),
              onPressed: () => _staff(),
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              label: const Text('Añadir empleado'),
            ),
          if (_tab == 1)
            FilledButton.icon(
              onPressed: () => showBranchForm(context, data),
              icon: const Icon(Icons.add_business_outlined, size: 18),
              label: const Text('Crear sucursal'),
            ),
          if (_tab == 2)
            FilledButton.icon(
              onPressed: () => showRegisterForm(context, data),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Crear caja'),
            ),
          if (_tab == 0)
            OutlinedButton.icon(
              onPressed: _filters,
              icon: const Icon(Icons.filter_list, size: 18),
              label: Text(
                _role == '*' && _status == '*' ? 'Filtros' : 'Filtros activos',
              ),
            ),
        ],
        toolbar: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WorkspaceTabs(
              keyPrefix: 'organization-tab',
              labels: const [
                'Personal',
                'Sucursales',
                'Cajas',
                'Catálogo por sucursal',
              ],
              selected: _tab,
              onSelected: (v) => setState(() {
                if (widget.onSection != null) {
                  widget.onSection!(v);
                } else {
                  _localTab = v;
                }
                _query = '';
                _search.clear();
              }),
            ),
            const SizedBox(height: 14),
            RecordToolbar(
              search: TextField(
                controller: _search,
                key: const Key('staff-search'),
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: [
                    'Buscar persona, usuario, puesto o caja',
                    'Buscar sucursal',
                    'Buscar caja u operador',
                    'Buscar producto',
                  ][_tab],
                ),
              ),
              filters: [
                if (_tab == 0 || _tab == 2)
                  DropdownButtonFormField<String>(
                    initialValue: _branch,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Sucursal',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: '*', child: Text('Todas')),
                      for (final b in data.branches)
                        DropdownMenuItem(
                          value: b.id,
                          child: Text(b.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => _branch = v ?? '*'),
                  ),
              ],
            ),
          ],
        ),
        child: switch (_tab) {
          0 => _people(data),
          1 => _branches(data),
          2 => _registers(data),
          _ => _catalog(data),
        },
      );
    },
  );

  Widget _people(PharmacyController data) {
    final members = data.staff
        .where(
          (m) =>
              (_branch == '*' || m.branchId == _branch) &&
              (_role == '*' || m.role.name == _role) &&
              (_status == '*' || m.active == (_status == 'active')) &&
              '${m.name} ${m.username} ${m.role.label} ${m.jobTitle} ${data.branchById(m.branchId)?.name} ${data.registerById(m.registerId)?.name}'
                  .toLowerCase()
                  .contains(_query),
        )
        .toList();
    return CompactRecords(
      resetKey: (_query, _branch, _role, _status, _tab),
      itemCount: members.length,
      minimumTableWidth: 1080,
      columns: const [
        RecordColumn('Persona / usuario', flex: 1.6),
        RecordColumn('Rol / puesto', flex: 1.3),
        RecordColumn('Sucursal', flex: 1.4),
        RecordColumn('Caja'),
        RecordColumn('Estado'),
        RecordColumn(''),
      ],
      rowBuilder: (i) {
        final m = members[i];
        final branch = data.branchById(m.branchId)?.name ?? 'Sin asignar';
        final register = data.registerById(m.registerId)?.name ?? 'Sin caja';
        final edit = IconButton(
          key: Key('staff-edit-${m.id}'),
          tooltip: 'Editar ${m.name}',
          onPressed: () => _staff(m),
          icon: const Icon(Icons.edit_outlined, size: 18),
        );
        return RecordRow(
          onOpen: () => _staff(m),
          cells: [
            RecordIdentity(
              title: m.name,
              subtitle: '@${m.username}',
              leading: PersonAvatar(
                name: m.name,
                asset: m.photoAsset,
                size: 32,
              ),
            ),
            RecordIdentity(title: m.role.label, subtitle: m.jobTitle),
            RecordText(branch),
            RecordText(register),
            _state(m.active),
            edit,
          ],
          mobile: RecordTile(
            title: m.name,
            leading: PersonAvatar(name: m.name, asset: m.photoAsset),
            subtitle: '@${m.username} · ${m.role.label} · ${m.jobTitle}',
            metadata:
                '$branch · $register · ${m.active ? 'Activo' : 'Inactivo'}',
            trailing: edit,
            onOpen: () => _staff(m),
          ),
        );
      },
    );
  }

  Widget _branches(PharmacyController data) {
    final branches = data.branches
        .where((b) => '${b.name} ${b.address}'.toLowerCase().contains(_query))
        .toList();
    return CompactRecords(
      resetKey: (_query, _tab),
      itemCount: branches.length,
      columns: const [
        RecordColumn('Sucursal / dirección', flex: 2.5),
        RecordColumn('Personal activo'),
        RecordColumn('Cajas'),
        RecordColumn('Estado'),
        RecordColumn('Consulta'),
        RecordColumn(''),
      ],
      rowBuilder: (i) {
        final b = branches[i];
        final people = data.staff
            .where((s) => s.active && s.branchId == b.id)
            .length;
        final registers = data.registers
            .where((r) => r.branchId == b.id)
            .length;
        final current = b.id == data.workingBranchId;
        final actions = RecordActions(
          actions: [
            ('Editar sucursal', () => showBranchForm(context, data, b)),
            if (b.active)
              (
                'Crear caja',
                () => showRegisterForm(context, data, branchId: b.id),
              ),
            if (b.active && !current)
              ('Usar para consultas', () => _selectBranch(b.id)),
          ],
        );
        return RecordRow(
          cells: [
            RecordIdentity(title: b.name, subtitle: b.address),
            RecordText('$people'),
            RecordText('$registers'),
            _state(b.active),
            RecordText(current ? 'Actual' : '—'),
            actions,
          ],
          mobile: RecordTile(
            title: b.name,
            subtitle: b.address,
            metadata:
                '$people personas · $registers cajas · ${current
                    ? 'Consulta actual'
                    : b.active
                    ? 'Activa'
                    : 'Inactiva'}',
            trailing: actions,
          ),
        );
      },
    );
  }

  Widget _registers(PharmacyController data) {
    final rows = data.registers
        .where(
          (r) =>
              (_branch == '*' || r.branchId == _branch) &&
              '${r.name} ${data.operatorFor(r.id)?.name}'
                  .toLowerCase()
                  .contains(_query),
        )
        .toList();
    return CompactRecords(
      resetKey: (_query, _branch, _tab),
      itemCount: rows.length,
      columns: const [
        RecordColumn('Caja'),
        RecordColumn('Sucursal', flex: 1.5),
        RecordColumn('Operador actual', flex: 1.5),
        RecordColumn('Estado'),
        RecordColumn(''),
      ],
      rowBuilder: (i) {
        final r = rows[i];
        final b = data.branchById(r.branchId)?.name ?? 'Sin sucursal';
        final operator = data.operatorFor(r.id)?.name ?? 'Sin asignar';
        final edit = IconButton(
          tooltip: 'Editar ${r.name} de $b',
          onPressed: () => showRegisterForm(context, data, register: r),
          icon: const Icon(Icons.edit_outlined, size: 18),
        );
        return RecordRow(
          cells: [
            RecordText(r.name, bold: true),
            RecordText(b),
            RecordText(operator),
            _state(r.active),
            edit,
          ],
          mobile: RecordTile(
            title: '${r.name} · $b',
            subtitle: operator,
            metadata: r.active ? 'Activa' : 'Inactiva',
            trailing: edit,
          ),
        );
      },
    );
  }

  Widget _catalog(PharmacyController data) {
    final rows = data.masterProducts
        .where((p) => '${p.name} ${p.code}'.toLowerCase().contains(_query))
        .toList();
    return CompactRecords(
      resetKey: (_query, _tab, data.workingBranchId),
      itemCount: rows.length,
      columns: const [
        RecordColumn('Producto', flex: 2),
        RecordColumn('Código'),
        RecordColumn('Ficha'),
        RecordColumn('Habilitado en esta sucursal'),
      ],
      rowBuilder: (i) {
        final p = rows[i];
        final toggle = Switch.adaptive(
          value: data.productEnabled(data.workingBranchId, p.id),
          onChanged: data.workingBranch?.active != true
              ? null
              : (enabled) => confirmCommand(
                  context,
                  enabled
                      ? '¿Habilitar en esta sucursal?'
                      : '¿Retirar de esta sucursal?',
                  'Solo cambia la disponibilidad del catálogo en ${data.workingBranch?.name}. Las demás sedes no cambian.',
                  () => data.setBranchProduct(
                    data.workingBranchId,
                    p.id,
                    enabled,
                  ),
                ),
        );
        return RecordRow(
          cells: [
            RecordText(p.name, bold: true),
            RecordText(p.code),
            RecordText(p.active ? 'Activa' : 'Archivada'),
            toggle,
          ],
          mobile: RecordTile(
            title: p.name,
            subtitle: p.code,
            metadata: p.active ? 'Ficha activa' : 'Ficha archivada',
            trailing: toggle,
          ),
        );
      },
    );
  }
}
