import 'package:flutter/material.dart';
import 'app_palette.dart';

/// Temas semánticos compartidos. La presentación siempre utiliza light;
/// AdministrationAppearance decide el tema del espacio interno.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData configured({
    required Brightness brightness,
    required Color accent,
    bool highContrast = false,
    bool compact = false,
  }) => _build(
    brightness,
    accent: accent,
    highContrast: highContrast,
    compact: compact,
  );

  static ThemeData _build(
    Brightness brightness, {
    Color? accent,
    bool highContrast = false,
    bool compact = false,
  }) {
    final basePalette = brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final palette = basePalette.copyWith(
      blue: accent,
      paleBlue: accent == null
          ? null
          : Color.alphaBlend(
              accent.withValues(alpha: .12),
              basePalette.surface,
            ),
      muted: highContrast ? basePalette.ink : null,
      border: highContrast ? basePalette.muted : null,
    );
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          brightness: brightness,
        ).copyWith(
          primary: palette.blue,
          onPrimary: brightness == Brightness.dark
              ? palette.canvas
              : Colors.white,
          primaryContainer: palette.paleBlue,
          onPrimaryContainer: palette.ink,
          surface: palette.surface,
          onSurface: palette.ink,
          onSurfaceVariant: palette.muted,
          outline: palette.border,
          outlineVariant: palette.border,
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Arial',
    );
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return base.copyWith(
      extensions: [palette],
      scaffoldBackgroundColor: palette.canvas,
      visualDensity: compact
          ? const VisualDensity(horizontal: -1, vertical: -1)
          : VisualDensity.standard,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      canvasColor: palette.surface,
      textTheme: base.textTheme.apply(
        bodyColor: palette.ink,
        displayColor: palette.ink,
      ),
      iconTheme: IconThemeData(color: palette.muted),
      dividerColor: palette.border,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        foregroundColor: palette.ink,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: palette.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        isDense: true,
        labelStyle: TextStyle(color: palette.muted),
        hintStyle: TextStyle(color: palette.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: border(palette.border),
        enabledBorder: border(palette.border),
        focusedBorder: border(palette.blue, 1.5),
      ),
    );
  }
}
