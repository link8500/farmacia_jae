import '../../inventory/models/product.dart';

/// Línea de una venta actual.
///
/// Mantener esta clase separada de la vista permite reutilizar el carrito en
/// una futura pantalla de facturación, caja o impresión de comprobantes.
class CartLine {
  /// Crea una línea iniciando la cantidad en una unidad.
  CartLine(this.product);

  /// Producto seleccionado para la venta.
  final Product product;

  /// Cantidad solicitada por el cliente.
  int quantity = 1;

  /// Subtotal de la línea.
  double get subtotal => quantity * product.price;
}
