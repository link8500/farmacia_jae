import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../../../shared/widgets/record_form_dialog.dart';
import '../models/product.dart';
import '../widgets/product_form_dialog.dart';
import '../widgets/product_thumbnail.dart';
import 'product_details_page.dart';

/// Catálogo maestro compacto. La ficha completa se abre desde la fila.
class ProductsPage extends StatefulWidget {
  const ProductsPage({
    required this.controller,
    required this.onInventory,
    this.onOpen,
    super.key,
  });
  final PharmacyController controller;
  final VoidCallback onInventory;
  final ValueChanged<String>? onOpen;
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String _query = '', _category = 'Todas', _state = 'Todos';
  String? _selected;
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(Product p) {
    if (widget.onOpen != null) {
      widget.onOpen!(p.id);
    } else {
      setState(() => _selected = p.id);
    }
  }

  Future<void> _register([Product? product]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) =>
          ProductFormDialog(controller: widget.controller, product: product),
    );
    if (saved == true && mounted && product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Producto registrado. Recibe sus existencias en Lotes.',
          ),
        ),
      );
    }
  }

  Future<void> _restoreImages() async {
    await confirmCommand(
      context,
      '¿Recuperar imágenes?',
      'Se recuperarán las ilustraciones locales de las fichas reconocidas. Los precios, lotes y ventas se conservan.',
      widget.controller.restoreMissingDemoIllustrations,
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggle(Product p) => confirmCommand(
    context,
    p.active ? '¿Archivar producto?' : '¿Reactivar producto?',
    'Se conservarán sus lotes y comprobantes.',
    () => widget.controller.toggleProduct(p.id),
  );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final data = widget.controller;
      if (_selected != null) {
        return ProductDetailsPage(
          controller: data,
          productId: _selected!,
          onBack: () => setState(() => _selected = null),
          onLots: widget.onInventory,
        );
      }
      final categories = [
        'Todas',
        ...({...data.products.map((p) => p.category)}.toList()..sort()),
      ];
      final category = categories.contains(_category) ? _category : 'Todas';
      final products = data.products
          .where(
            (p) =>
                (_state == 'Todos' || p.active == (_state == 'Activos')) &&
                (category == 'Todas' || p.category == category) &&
                [
                  p.name,
                  p.code,
                  p.category,
                  p.barcode,
                  p.activeIngredient,
                  p.dosage,
                  p.manufacturer,
                  p.origin,
                ].any((v) => v.toLowerCase().contains(_query)),
          )
          .toList();
      return CompactWorkspace(
        title: 'Productos',
        subtitle: '${data.products.length} fichas en el catálogo',
        actions: [
          OutlinedButton.icon(
            onPressed: widget.onInventory,
            icon: const Icon(Icons.inventory_2_outlined, size: 17),
            label: const Text('Ir a inventario y lotes'),
          ),
          if (data.productsWithRecoverableIllustration.isNotEmpty)
            IconButton(
              key: const Key('products-restore-images'),
              tooltip: 'Recuperar imágenes',
              onPressed: _restoreImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
            ),
          if (data.isAdministrator)
            FilledButton.icon(
              onPressed: () => _register(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Registrar producto'),
            ),
        ],
        toolbar: RecordToolbar(
          search: TextField(
            key: const Key('products-search'),
            controller: _search,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'Buscar producto o código',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
          filters: [
            RecordFilter(
              label: 'Categoría',
              value: category,
              options: categories,
              onChanged: (v) => setState(() => _category = v),
            ),
            RecordFilter(
              label: 'Estado',
              value: _state,
              options: const ['Todos', 'Activos', 'Archivados'],
              onChanged: (v) => setState(() => _state = v),
            ),
          ],
        ),
        child: CompactRecords(
          itemCount: products.length,
          resetKey: '$_query|$category|$_state|${data.workingBranchId}',
          emptyText: 'No hay fichas que coincidan con la búsqueda.',
          columns: const [
            RecordColumn('Producto', flex: 3),
            RecordColumn('Categoría', flex: 1.4),
            RecordColumn('Presentación', flex: 1.6),
            RecordColumn('Precio', flex: 1.1),
            RecordColumn('Estado'),
            RecordColumn('', flex: .5),
          ],
          rowBuilder: (index) {
            final p = products[index];
            Widget thumbnail() => ProductThumbnail(
              illustrationKey: p.illustrationKey,
              width: 38,
              height: 38,
            );
            Widget menu() => RecordActions(
              recordKey: 'product-actions-${p.id}',
              actions: [
                ('Ver detalle', () => _open(p)),
                if (data.isAdministrator) ...[
                  ('Editar ficha', () => _register(p)),
                  (p.active ? 'Archivar' : 'Reactivar', () => _toggle(p)),
                ],
              ],
            );
            return RecordRow(
              onOpen: () => _open(p),
              cells: [
                RecordIdentity(
                  title: p.name,
                  subtitle: p.code,
                  leading: thumbnail(),
                ),
                RecordText(p.category),
                RecordText(p.presentation),
                RecordText(
                  p.price > 0
                      ? '${formatCordobas(p.price)} / ${p.unit}'
                      : 'Por definir',
                  bold: true,
                ),
                RecordText(p.active ? 'Activo' : 'Archivado'),
                menu(),
              ],
              mobile: RecordTile(
                title: p.name,
                subtitle: '${p.code} · ${p.category}',
                metadata:
                    '${formatCordobas(p.price)} / ${p.unit} · ${p.active ? 'Activo' : 'Archivado'}',
                leading: thumbnail(),
                trailing: menu(),
                onOpen: () => _open(p),
              ),
            );
          },
        ),
      );
    },
  );
}
