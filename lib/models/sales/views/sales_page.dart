import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/page_header.dart';
import '../widgets/cart_card.dart';
import '../widgets/product_catalog.dart';

/// Pantalla de punto de venta (POS).
///
/// Presenta el catálogo y el carrito como dos piezas independientes para
/// poder reutilizarlas después en caja, facturación o venta rápida.
class SalesPage extends StatelessWidget {
  /// Crea el punto de venta conectado al controlador de farmacia.
  const SalesPage({
    required this.controller,
    required this.onMessage,
    super.key,
  });

  /// Estado compartido de productos y carrito.
  final PharmacyController controller;

  /// Callback para mostrar mensajes de operación.
  final ValueChanged<String> onMessage;

  @override
  Widget build(BuildContext context) {
    final total = controller.cart.fold<double>(
      0,
      (sum, line) => sum + line.subtotal,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(34, 28, 34, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Nueva venta',
            description: 'Busca un producto y agrégalo al carrito para cobrar.',
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              // En móvil el catálogo y el carrito ocupan todo el ancho;
              // en pantallas mayores se acomodan como paneles flexibles.
              final catalogWidth =
                  constraints.maxWidth < AppBreakpoints.tabletContent
                  ? constraints.maxWidth
                  : 620.0;
              final cartWidth =
                  constraints.maxWidth < AppBreakpoints.tabletContent
                  ? constraints.maxWidth
                  : 340.0;
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  SizedBox(
                    width: catalogWidth,
                    child: ProductCatalog(
                      products: controller.products,
                      onAdd: (product) {
                        final added = controller.addToCart(product);
                        if (added) {
                          onMessage('${product.name} agregado a la venta');
                        } else {
                          onMessage('Este producto no tiene existencias');
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: cartWidth,
                    child: CartCard(
                      cart: controller.cart,
                      total: total,
                      onRemove: controller.removeFromCart,
                      onClear: controller.clearCart,
                      onFinish: () {
                        if (controller.finishSale()) {
                          onMessage('Venta registrada correctamente');
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
