import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_pill.dart';
import '../models/product.dart';

/// Lista reutilizable de productos registrados.
class ProductListCard extends StatelessWidget {
  /// Crea la lista con los productos filtrados.
  const ProductListCard({required this.products, super.key});

  /// Productos que se deben mostrar.
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Productos registrados',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${products.length} resultados',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 42),
              child: Center(
                child: Text(
                  'No hay productos que coincidan con el filtro.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            )
          else
            ...products.map(_buildProductRow),
        ],
      ),
    );
  }

  /// Construye una fila de producto con stock, vencimiento y estado.
  Widget _buildProductRow(Product product) {
    final statusColor = product.isLow
        ? AppColors.orange
        : product.isExpiring
        ? AppColors.red
        : AppColors.green;
    final statusText = product.isLow
        ? 'Bajo mínimo'
        : product.isExpiring
        ? 'Por vencer'
        : 'Disponible';

    return LayoutBuilder(
      builder: (context, constraints) {
        if (isCompactWidth(constraints.maxWidth)) {
          // En móvil los metadatos bajan a una segunda línea y dejan de
          // competir con el nombre por el espacio horizontal de la fila.
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.medication_outlined,
                      color: AppColors.blue,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 34, top: 6),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${product.category}  •  Vence ${formatDate(product.expiry)}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '${product.stock} unidades',
                        style: TextStyle(
                          color: product.isLow ? AppColors.red : AppColors.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      StatusPill(text: statusText, color: statusColor),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.medication_outlined, color: AppColors.blue),
          title: Text(
            product.name,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '${product.category}  •  Vence ${formatDate(product.expiry)}',
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
          trailing: SizedBox(
            width: 112,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${product.stock} unidades',
                  style: TextStyle(
                    color: product.isLow ? AppColors.red : AppColors.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                StatusPill(text: statusText, color: statusColor),
              ],
            ),
          ),
        );
      },
    );
  }
}
