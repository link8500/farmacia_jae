import 'package:flutter/material.dart';
import '../../../models/inventory/models/product.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../core/utils/formatters.dart';

/// Catálogo de productos que se pueden agregar al POS.
class ProductCatalog extends StatelessWidget {
  /// Crea el catálogo con una acción de selección.
  const ProductCatalog({
    required this.products,
    required this.onAdd,
    super.key,
  });

  /// Productos disponibles para mostrar.
  final List<Product> products;

  /// Acción ejecutada al seleccionar un producto.
  final ValueChanged<Product> onAdd;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catálogo de productos',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 15),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Escanear o buscar producto',
              prefixIcon: Icon(Icons.search_rounded),
              suffixIcon: Icon(Icons.qr_code_scanner_rounded),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: products.take(6).map(_buildProductTile).toList(),
          ),
        ],
      ),
    );
  }

  /// Construye una ficha compacta para el catálogo.
  Widget _buildProductTile(Product product) {
    return SizedBox(
      width: 180,
      child: InkWell(
        onTap: product.stock > 0 ? () => onAdd(product) : null,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.medication_outlined, color: AppColors.blue),
              const SizedBox(height: 10),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                formatCordobas(product.price),
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
