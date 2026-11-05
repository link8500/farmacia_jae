import 'package:flutter/material.dart';
import 'app_colors.dart';
export 'app_colors.dart';

/// Colores semánticos de superficies y texto. La marca conserva sus colores
/// originales; los componentes consultan el tema, no colores claros fijos.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.ink,
    required this.muted,
    required this.border,
    required this.canvas,
    required this.surface,
    required this.paleBlue,
    required this.blue,
    required this.positiveSurface,
    required this.negativeSurface,
    required this.warningSurface,
    required this.heroStart,
    required this.heroEnd,
  });
  final Color ink, muted, border, canvas, surface, paleBlue, blue;
  final Color positiveSurface,
      negativeSurface,
      warningSurface,
      heroStart,
      heroEnd;
  static const light = AppPalette(
    ink: AppColors.ink,
    // Texto secundario con contraste mínimo 4.5:1 sobre superficie clara.
    muted: Color(0xFF637187),
    border: AppColors.border,
    canvas: AppColors.canvas,
    surface: Colors.white,
    paleBlue: AppColors.paleBlue,
    blue: AppColors.blue,
    positiveSurface: Color(0xFFEAF8F1),
    negativeSurface: Color(0xFFFFEFF0),
    warningSurface: Color(0xFFFFF4E8),
    heroStart: Color(0xFFEDF4FF),
    heroEnd: Color(0xFFF2FAF6),
  );
  static const dark = AppPalette(
    ink: Color(0xFFE8EFF9),
    muted: Color(0xFFADBCD1),
    border: Color(0xFF30435F),
    canvas: Color(0xFF0D1626),
    surface: Color(0xFF17243A),
    paleBlue: Color(0xFF223856),
    blue: Color(0xFF8AB4FF),
    positiveSurface: Color(0xFF19382F),
    negativeSurface: Color(0xFF3D2832),
    warningSurface: Color(0xFF3B3022),
    heroStart: Color(0xFF1B304E),
    heroEnd: Color(0xFF1B362F),
  );

  @override
  AppPalette copyWith({
    Color? ink,
    Color? muted,
    Color? border,
    Color? canvas,
    Color? surface,
    Color? paleBlue,
    Color? blue,
    Color? positiveSurface,
    Color? negativeSurface,
    Color? warningSurface,
    Color? heroStart,
    Color? heroEnd,
  }) => AppPalette(
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    border: border ?? this.border,
    canvas: canvas ?? this.canvas,
    surface: surface ?? this.surface,
    paleBlue: paleBlue ?? this.paleBlue,
    blue: blue ?? this.blue,
    positiveSurface: positiveSurface ?? this.positiveSurface,
    negativeSurface: negativeSurface ?? this.negativeSurface,
    warningSurface: warningSurface ?? this.warningSurface,
    heroStart: heroStart ?? this.heroStart,
    heroEnd: heroEnd ?? this.heroEnd,
  );

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    Color blend(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      ink: blend(ink, other.ink),
      muted: blend(muted, other.muted),
      border: blend(border, other.border),
      canvas: blend(canvas, other.canvas),
      surface: blend(surface, other.surface),
      paleBlue: blend(paleBlue, other.paleBlue),
      blue: blend(blue, other.blue),
      positiveSurface: blend(positiveSurface, other.positiveSurface),
      negativeSurface: blend(negativeSurface, other.negativeSurface),
      warningSurface: blend(warningSurface, other.warningSurface),
      heroStart: blend(heroStart, other.heroStart),
      heroEnd: blend(heroEnd, other.heroEnd),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light);
}
