import 'package:flutter/material.dart';
import '../../core/services/preferences_controller.dart';
import '../../core/services/browser_appearance.dart';
import '../themes/app_theme.dart';
import '../themes/app_palette.dart';
import '../themes/workspace_color_filter.dart';
import '../../models/settings/models/app_preferences.dart';

/// Límite del tema privado: ni el modo oscuro, ni el tamaño del texto, ni los
/// ajustes de movimiento cambian la presentación pública, que permanece clara.
class AdministrationAppearance extends StatefulWidget {
  const AdministrationAppearance({
    required this.preferences,
    required this.child,
    this.syncBrowser = true,
    super.key,
  });
  final PreferencesController preferences;
  final Widget child;
  final bool syncBrowser;
  @override
  State<AdministrationAppearance> createState() =>
      _AdministrationAppearanceState();
}

class _AdministrationAppearanceState extends State<AdministrationAppearance> {
  Brightness? _browserBrightness;

  @override
  void initState() {
    super.initState();
    widget.preferences.initialize();
  }

  @override
  void dispose() {
    if (widget.syncBrowser) updateBrowserAppearance();
    super.dispose();
  }

  void _syncBrowser(Brightness brightness, Color canvas) {
    if (!widget.syncBrowser || _browserBrightness == brightness) return;
    _browserBrightness = brightness;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _browserBrightness == brightness) {
        updateBrowserAppearance(
          background: canvas,
          dark: brightness == Brightness.dark,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.preferences,
    builder: (context, _) {
      final media = MediaQuery.of(context);
      final prefs = widget.preferences.value;
      final dark =
          prefs.themeMode == ThemeMode.dark ||
          (prefs.themeMode == ThemeMode.system &&
              media.platformBrightness == Brightness.dark);
      final reduceMotion = prefs.reduceMotion || media.disableAnimations;
      final brightness = dark ? Brightness.dark : Brightness.light;
      final theme = AppTheme.configured(
        brightness: brightness,
        accent: dark ? prefs.accent.dark : prefs.accent.light,
        highContrast: prefs.highContrast,
        compact: prefs.density == WorkspaceDensity.compact,
      );
      _syncBrowser(brightness, theme.extension<AppPalette>()!.canvas);
      return AnimatedTheme(
        data: theme,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 180),
        child: MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(
              media.textScaler.scale(1) * prefs.textSize.factor,
            ),
            disableAnimations: reduceMotion,
          ),
          // Se conserva el árbol al cambiar de filtro, incluido el navegador
          // interno y cualquier formulario que el usuario tenga abierto.
          child: ColorFiltered(
            colorFilter: prefs.colorFilter.colorFilter,
            child: widget.preferences.isLoaded
                ? _AdministrationOverlayTheme(
                    preferences: widget.preferences,
                    child: widget.child,
                  )
                : const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
          ),
        ),
      );
    },
  );
}

/// Flutter captura InheritedTheme al abrir un diálogo, menú o calendario en
/// el navegador raíz. Transporta las preferencias vivas junto con el tema.
class _AdministrationOverlayTheme extends InheritedTheme {
  const _AdministrationOverlayTheme({
    required this.preferences,
    required super.child,
  });

  final PreferencesController preferences;

  @override
  Widget wrap(BuildContext context, Widget child) => AdministrationAppearance(
    preferences: preferences,
    syncBrowser: false,
    child: child,
  );

  @override
  bool updateShouldNotify(_AdministrationOverlayTheme oldWidget) =>
      preferences != oldWidget.preferences;
}
