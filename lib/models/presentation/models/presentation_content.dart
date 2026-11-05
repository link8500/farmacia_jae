/// Contenido editorial permanente de la presentación pública.
///
/// Este módulo es estático por diseño: no consulta inventario, autenticación,
/// servicios ni base de datos. No se prevé conectarlo a un backend.
abstract final class PresentationContent {
  static const location = 'La Paz Centro, León';
  static const categories = [
    (
      title: 'Medicamentos',
      description: 'Consulta información y disponibilidad en la farmacia.',
      type: 'medicine',
    ),
    (
      title: 'Cuidado personal',
      description: 'Productos para tu rutina de cuidado cotidiano.',
      type: 'care',
    ),
    (
      title: 'Vitaminas y bienestar',
      description: 'Conoce esta categoría en el establecimiento.',
      type: 'vitamins',
    ),
    (
      title: 'Primeros auxilios',
      description: 'Artículos para organizar tu botiquín.',
      type: 'kit',
    ),
  ];
}
