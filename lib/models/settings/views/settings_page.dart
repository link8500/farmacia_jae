import 'package:flutter/material.dart';
import '../../../core/services/preferences_controller.dart';
import '../../../core/services/preferences_store.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../../../shared/widgets/form_dialog.dart';
import '../../../shared/widgets/workspace_sections.dart';
import '../../../shared/widgets/section_card.dart';
import '../models/app_preferences.dart';
import '../widgets/preferences_section.dart';
import '../widgets/theme_mode_option.dart';

/// Espacio PERSONAL accesible a todos los usuarios. Respaldos, permisos y
/// mantenimiento no pertenecen aquí y permanecen en su vista administrativa.
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    this.preferences,
    this.selectedSection,
    this.onSection,
    super.key,
  });
  final PreferencesController? preferences;
  final int? selectedSection;
  final ValueChanged<int>? onSection;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final PreferencesController _preferences;
  int _localSection = 0;
  int get _section => widget.selectedSection ?? _localSection;
  void _selectSection(int section) {
    if (widget.onSection != null) {
      widget.onSection!(section);
    } else {
      setState(() => _localSection = section);
    }
  }

  @override
  void initState() {
    super.initState();
    _preferences =
        widget.preferences ?? PreferencesController(MemoryPreferencesStore());
    _preferences.initialize();
  }

  @override
  void dispose() {
    if (widget.preferences == null) _preferences.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Restablecer tus preferencias?'),
        content: const Text(
          'Solo se restablecerán tus ajustes de apariencia, accesibilidad y facturación en este navegador. No cambia otras cuentas, productos, ventas ni asignaciones.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) _preferences.restoreDefaults();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _preferences,
    builder: (context, _) {
      final prefs = _preferences.value;
      return CompactWorkspace(
        title: 'Mis preferencias',
        subtitle: 'Ajustes personales que se aplican al instante.',
        actions: [
          OutlinedButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => FormDialog(
                title: 'Vista previa',
                description: 'Así se ven tus preferencias en este momento.',
                child: _preview(prefs),
              ),
            ),
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('Vista previa'),
          ),
          OutlinedButton.icon(
            key: const Key('preferences-reset'),
            onPressed: _restore,
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('Restablecer mis ajustes'),
          ),
        ],
        toolbar: WorkspaceTabs(
          keyPrefix: 'preferences-section',
          labels: const ['Apariencia', 'Accesibilidad', 'Facturación y avisos'],
          selected: _section,
          onSelected: _selectSection,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              switch (_section) {
                0 => _appearance(prefs),
                1 => _accessibility(prefs),
                _ => _workflow(prefs),
              },
              const SizedBox(height: 12),
              Text(
                _preferences.storageError ??
                    (_preferences.isSaving
                        ? 'Guardando preferencias…'
                        : 'Preferencias guardadas para tu cuenta en este navegador.'),
                style: TextStyle(fontSize: 11, color: context.palette.muted),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _appearance(AppPreferences prefs) => PreferencesSection(
    title: 'Elige cómo quieres trabajar',
    description:
        'Tema, color y espaciado del área interna. La presentación pública conserva su diseño.',
    icon: Icons.palette_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 560
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final option in [
                  (
                    ThemeMode.light,
                    'Claro',
                    'Limpio y luminoso',
                    Icons.light_mode_outlined,
                  ),
                  (
                    ThemeMode.dark,
                    'Oscuro',
                    'Para ambientes oscuros',
                    Icons.dark_mode_outlined,
                  ),
                  (
                    ThemeMode.system,
                    'Sistema',
                    'Sigue tu dispositivo',
                    Icons.brightness_auto_outlined,
                  ),
                ])
                  SizedBox(
                    width: width,
                    child: ThemeModeOption(
                      key: Key('theme-${option.$1.name}'),
                      label: option.$2,
                      description: option.$3,
                      icon: option.$4,
                      selected: prefs.themeMode == option.$1,
                      onTap: () => _preferences.setThemeMode(option.$1),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 26),
        _label(
          'Color de acento',
          'Se aplica a botones, selección y enlaces; no cambia la marca.',
        ),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            for (final accent in AppAccent.values)
              ChoiceChip(
                key: Key('accent-${accent.name}'),
                avatar: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? accent.dark
                      : accent.light,
                  radius: 7,
                ),
                label: Text(accent.label),
                selected: prefs.accent == accent,
                onSelected: (_) => _preferences.setAccent(accent),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _label(
          'Densidad del espacio',
          'El modo compacto reduce espaciado sin reducir el tamaño del texto.',
        ),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            for (final density in WorkspaceDensity.values)
              ChoiceChip(
                key: Key('density-${density.name}'),
                label: Text(
                  density == WorkspaceDensity.comfortable
                      ? 'Cómoda'
                      : 'Compacta',
                ),
                selected: prefs.density == density,
                onSelected: (_) => _preferences.setDensity(density),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _accessibility(AppPreferences prefs) => PreferencesSection(
    title: 'Lectura y comodidad',
    description:
        'Adapta la interfaz sin modificar el zoom ni las preferencias de otras cuentas.',
    icon: Icons.accessibility_new_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(
          'Tamaño del texto',
          'Se combina con la escala de lectura de tu dispositivo.',
        ),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            for (final size in AppTextSize.values)
              ChoiceChip(
                key: Key('text-size-${size.name}'),
                label: Text(size.label),
                selected: prefs.textSize == size,
                onSelected: (_) => _preferences.setTextSize(size),
              ),
          ],
        ),
        const SizedBox(height: 20),
        PreferenceToggle(
          key: const Key('high-contrast'),
          title: 'Reforzar el contraste',
          description:
              'Aumenta la separación de bordes y la intensidad de textos secundarios.',
          value: prefs.highContrast,
          onChanged: _preferences.setHighContrast,
        ),
        const Divider(height: 28),
        PreferenceToggle(
          key: const Key('reduce-motion'),
          title: 'Reducir animaciones',
          description:
              'Reduce transiciones del tema, menú y gráficos. También se respeta el movimiento reducido del dispositivo.',
          value: prefs.reduceMotion,
          onChanged: _preferences.setReduceMotion,
        ),
      ],
    ),
  );

  Widget _workflow(AppPreferences prefs) => PreferencesSection(
    title: 'Tu forma de facturar',
    description:
        'Preferencias de uso, no reglas del negocio. Nunca desactivan permisos, stock ni validaciones del cobro.',
    icon: Icons.point_of_sale_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(
          'Vista inicial del catálogo',
          'También puedes alternarla mientras preparas una factura.',
        ),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            for (final layout in CatalogLayout.values)
              ChoiceChip(
                key: Key('catalog-layout-${layout.name}'),
                avatar: Icon(
                  layout == CatalogLayout.cards
                      ? Icons.grid_view_rounded
                      : Icons.view_list_rounded,
                  size: 18,
                ),
                label: Text(
                  layout == CatalogLayout.cards ? 'Tarjetas' : 'Lista',
                ),
                selected: prefs.catalogLayout == layout,
                onSelected: (_) => _preferences.setCatalogLayout(layout),
              ),
          ],
        ),
        const SizedBox(height: 20),
        PreferenceToggle(
          key: const Key('confirm-clear-sale'),
          title: 'Confirmar antes de vaciar el carrito',
          description:
              'Pide confirmación antes de descartar una venta en preparación. Siempre se conserva la validación de existencias.',
          value: prefs.confirmClearSale,
          onChanged: _preferences.setConfirmClearSale,
        ),
        const Divider(height: 28),
        PreferenceToggle(
          key: const Key('notification-badges'),
          title: 'Mostrar indicador de alertas',
          description:
              'Controla el punto de la campana. No oculta los avisos importantes de inventario.',
          value: prefs.showNotificationBadges,
          onChanged: _preferences.setNotificationBadges,
        ),
      ],
    ),
  );

  Widget _label(String title, String description) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: TextStyle(color: context.palette.muted, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _preview(AppPreferences prefs) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.visibility_outlined,
              size: 18,
              color: context.palette.blue,
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Text(
                'Tu espacio, en vivo',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Vista previa de lectura y selección',
          style: TextStyle(fontSize: 12, color: context.palette.muted),
        ),
        const SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(
            prefs.density == WorkspaceDensity.compact ? 12 : 20,
          ),
          decoration: BoxDecoration(
            color: context.palette.canvas,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'FACTURACIÓN',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                  color: context.palette.blue,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Un espacio claro y ordenado',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Productos, cantidades y totales fáciles de identificar.',
                style: TextStyle(color: context.palette.muted, height: 1.5),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.palette.paleBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Elemento seleccionado',
                  style: TextStyle(
                    color: context.palette.blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Personalización individual\nNo cambia otras cuentas ni los datos de la farmacia.',
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: context.palette.muted,
          ),
        ),
      ],
    ),
  );
}
