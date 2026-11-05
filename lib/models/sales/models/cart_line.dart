import '../../products/models/product.dart';

/// Línea de una venta actual.
///
/// Mantener esta clase separada de la vista permite reutilizar el carrito en
/// una futura pantalla de facturación, caja o impresión de comprobantes.
class CartLine {
  /// Crea una línea iniciando la cantidad en una unidad.
  const CartLine(this.product, {this.quantity = 1});

  /// Producto seleccionado para la venta.
  final Product product;

  /// Cantidad solicitada por el cliente.
  final int quantity;

  /// Las vistas no pueden cambiar cantidades sin pasar por las validaciones.
  CartLine withQuantity(int value) => CartLine(product, quantity: value);

  /// Subtotal de la línea.
  double get subtotal => quantity * product.price;
}
