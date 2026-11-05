import 'package:flutter/material.dart';
import '../../../core/routing/app_paths.dart';
import '../../../core/services/auth_controller.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../../../shared/widgets/form_dialog.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/workspace_sections.dart';
import '../widgets/profile_edit_dialog.dart';

/// Datos de solo lectura. La edición tiene un formulario independiente; los
/// permisos provienen de la sesión y las asignaciones del centro de personal.
class ProfilePage extends StatefulWidget {
  const ProfilePage({required this.auth, this.operations, super.key});
  final AuthController auth;
  final PharmacyController? operations;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _tab = 0;
  Future<void> _edit() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProfileEditDialog(auth: widget.auth),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil guardado en este navegador.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([widget.auth, ?widget.operations]),
    builder: (context, _) {
      final user = widget.auth.user;
      if (user == null) return const SizedBox.shrink();
      final data = widget.operations;
      return CompactWorkspace(
        title: 'Mi perfil',
        subtitle: user.isAdministrator
            ? 'Perfil del administrador'
            : 'Perfil del empleado',
        actions: [
          if (_tab == 1)
            OutlinedButton.icon(
              onPressed: widget.auth.signOut,
              icon: const Icon(Icons.logout, size: 17),
              label: const Text('Cerrar sesión'),
            ),
          FilledButton.icon(
            onPressed: _edit,
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: const Text('Editar perfil'),
          ),
        ],
        toolbar: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.auth.profileStorageError != null)
              Text(
                widget.auth.profileStorageError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            Row(
              children: [
                UserAvatar(user: user, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '@${user.username} · ${user.role.label}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            WorkspaceTabs(
              labels: const [
                'Información personal',
                'Acceso y seguridad',
                'Actividad',
              ],
              selected: _tab,
              onSelected: (v) => setState(() => _tab = v),
            ),
          ],
        ),
        child: switch (_tab) {
          0 => SingleChildScrollView(
            child: SectionCard(
              child: FormFieldsGrid(
                fields: [
                  _detail('Nombre completo', user.name),
                  _detail(
                    'Correo de contacto',
                    user.displayEmail.isEmpty
                        ? 'No registrado'
                        : user.displayEmail,
                  ),
                  _detail(
                    'Teléfono de contacto',
                    user.phone.isEmpty ? 'No registrado' : user.phone,
                  ),
                  _detail('Usuario de acceso', user.username),
                  _detail('Código de empleado', user.employeeCode),
                  _detail('Rol asignado', user.role.label),
                  _detail(
                    'Ubicación de referencia',
                    data?.branchById(data.currentStaff?.branchId ?? '')?.name ??
                        'Sin sucursal asignada',
                  ),
                  _detail(
                    'Caja asignada',
                    data
                            ?.registerById(data.currentStaff?.registerId ?? '')
                            ?.name ??
                        'Sin caja asignada',
                  ),
                ],
              ),
            ),
          ),
          1 => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SummaryStrip(
                values: [
                  (
                    'Vistas disponibles',
                    '${AppPaths.enabledSectionIndices.where((i) => user.isAdministrator || !AppPaths.administratorOnly.contains(i)).length} de ${AppPaths.enabledSectionIndices.length} vistas',
                  ),
                  ('Rol', user.role.label),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Sesión temporal del prototipo',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Se cierra al recargar o pulsar Cerrar sesión.',
                style: TextStyle(fontSize: 12, color: context.palette.muted),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: CompactRecords(
                  resetKey: (user.id, _tab),
                  itemCount: AppPaths.enabledSectionIndices.length,
                  columns: const [
                    RecordColumn('Vista', flex: 2),
                    RecordColumn('Acceso'),
                  ],
                  rowBuilder: (i) {
                    final index = AppPaths.enabledSectionIndices[i];
                    final allowed =
                        user.isAdministrator ||
                        !AppPaths.administratorOnly.contains(index);
                    return RecordRow(
                      cells: [
                        RecordText(AppPaths.titles[index], bold: true),
                        RecordText(
                          allowed ? 'Disponible' : 'Requiere administración',
                        ),
                      ],
                      mobile: RecordTile(
                        title: AppPaths.titles[index],
                        subtitle: allowed
                            ? 'Disponible'
                            : 'Requiere administración',
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          _ => _activity(user.id),
        },
      );
    },
  );
  Widget _detail(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 11, color: context.palette.muted)),
      const SizedBox(height: 5),
      SelectableText(
        value,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ],
  );
  Widget _activity(String id) {
    final entries =
        widget.operations?.audit
            .where((e) => e.actorId == id)
            .toList()
            .reversed
            .toList() ??
        [];
    return CompactRecords(
      resetKey: (id, _tab),
      itemCount: entries.length,
      emptyText:
          'Todavía no hay operaciones locales registradas para este perfil.',
      columns: const [
        RecordColumn('Operación', flex: 1.5),
        RecordColumn('Detalle', flex: 3),
        RecordColumn('Fecha'),
      ],
      rowBuilder: (i) {
        final e = entries[i];
        return RecordRow(
          cells: [
            RecordText(e.action, bold: true),
            RecordText(e.detail),
            RecordText(formatDate(e.at)),
          ],
          mobile: RecordTile(
            title: e.action,
            subtitle: e.detail,
            metadata: formatDate(e.at),
          ),
        );
      },
    );
  }
}
