import 'package:flutter/material.dart';
import '../../core/services/preferences_controller.dart';
import '../themes/app_theme.dart';
import '../../models/settings/models/app_preferences.dart';

/// Límite del tema privado: ni el modo oscuro, ni el tamaño del texto, ni los
/// ajustes de movimiento cambian la presentación pública, que permanece clara.
class AdministrationAppearance extends StatefulWidget {
  const AdministrationAppearance({
    required this.preferences,
    required this.child,
    super.key,
  });
  final PreferencesController preferences;
  final Widget child;
  @override
  State<AdministrationAppearance> createState() =>
      _AdministrationAppearanceState();
}

class _AdministrationAppearanceState extends State<AdministrationAppearance> {
  @override
  void initState() {
    super.initState();
    widget.preferences.initialize();
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
      return AnimatedTheme(
        data: AppTheme.configured(
          brightness: dark ? Brightness.dark : Brightness.light,
          accent: dark ? prefs.accent.dark : prefs.accent.light,
          highContrast: prefs.highContrast,
          compact: prefs.density == WorkspaceDensity.compact,
        ),
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
          child: widget.preferences.isLoaded
              ? widget.child
              : const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
        ),
      );
    },
  );
}
