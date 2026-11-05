import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../widgets/lot_form_dialog.dart';
import '../widgets/inventory_actions.dart';
import 'lot_details_page.dart';

/// Existencias y lotes en tablas paginadas. Cada producto y lote abre su contexto
/// en una vista independiente, conservando el filtro del listado.
class InventoryPage extends StatefulWidget {
  const InventoryPage({
    required this.controller,
    required this.onProducts,
    this.productId,
    this.lotsView = false,
    this.onProductLots,
    this.onAllLots,
    this.onSummary,
    this.onLot,
    super.key,
  });
  final PharmacyController controller;
  final VoidCallback onProducts;
  final String? productId;
  final bool lotsView;
  final ValueChanged<String>? onProductLots, onLot;
  final VoidCallback? onAllLots, onSummary;
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  late final TextEditingController _search;
  late bool _showLots;
  String? _product, _lot;
  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.controller.inventorySearch);
    _showLots = widget.lotsView;
    _product = widget.productId;
  }

  @override
  void didUpdateWidget(covariant InventoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.productId != oldWidget.productId ||
        widget.lotsView != oldWidget.lotsView) {
      _showLots = widget.lotsView;
      _product = widget.productId;
      _lot = null;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _summary() {
    if (widget.onSummary != null) {
      widget.onSummary!();
    } else {
      setState(() {
        _showLots = false;
        _product = null;
        _lot = null;
      });
    }
  }

  void _allLots() {
    if (widget.onAllLots != null) {
      widget.onAllLots!();
    } else {
      setState(() {
        _showLots = true;
        _product = null;
      });
    }
  }

  void _productLots(String id) {
    if (widget.onProductLots != null) {
      widget.onProductLots!(id);
    } else {
      setState(() {
        _showLots = true;
        _product = id;
      });
    }
  }

  void _openLot(String id) {
    if (widget.onLot != null) {
      widget.onLot!(id);
    } else {
      setState(() => _lot = id);
    }
  }

  Future<void> _receive() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) =>
          LotFormDialog(controller: widget.controller, productId: _product),
    );
    if (saved == true && mounted) {
      if (_product != null) {
        _productLots(_product!);
      } else {
        _allLots();
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final data = widget.controller;
      if (_lot != null) {
        return LotDetailsPage(
          controller: data,
          lotId: _lot!,
          onBack: () => setState(() => _lot = null),
        );
      }
      final entries = data.visibleInventory;
      final lots = data.visibleLots
          .where((l) => _product == null || l.productId == _product)
          .toList();
      final selected = _product == null ? null : data.productById(_product!);
      final showLots = _showLots || _product != null;
      return CompactWorkspace(
        title: _product != null
            ? 'Lotes de ${selected?.name ?? 'producto no disponible'}'
            : 'Lotes',
        subtitle:
            '${data.products.length} productos · ${data.lots.length} lotes · ${data.availableTotal} unidades disponibles',
        actions: [
          if (_product != null)
            OutlinedButton.icon(
              onPressed: _summary,
              icon: const Icon(Icons.arrow_back, size: 17),
              label: const Text('Volver a lotes'),
            )
          else
            OutlinedButton(
              onPressed: widget.onProducts,
              child: const Text('Abrir catálogo de productos'),
            ),
          FilledButton.icon(
            onPressed: data.products.where((p) => p.active).isEmpty
                ? null
                : _receive,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Recibir lote'),
          ),
        ],
        toolbar: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecordToolbar(
              search: TextField(
                key: const Key('inventory-search'),
                controller: _search,
                onChanged: data.setInventorySearch,
                decoration: const InputDecoration(
                  hintText: 'Buscar producto, código o lote',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
              filters: [
                RecordFilter(
                  label: 'Existencias',
                  value: data.inventoryFilter,
                  options: const [
                    'Todos',
                    'Bajo mínimo',
                    'Por vencer',
                    'Vencidos',
                  ],
                  onChanged: data.setInventoryFilter,
                ),
              ],
            ),
            if (_product == null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: const Text('Existencias por producto'),
                    selected: !showLots,
                    onSelected: (_) => _summary(),
                  ),
                  ChoiceChip(
                    label: const Text('Detalle de lotes'),
                    selected: showLots,
                    onSelected: (_) => _allLots(),
                  ),
                ],
              ),
            ],
          ],
        ),
        child: CompactRecords(
          itemCount: showLots ? lots.length : entries.length,
          resetKey:
              '${data.inventorySearch}|${data.inventoryFilter}|$_product|$showLots|${data.workingBranchId}',
          emptyText: 'No hay existencias para este filtro.',
          columns: showLots
              ? const [
                  RecordColumn('Lote', flex: 1.5),
                  RecordColumn('Producto', flex: 2.5),
                  RecordColumn('Cantidad'),
                  RecordColumn('Vencimiento', flex: 1.2),
                  RecordColumn('Ubicación', flex: 1.4),
                  RecordColumn('Estado'),
                  RecordColumn('', flex: .5),
                ]
              : const [
                  RecordColumn('Producto', flex: 3),
                  RecordColumn('Disponible', flex: 1.3),
                  RecordColumn('Mínimo'),
                  RecordColumn('Lotes', flex: .65),
                  RecordColumn('Próximo vencimiento', flex: 1.4),
                  RecordColumn('', flex: .5),
                ],
          rowBuilder: (i) {
            if (showLots) {
              final lot = lots[i], p = data.productById(lot.productId);
              final state = lot.quantity == 0
                  ? 'Agotado'
                  : p?.active != true
                  ? 'No vendible'
                  : lot.isExpired(data.today)
                  ? 'Vencido'
                  : lot.isExpiring(data.today)
                  ? 'Por vencer'
                  : 'Disponible';
              Widget menu() => RecordActions(
                recordKey: 'lot-actions-${lot.id}',
                actions: [
                  ('Ver detalle', () => _openLot(lot.id)),
                  if (data.isAdministrator)
                    (
                      'Ajustar existencias',
                      () => adjustInventoryLot(context, data, lot),
                    ),
                ],
              );
              return RecordRow(
                onOpen: () => _openLot(lot.id),
                cells: [
                  RecordText(lot.code, bold: true),
                  RecordText(p?.name ?? ''),
                  RecordText('${lot.quantity} · ${p?.unit ?? ''}'),
                  RecordText(formatDate(lot.expiry)),
                  RecordText(
                    lot.location.isEmpty ? 'Sin ubicar' : lot.location,
                  ),
                  RecordText(state),
                  menu(),
                ],
                mobile: RecordTile(
                  title: lot.code,
                  subtitle:
                      '${p?.name ?? ''} · ${lot.location.isEmpty ? 'Sin ubicar' : lot.location}',
                  metadata:
                      '${lot.quantity} · ${p?.unit ?? ''} · ${formatDate(lot.expiry)} · $state',
                  trailing: menu(),
                  onOpen: () => _openLot(lot.id),
                ),
              );
            }
            final entry = entries[i], p = entry.product;
            Widget menu() => RecordActions(
              recordKey: 'inventory-actions-${p.id}',
              actions: [('Ver lotes', () => _productLots(p.id))],
            );
            return RecordRow(
              onOpen: () => _productLots(p.id),
              cells: [
                RecordIdentity(title: p.name, subtitle: p.code),
                RecordText(
                  '${entry.availableQuantity} · ${p.unit}',
                  bold: true,
                ),
                RecordText('${p.minimum}'),
                RecordText('${entry.lotCount}'),
                RecordText(
                  entry.nextExpiry == null
                      ? '—'
                      : formatDate(entry.nextExpiry!),
                ),
                menu(),
              ],
              mobile: RecordTile(
                title: p.name,
                subtitle: '${p.code} · ${entry.lotCount} lotes',
                metadata:
                    '${entry.availableQuantity} · ${p.unit} · Mínimo: ${p.minimum}',
                trailing: menu(),
                onOpen: () => _productLots(p.id),
              ),
            );
          },
        ),
      );
    },
  );
}
