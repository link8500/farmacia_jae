import 'package:flutter/material.dart';
import '../../products/models/product.dart';
import '../../products/widgets/product_thumbnail.dart';
import '../../settings/models/app_preferences.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../core/utils/formatters.dart';

/// Catálogo de facturación: filtros reales, lector por teclado y tarjetas
/// rectangulares con estados claros. La vista no modifica precios ni stock.
class ProductCatalog extends StatefulWidget {
  const ProductCatalog({
    required this.products,
    required this.onAdd,
    required this.availableStock,
    this.layout = CatalogLayout.cards,
    this.onLayout,
    super.key,
  });
  final List<Product> products;
  final ValueChanged<Product> onAdd;
  final int Function(Product) availableStock;
  final CatalogLayout layout;
  final ValueChanged<CatalogLayout>? onLayout;
  @override
  State<ProductCatalog> createState() => _ProductCatalogState();
}

class _ProductCatalogState extends State<ProductCatalog> {
  final _search = TextEditingController();
  String _query = '', _category = 'Todos';
  bool _onlyStock = false;
  int _limit = 24;
  CatalogLayout? _localLayout;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _scan(String code) {
    final exact = widget.products.where(
      (p) =>
          p.active &&
          (p.code.toLowerCase() == code.trim().toLowerCase() ||
              (p.barcode.isNotEmpty && p.barcode == code.trim())),
    );
    if (exact.length == 1 &&
        exact.single.price > 0 &&
        widget.availableStock(exact.single) > 0) {
      widget.onAdd(exact.single);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final narrow = box.maxWidth < 420;
      final categories =
          widget.products
              .where((p) => p.active)
              .map((p) => p.category)
              .toSet()
              .toList()
            ..sort();
      final category = categories.contains(_category) ? _category : 'Todos';
      final products = widget.products
          .where(
            (p) =>
                p.active &&
                (category == 'Todos' || p.category == category) &&
                (!_onlyStock || widget.availableStock(p) > 0) &&
                [
                  p.code,
                  p.barcode,
                  p.name,
                  p.category,
                  p.activeIngredient,
                  p.dosage,
                  p.presentation,
                ].any((text) => text.toLowerCase().contains(_query)),
          )
          .toList();
      final layout = widget.onLayout == null
          ? _localLayout ?? widget.layout
          : widget.layout;
      final bounded =
          box.hasBoundedHeight &&
          box.maxHeight >=
              (MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 600 : 420);
      final scrollBody = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 38),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 34,
                    color: context.palette.muted,
                  ),
                  const SizedBox(height: 12),
                  const Text('No hay productos para estos filtros.'),
                  const SizedBox(height: 6),
                  Text(
                    'Prueba otra búsqueda o categoría.',
                    style: TextStyle(color: context.palette.muted),
                  ),
                ],
              ),
            ),
          if (layout == CatalogLayout.cards)
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = (constraints.maxWidth / 205).floor().clamp(
                  1,
                  4,
                );
                final width =
                    (constraints.maxWidth - 12 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final product in products.take(_limit))
                      SizedBox(
                        width: width,
                        child: _ProductTile(
                          product: product,
                          stock: widget.availableStock(product),
                          onAdd: () => widget.onAdd(product),
                          // Una sola columna usa foto lateral: nombre, precio
                          // y acción caben juntos sin una ficha vertical enorme.
                          list: columns == 1,
                        ),
                      ),
                  ],
                );
              },
            )
          else
            Column(
              children: [
                for (final product in products.take(_limit))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ProductTile(
                      product: product,
                      stock: widget.availableStock(product),
                      onAdd: () => widget.onAdd(product),
                      list: true,
                    ),
                  ),
              ],
            ),
          if (products.length > _limit)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: OutlinedButton(
                onPressed: () => setState(() => _limit += 24),
                child: const Text('Mostrar más productos'),
              ),
            ),
        ],
      );
      final panel = SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catálogo de productos',
                      style: TextStyle(
                        fontSize: narrow ? 15 : 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      narrow
                          ? '${products.length} productos'
                          : '${products.length} productos · inventario de tu sucursal',
                      style: TextStyle(
                        color: context.palette.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SegmentedButton<CatalogLayout>(
                  key: const Key('sales-catalog-layout'),
                  style: narrow
                      ? const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          padding: WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 8),
                          ),
                          minimumSize: WidgetStatePropertyAll(Size(36, 32)),
                        )
                      : null,
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: CatalogLayout.cards,
                      icon: Icon(Icons.grid_view_rounded, size: 18),
                      tooltip: 'Vista en tarjetas',
                    ),
                    ButtonSegment(
                      value: CatalogLayout.list,
                      icon: Icon(Icons.view_list_rounded, size: 20),
                      tooltip: 'Vista en lista',
                    ),
                  ],
                  selected: {layout},
                  onSelectionChanged: (v) {
                    if (widget.onLayout != null) {
                      widget.onLayout!(v.single);
                    } else {
                      setState(() => _localLayout = v.single);
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: narrow ? 12 : 20),
            TextField(
              key: const Key('sales-search'),
              controller: _search,
              onChanged: (value) => setState(() {
                _query = value.trim().toLowerCase();
                _limit = 24;
              }),
              onSubmitted: _scan,
              decoration: InputDecoration(
                hintText: 'Buscar producto o código de barras',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? const Tooltip(
                        message:
                            'El lector de barras puede introducir el código y pulsar Enter',
                        child: Icon(Icons.qr_code_scanner_rounded, size: 20),
                      )
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () => setState(() {
                          _search.clear();
                          _query = '';
                          _limit = 24;
                        }),
                        icon: const Icon(Icons.close, size: 18),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            // Todas las categorías son accesibles con ratón, teclado o táctil;
            // no quedan ocultas en una fila horizontal que exige gestos laterales.
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: narrow
                        ? (constraints.maxWidth - 60).clamp(100, 360)
                        : 250,
                    child: DropdownButtonFormField<String>(
                      key: const Key('sales-category'),
                      initialValue: category,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon: Icon(Icons.category_outlined, size: 18),
                      ),
                      items: [
                        for (final c in ['Todos', ...categories])
                          DropdownMenuItem(
                            value: c,
                            child: Text(
                              c == 'Todos' ? 'Todas las categorías' : c,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (c) => setState(() {
                        _category = c ?? 'Todos';
                        _limit = 24;
                      }),
                    ),
                  ),
                  if (narrow)
                    IconButton.filledTonal(
                      tooltip: _onlyStock
                          ? 'Mostrar todos los productos'
                          : 'Solo con existencias',
                      isSelected: _onlyStock,
                      icon: const Icon(Icons.inventory_2_outlined, size: 20),
                      onPressed: () => setState(() {
                        _onlyStock = !_onlyStock;
                        _limit = 24;
                      }),
                    )
                  else
                    FilterChip(
                      label: const Text('Solo con existencias'),
                      avatar: const Icon(Icons.inventory_2_outlined, size: 16),
                      selected: _onlyStock,
                      onSelected: (v) => setState(() {
                        _onlyStock = v;
                        _limit = 24;
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (bounded)
              Expanded(child: SingleChildScrollView(child: scrollBody))
            else
              scrollBody,
          ],
        ),
      );
      return box.hasBoundedHeight && !bounded
          ? SingleChildScrollView(child: panel)
          : panel;
    },
  );
}

/// Material e InkWell conservan foco, teclado y respuesta táctil; la tarjeta no
/// hereda el borde tipo cápsula de un OutlinedButton de Material 3.
class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.stock,
    required this.onAdd,
    this.list = false,
  });
  final Product product;
  final int stock;
  final VoidCallback onAdd;
  final bool list;
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final compact = Theme.of(context).visualDensity.vertical < 0;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: stock == 0 ? palette.canvas : palette.paleBlue,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        stock == 0 ? 'Sin existencias' : '$stock disponibles',
        style: TextStyle(
          color: stock == 0 ? palette.muted : palette.blue,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final name = Text(
      product.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: palette.ink,
        fontWeight: FontWeight.w700,
        fontSize: 14,
        height: 1.35,
      ),
    );
    final price = Text(
      product.price > 0 ? formatCordobas(product.price) : 'Precio pendiente',
      style: TextStyle(
        color: palette.ink,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
    return Semantics(
      button: true,
      enabled: stock > 0 && product.price > 0,
      excludeSemantics: true,
      onTap: stock > 0 && product.price > 0 ? onAdd : null,
      label:
          'Añadir ${product.name}. ${formatCordobas(product.price)}. $stock disponibles.',
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: palette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('add-product-${product.id}'),
          onTap: stock == 0 || product.price <= 0 ? null : onAdd,
          child: Padding(
            padding: EdgeInsets.all(compact ? 12 : 16),
            child: list
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProductThumbnail(
                            illustrationKey: product.illustrationKey,
                            width: 68,
                            height: 68,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                name,
                                const SizedBox(height: 5),
                                Text(
                                  '${product.code} · ${product.presentation}${product.requiresPrescription ? ' · Bajo receta' : ''}',
                                  style: TextStyle(
                                    color: palette.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          badge,
                          price,
                          Icon(
                            Icons.add_circle_outline,
                            size: 24,
                            color: stock == 0 ? palette.muted : palette.blue,
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // La foto es orientativa; código, nombre y presentación
                      // permanecen visibles como identificación del artículo.
                      ProductThumbnail(
                        illustrationKey: product.illustrationKey,
                        height: compact ? 108 : 128,
                        showCaption: true,
                      ),
                      const SizedBox(height: 12),
                      Align(alignment: Alignment.centerLeft, child: badge),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 40 * MediaQuery.textScalerOf(context).scale(1),
                        child: name,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.presentation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: palette.muted, fontSize: 11),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: price),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: stock == 0
                                  ? palette.canvas
                                  : palette.paleBlue,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              size: 20,
                              color: stock == 0 ? palette.muted : palette.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
