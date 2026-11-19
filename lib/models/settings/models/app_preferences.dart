import 'package:flutter/material.dart';

/// Escala adicional al tamaño de texto del sistema, sin modificar el navegador.
enum AppTextSize {
  standard('Estándar', 1),
  large('Grande', 1.1),
  extraLarge('Muy grande', 1.2);

  const AppTextSize(this.label, this.factor);
  final String label;
  final double factor;
}

/// Opciones de presentación. No modifican permisos ni datos de la farmacia.
enum AppAccent {
  blue('Azul', Color(0xFF245AC7), Color(0xFF8AB4FF)),
  teal('Verde petróleo', Color(0xFF087E77), Color(0xFF65D6C6)),
  violet('Violeta', Color(0xFF7143BD), Color(0xFFC5A6FF));

  const AppAccent(this.label, this.light, this.dark);
  final String label;
  final Color light, dark;
}

enum CatalogLayout { cards, list }

enum WorkspaceDensity { comfortable, compact }

enum WorkspaceColorFilter {
  none('Sin filtro'),
  grayscale('Escala de grises'),
  warm('Cálido');

  const WorkspaceColorFilter(this.label);
  final String label;
}

/// Preferencias personales de una cuenta en este navegador, sin sesión ni stock.
class AppPreferences {
  const AppPreferences({
    this.themeMode = ThemeMode.light,
    this.textSize = AppTextSize.standard,
    this.reduceMotion = false,
    this.confirmClearSale = true,
    this.showNotificationBadges = true,
    this.accent = AppAccent.blue,
    this.catalogLayout = CatalogLayout.cards,
    this.density = WorkspaceDensity.comfortable,
    this.highContrast = false,
    this.colorFilter = WorkspaceColorFilter.none,
  });
  final ThemeMode themeMode;
  final AppTextSize textSize;
  final bool reduceMotion;
  final bool confirmClearSale;
  final bool showNotificationBadges;
  final AppAccent accent;
  final CatalogLayout catalogLayout;
  final WorkspaceDensity density;
  final bool highContrast;
  final WorkspaceColorFilter colorFilter;

  AppPreferences copyWith({
    ThemeMode? themeMode,
    AppTextSize? textSize,
    bool? reduceMotion,
    bool? confirmClearSale,
    bool? showNotificationBadges,
    AppAccent? accent,
    CatalogLayout? catalogLayout,
    WorkspaceDensity? density,
    bool? highContrast,
    WorkspaceColorFilter? colorFilter,
  }) => AppPreferences(
    themeMode: themeMode ?? this.themeMode,
    textSize: textSize ?? this.textSize,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    confirmClearSale: confirmClearSale ?? this.confirmClearSale,
    showNotificationBadges:
        showNotificationBadges ?? this.showNotificationBadges,
    accent: accent ?? this.accent,
    catalogLayout: catalogLayout ?? this.catalogLayout,
    density: density ?? this.density,
    highContrast: highContrast ?? this.highContrast,
    colorFilter: colorFilter ?? this.colorFilter,
  );

  Map<String, Object> toJson() => {
    'version': 2,
    'themeMode': themeMode.name,
    'textSize': textSize.name,
    'reduceMotion': reduceMotion,
    'confirmClearSale': confirmClearSale,
    'showNotificationBadges': showNotificationBadges,
    'accent': accent.name,
    'catalogLayout': catalogLayout.name,
    'density': density.name,
    'highContrast': highContrast,
    'colorFilter': colorFilter.name,
  };

  /// Datos locales corruptos/desconocidos no impiden entrar a la aplicación.
  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version != 1 && version != 2) return const AppPreferences();
    // En v1 "system" también se guardaba al cambiar ajustes ajenos al tema.
    // El nuevo valor inicial es claro. Una elección de sistema en v2 sí persiste.
    final themeMode = version == 1 && json['themeMode'] == 'system'
        ? ThemeMode.light
        : ThemeMode.values.firstWhere(
            (mode) => mode.name == json['themeMode'],
            orElse: () => ThemeMode.light,
          );
    return AppPreferences(
      themeMode: themeMode,
      textSize: AppTextSize.values.firstWhere(
        (size) => size.name == json['textSize'],
        orElse: () => AppTextSize.standard,
      ),
      reduceMotion: json['reduceMotion'] is bool
          ? json['reduceMotion'] as bool
          : false,
      confirmClearSale: json['confirmClearSale'] is bool
          ? json['confirmClearSale'] as bool
          : true,
      showNotificationBadges: json['showNotificationBadges'] is bool
          ? json['showNotificationBadges'] as bool
          : true,
      accent: AppAccent.values.firstWhere(
        (v) => v.name == json['accent'],
        orElse: () => AppAccent.blue,
      ),
      catalogLayout: CatalogLayout.values.firstWhere(
        (v) => v.name == json['catalogLayout'],
        orElse: () => CatalogLayout.cards,
      ),
      density: WorkspaceDensity.values.firstWhere(
        (v) => v.name == json['density'],
        orElse: () => WorkspaceDensity.comfortable,
      ),
      highContrast: json['highContrast'] is bool
          ? json['highContrast'] as bool
          : false,
      colorFilter: WorkspaceColorFilter.values.firstWhere(
        (filter) => filter.name == json['colorFilter'],
        orElse: () => WorkspaceColorFilter.none,
      ),
    );
  }
}
