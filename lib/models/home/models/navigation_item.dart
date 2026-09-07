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
