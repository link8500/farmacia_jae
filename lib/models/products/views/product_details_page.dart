import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/record_detail.dart';
import '../../../shared/widgets/workspace_sections.dart';
import '../../../shared/widgets/record_form_dialog.dart';
import '../../../core/utils/form_validators.dart';
import '../widgets/supplier_catalog.dart';
import '../widgets/product_form_dialog.dart';
import '../widgets/product_thumbnail.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({
    required this.controller,
    required this.productId,
    required this.onBack,
    required this.onLots,
    super.key,
  });
  final PharmacyController controller;
  final String productId;
  final VoidCallback onBack, onLots;
  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _tab = 0;
  PharmacyController get controller => widget.controller;
  String get productId => widget.productId;
  VoidCallback get onBack => widget.onBack;
  VoidCallback get onLots => widget.onLots;
  @override
  void didUpdateWidget(covariant ProductDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) _tab = 0;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final p = controller.productById(productId);
      if (p == null) {
        return RecordDetail(
          title: 'Producto no disponible',
          onBack: onBack,
          fields: const [],
        );
      }
      return RecordDetail(
        title: p.name,
        subtitle: '${p.code} · Ficha de producto',
        navigation: WorkspaceTabs(
          labels: [
            'Ficha comercial',
            'Información farmacéutica',
            if (controller.isAdministrator) 'Proveedores',
          ],
          selected: _tab,
          onSelected: (i) => setState(() => _tab = i),
        ),
        media: ProductThumbnail(
          illustrationKey: p.illustrationKey,
          height: 150,
          showCaption: true,
        ),
        onBack: onBack,
        actions: [
          if (controller.isAdministrator &&
              controller.lots.any((l) => l.productId == p.id))
            OutlinedButton.icon(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => RecordFormDialog(
                  title: 'Precio unitario de venta',
                  description:
                      'Precio por ${p.unit}. Envase: ${p.presentation} (${p.packageUnits} unidades de venta). Se aplica a ventas nuevas.',
                  fields: [
                    RecordField(
                      'sale-price',
                      'Precio por ${p.unit} (C\$)',
                      initial: p.price > 0 ? p.price.toStringAsFixed(2) : '',
                      validator: positiveAmount,
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                  onSave: (v) => controller.setProductPrice(
                    p.id,
                    parseAmount(v['sale-price']!)!,
                  ),
                ),
              ),
              icon: const Icon(Icons.sell_outlined, size: 17),
              label: const Text('Definir precio'),
            ),

          OutlinedButton.icon(
            onPressed: onLots,
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Ver lotes'),
          ),
          if (controller.isAdministrator)
            FilledButton.icon(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) =>
                    ProductFormDialog(controller: controller, product: p),
              ),
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: const Text('Editar ficha'),
            ),
        ],
        fields: [
          if (_tab != 1) ...[
            ('Código', p.code),
            ('Categoría', p.category),
            ('Presentación', p.presentation),
            ('Unidad de venta', p.unit),
            (
              'Precio por ${p.unit}',
              p.price > 0 ? formatCordobas(p.price) : 'Pendiente de definir',
            ),
            ('Unidades por envase', '${p.packageUnits} ${p.unit}'),
            ('Mínimo', '${p.minimum} ${p.unit}'),
            ('Código de barras', p.barcode),
            ('Estado', p.active ? 'Activo' : 'Archivado'),
          ],
          if (_tab == 1) ...[
            ('Concentración / dosis', p.dosage),
            ('Unidad de medida', p.measurementUnit),
            ('Origen', p.origin),
            ('Laboratorio / fabricante', p.manufacturer),
            (
              'Dispensación',
              p.requiresPrescription ? 'Bajo receta' : 'Sin receta',
            ),
            ('Principio activo', p.activeIngredient),
            ('Descripción', p.description),
            ('Indicaciones del fabricante', p.indications),
            ('Contraindicaciones / advertencias', p.contraindications),
          ],
        ],
        children: [
          if (controller.isAdministrator && _tab == 2)
            SupplierCatalog(controller: controller, productId: p.id),
        ],
      );
    },
  );
}
