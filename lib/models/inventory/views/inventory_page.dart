import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/stat_card.dart';
import '../widgets/product_list_card.dart';

/// Pantalla de inventario con búsqueda, filtros y alertas de existencias.
class InventoryPage extends StatelessWidget {
  /// Crea la pantalla de inventario.
  const InventoryPage({
    required this.controller,
    required this.onAddProduct,
    super.key,
  });

  /// Estado compartido que contiene productos y filtros.
  final PharmacyController controller;

  /// Acción que abre el formulario de nuevo producto.
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(34, 28, 34, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Control de inventario',
            description:
                'Administra existencias, lotes y fechas de vencimiento.',
            action: FilledButton.icon(
              onPressed: onAddProduct,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo producto'),
            ),
          ),
          const SizedBox(height: 24),
          const Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              StatCard(
                label: 'Total productos',
                value: '128',
                detail: 'Registros activos',
                icon: Icons.inventory_2_outlined,
                color: AppColors.blue,
                background: AppColors.paleBlue,
                width: 245,
              ),
              StatCard(
                label: 'Valor inventario',
                value: r'C$ 24,680',
                detail: 'Costo estimado',
                icon: Icons.payments_outlined,
                color: AppColors.green,
                background: Color(0xFFEAF8F1),
                width: 245,
              ),
              StatCard(
                label: 'Lotes por vencer',
                value: '3',
                detail: 'Próximos 90 días',
                icon: Icons.event_busy_outlined,
                color: AppColors.red,
                background: Color(0xFFFFEFF0),
                width: 245,
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: controller.setInventorySearch,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre o categoría',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: ['Todos', 'Bajo mínimo', 'Por vencer']
                        .map(
                          (item) => ChoiceChip(
                            label: Text(item),
                            selected: controller.inventoryFilter == item,
                            onSelected: (_) =>
                                controller.setInventoryFilter(item),
                            selectedColor: AppColors.paleBlue,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ProductListCard(products: controller.visibleProducts),
        ],
      ),
    );
  }
}
