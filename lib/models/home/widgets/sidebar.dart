import 'package:flutter/material.dart';
import '../../../core/routing/app_paths.dart';
import '../../../models/auth/models/session_user.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/pharmacy_brand.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../models/navigation_item.dart';
import '../models/admin_modules.dart';

/// Menú lateral principal de la aplicación.
class Sidebar extends StatefulWidget {
  /// Crea el menú indicando la pantalla activa y su callback de navegación.
  const Sidebar({
    required this.selected,
    required this.onSelect,
    required this.user,
    required this.onProfile,
    required this.onLogout,
    super.key,
  });

  /// Identidad real de la sesión de demostración, no un administrador fijo.
  final SessionUser user;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  /// Índice de la opción activa.
  final int selected;

  /// Callback que cambia la pantalla principal.
  final ValueChanged<int> onSelect;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  // Catálogo único de procesos; el mismo árbol alimenta desktop y drawer.
  static const _modules = adminModules;

  final Set<String> _expandedModules = {'supervision', 'abastecimiento'};

  @override
  void initState() {
    super.initState();
    final active = _moduleFor(widget.selected);
    if (active != null) _expandedModules.add(active.id);
  }

  @override
  void didUpdateWidget(covariant Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      final activeModule = _moduleFor(widget.selected);
      if (activeModule != null) {
        setState(() => _expandedModules.add(activeModule.id));
      }
    }
  }

  NavigationModule? _moduleFor(int index) {
    for (final module in _modules) {
      if (module.contains(index)) return module;
    }
    return null;
  }

  void _toggleModule(String id) {
    setState(() {
      if (_expandedModules.contains(id)) {
        _expandedModules.remove(id);
      } else {
        _expandedModules.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ocultar opciones no sustituye el guard: ambos usan la misma política.
    final visibleModules = _modules
        .map(
          (module) => NavigationModule(
            id: module.id,
            label: module.label,
            icon: module.icon,
            items: module.items
                .where(
                  (item) =>
                      widget.user.isAdministrator ||
                      !AppPaths.administratorOnly.contains(item.index),
                )
                .toList(),
          ),
        )
        .where((module) => module.items.isNotEmpty)
        .toList();
    return Container(
      width: 248,
      color: context.palette.surface,
      child: SafeArea(
        // El perfil queda al pie con ambos roles. Solo la navegación desplaza
        // el contenido cuando la altura o el tamaño de texto lo requieren.
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Brand(),
                  const _MenuLabel('MÓDULOS'),
                  ...visibleModules.asMap().entries.map(
                    (entry) => _buildModule(entry.value, entry.key == 0),
                  ),
                ],
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(height: 26),
                  _UserCard(
                    user: widget.user,
                    onProfile: widget.onProfile,
                    onLogout: widget.onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un módulo que puede abrirse y cerrarse desde el navbar.
  Widget _buildModule(NavigationModule module, bool first) {
    final expanded = _expandedModules.contains(module.id);
    final active = module.contains(widget.selected);

    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : 7),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Material(
              color: active && !expanded
                  ? context.palette.paleBlue
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _toggleModule(module.id),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        module.icon,
                        size: 18,
                        color: active
                            ? context.palette.blue
                            : context.palette.muted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          module.label,
                          style: TextStyle(
                            color: active
                                ? context.palette.blue
                                : context.palette.ink,
                            fontSize: 13,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: active
                            ? context.palette.blue
                            : context.palette.muted,
                        size: 19,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // No iniciar AnimatedSize con duración cero: su controlador puede
          // invalidar el layout mientras se mide al cambiar de módulo.
          if (MediaQuery.disableAnimationsOf(context))
            _moduleItems(module, expanded)
          else
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: _moduleItems(module, expanded),
            ),
        ],
      ),
    );
  }

  /// Construye una pantalla hija con sangría visual dentro del módulo.
  Widget _moduleItems(NavigationModule module, bool expanded) => expanded
      ? Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Column(children: module.items.map(_buildItem).toList()),
        )
      : const SizedBox.shrink();

  /// Construye una pantalla hija con sangría visual dentro del módulo.
  Widget _buildItem(NavigationItem item) {
    final active = item.index == widget.selected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Material(
        color: active ? context.palette.paleBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: () => widget.onSelect(item.index),
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(42, 9, 12, 9),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 17,
                  color: active ? context.palette.blue : context.palette.muted,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: active
                          ? context.palette.blue
                          : context.palette.ink,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (item.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? context.palette.surface
                          : context.palette.paleBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.badge!,
                      style: TextStyle(
                        color: context.palette.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Marca visual de la farmacia en el menú.
class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(24, 24, 20, 24),
    child: PharmacyBrand(compact: true, subtitle: 'Administración'),
  );
}

/// Separador textual que agrupa opciones relacionadas.
class _MenuLabel extends StatelessWidget {
  const _MenuLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 9),
      child: Text(
        text,
        style: TextStyle(
          color: context.palette.muted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// Información resumida del usuario activo.
class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onProfile,
    required this.onLogout,
  });
  final SessionUser user;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.paleBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                UserAvatar(user: user),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.palette.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        user.role.label,
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, size: 15),
            label: const Text('Cerrar sesión', style: TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: context.palette.blue.withValues(alpha: .15),
              ),
              foregroundColor: context.palette.ink,
            ),
          ),
        ],
      ),
    );
  }
}
