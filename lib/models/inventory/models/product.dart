/// Producto disponible para venta y control de inventario.
///
/// Este modelo representa los datos que después se conectarán con la tabla
/// producto y sus lotes en la base de datos.
class Product {
  /// Crea un producto con sus datos operativos principales.
  Product({
    required this.name,
    required this.category,
    required this.stock,
    required this.minimum,
    required this.price,
    required this.expiry,
  });

  /// Nombre comercial y presentación del medicamento.
  final String name;

  /// Categoría utilizada para clasificar y buscar el producto.
  final String category;

  /// Existencias disponibles en la farmacia.
  int stock;

  /// Cantidad mínima que dispara una alerta de reposición.
  final int minimum;

  /// Precio unitario de venta.
  final double price;

  /// Fecha de vencimiento del lote representativo.
  final DateTime expiry;

  /// Indica si el producto está en el nivel mínimo o por debajo.
  bool get isLow => stock <= minimum;

  /// Indica si el vencimiento ocurre dentro de los próximos 90 días.
  bool get isExpiring => expiry.difference(DateTime.now()).inDays <= 90;
}
