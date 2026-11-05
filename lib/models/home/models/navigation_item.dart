import 'package:flutter/material.dart';

/// Describe una opción del menú lateral.
///
/// Convertir las opciones en datos evita duplicar la estructura del menú
/// entre desktop y móvil y facilita agregar nuevas áreas en el futuro.
class NavigationItem {
  /// Crea una opción de navegación.
  const NavigationItem({
    required this.index,
    required this.label,
    required this.icon,
    this.badge,
  });

  /// Índice de la pantalla que debe mostrarse.
  final int index;

  /// Texto visible para el usuario.
  final String label;

  /// Icono representativo.
  final IconData icon;

  /// Indicador opcional, por ejemplo la cantidad de alertas.
  final String? badge;
}

/// Módulo de navegación que agrupa pantallas relacionadas.
///
/// Los módulos se muestran como secciones desplegables en el menú lateral.
/// Mantener esta relación como datos permite reutilizar el mismo menú en
/// escritorio y dentro del drawer móvil sin duplicar reglas de navegación.
class NavigationModule {
  /// Crea un módulo con sus pantallas hijas.
  const NavigationModule({
    required this.id,
    required this.label,
    required this.icon,
    required this.items,
  });

  /// Identificador estable utilizado para conservar el estado de expansión.
  final String id;

  /// Nombre visible del módulo.
  final String label;

  /// Icono que representa el módulo.
  final IconData icon;

  /// Pantallas que pertenecen a este módulo.
  final List<NavigationItem> items;

  /// Indica si el módulo contiene la pantalla activa.
  bool contains(int selectedIndex) =>
      items.any((item) => item.index == selectedIndex);
}
