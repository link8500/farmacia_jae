/// Puntos de corte usados por la interfaz responsive.
///
/// Se mantienen centralizados para que todas las vistas respondan igual al
/// pasar de móvil a tablet o escritorio.
abstract final class AppBreakpoints {
  /// Hasta este ancho se considera una pantalla móvil.
  static const mobile = 600.0;

  /// Por debajo de este ancho los paneles se apilan en una sola columna.
  static const tabletContent = 720.0;

  /// Desde este ancho se habilita el layout de escritorio con sidebar.
  static const desktop = 900.0;

  /// Por debajo de este ancho se apilan cabeceras y acciones.
  static const compactHeader = 620.0;
}

/// Indica si un ancho debe usar la navegación móvil.
bool isMobileWidth(double width) => width < AppBreakpoints.desktop;

/// Indica si una vista debe apilar sus controles de cabecera.
bool isCompactWidth(double width) => width < AppBreakpoints.compactHeader;
