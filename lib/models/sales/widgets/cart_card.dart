import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/sales/models/cart_line.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../shared/widgets/section_card.dart';

/// Carrito de la venta actual.
class CartCard extends StatelessWidget {
  /// Crea el carrito con las acciones de edición y confirmación.
  const CartCard({
    required this.cart,
    required this.total,
    required this.onRemove,
    required this.onClear,
    required this.onFinish,
    super.key,
  });

  /// Líneas actualmente seleccionadas.
  final List<CartLine> cart;

  /// Total calculado de la venta.
  final double total;

  /// Quita una unidad de una línea.
  final ValueChanged<CartLine> onRemove;

  /// Vacía el carrito.
  final VoidCallback onClear;

  /// Confirma la venta.
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Venta actual',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (cart.isNotEmpty)
                TextButton(onPressed: onClear, child: const Text('Vaciar')),
            ],
          ),
          if (cart.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  'El carrito está vacío',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            )
          else ...[
            ...cart.map(
              (line) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  line.product.name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${line.quantity} x ${formatCordobas(line.product.price)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                trailing: IconButton(
                  onPressed: () => onRemove(line),
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    size: 17,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total a pagar',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  formatCordobas(total),
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onFinish,
                child: const Text('Completar venta'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
