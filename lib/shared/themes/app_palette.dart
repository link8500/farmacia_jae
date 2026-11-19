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
    required this.subtle,
    required this.paleBlue,
    required this.blue,
    required this.positiveSurface,
    required this.negativeSurface,
    required this.warningSurface,
    required this.heroStart,
    required this.heroEnd,
  });
  final Color ink, muted, border, canvas, surface, paleBlue, blue;
  final Color subtle;
  final Color positiveSurface,
      negativeSurface,
      warningSurface,
      heroStart,
      heroEnd;
  static const light = AppPalette(
    ink: AppColors.ink,
    // Texto secundario con contraste mínimo 4.5:1 sobre superficie clara.
    muted: Color(0xFF55647A),
    border: AppColors.border,
    canvas: AppColors.canvas,
    surface: Colors.white,
    subtle: Color(0xFFF4F6F9),
    paleBlue: AppColors.paleBlue,
    blue: AppColors.blue,
    positiveSurface: Color(0xFFEAF8F1),
    negativeSurface: Color(0xFFFFEFF0),
    warningSurface: Color(0xFFFFF4E8),
    heroStart: Color(0xFFEDF4FF),
    heroEnd: Color(0xFFF2FAF6),
  );
  static const dark = AppPalette(
    ink: Color(0xFFEAF0F8),
    muted: Color(0xFFB2BECE),
    border: Color(0xFF364456),
    canvas: Color(0xFF151C27),
    surface: Color(0xFF1C2635),
    subtle: Color(0xFF253142),
    paleBlue: Color(0xFF293D59),
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
    Color? subtle,
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
    subtle: subtle ?? this.subtle,
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
      subtle: blend(subtle, other.subtle),
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
