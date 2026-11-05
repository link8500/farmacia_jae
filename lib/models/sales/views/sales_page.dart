import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../shared/widgets/compact_workspace.dart';
import '../../../shared/widgets/record_form_dialog.dart';
import '../../settings/models/app_preferences.dart';
import '../models/sale_receipt.dart';
import '../widgets/cart_card.dart';
import '../widgets/sales_history.dart';
import '../../../shared/widgets/workspace_sections.dart';
import '../widgets/product_catalog.dart';
import '../widgets/receipt_dialog.dart';
import '../widgets/checkout_dialog.dart';

/// POS local completo: carrito, cliente, cobro, cambio e historial inmutable.
class SalesPage extends StatefulWidget {
  const SalesPage({
    required this.controller,
    required this.onMessage,
    this.confirmClearSale = true,
    this.onCash,
    this.catalogLayout = CatalogLayout.cards,
    this.onCatalogLayout,
    this.historyView,
    this.onHistoryView,
    super.key,
  });
  final PharmacyController controller;
  final ValueChanged<String> onMessage;
  final bool confirmClearSale;
  final VoidCallback? onCash;
  final CatalogLayout catalogLayout;
  final ValueChanged<CatalogLayout>? onCatalogLayout;

  /// El router controla la sub-vista; los usos aislados conservan estado local.
  final bool? historyView;
  final ValueChanged<bool>? onHistoryView;
  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  int _localTab = 0;
  bool _mobileCart = false;
  int get _tab =>
      widget.historyView == null ? _localTab : (widget.historyView! ? 1 : 0);
  void _selectTab(int tab) {
    if (widget.onHistoryView != null) {
      widget.onHistoryView!(tab == 1);
    } else {
      setState(() => _localTab = tab);
    }
  }

  Future<void> _clear() async {
    if (widget.controller.cart.isEmpty) return;
    if (!widget.confirmClearSale) {
      widget.controller.clearCart();
      return;
    }
    await confirmCommand(
      context,
      '¿Vaciar la venta?',
      'Se quitarán las líneas del carrito. Esto no modifica el inventario.',
      () {
        widget.controller.clearCart();
        return null;
      },
    );
  }

  Future<void> _checkout() async {
    final controller = widget.controller;
    if (controller.billingAssignmentError != null) {
      widget.onMessage(controller.billingAssignmentError!);
      return;
    }
    final sale = await showDialog<SaleReceipt>(
      context: context,
      builder: (_) => CheckoutDialog(controller: controller),
    );
    if (sale != null && mounted) {
      await showReceipt(context, sale, controller: controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (_tab == 1) {
      return SalesHistory(controller: controller, onNew: () => _selectTab(0));
    }
    return CompactWorkspace(
      title: 'Facturación',
      subtitle: 'Prepara los productos y confirma el cobro.',
      toolbar: WorkspaceTabs(
        labels: const ['Nueva factura', 'Historial de facturas'],
        selected: _tab,
        onSelected: _selectTab,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.billingAssignmentError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                controller.billingAssignmentError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (controller.cashEnabled &&
              controller.openCash == null &&
              widget.onCash != null)
            TextButton(
              onPressed: widget.onCash,
              child: const Text('Ir a caja'),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final wide = box.maxWidth >= 960;
                final catalog = ProductCatalog(
                  key: ValueKey(controller.workingBranchId),
                  layout: widget.catalogLayout,
                  onLayout: widget.onCatalogLayout,
                  products: controller.products,
                  availableStock: controller.availableStock,
                  onAdd: (product) {
                    if (!controller.addToCart(product)) {
                      widget.onMessage(
                        'No quedan más unidades disponibles de ese producto.',
                      );
                    }
                  },
                );
                final cart = CartCard(
                  cart: controller.cart,
                  total: controller.cartTotal,
                  onRemove: controller.removeFromCart,
                  onDelete: controller.discardCartLine,
                  checkoutEnabled:
                      controller.billingAssignmentError == null &&
                      (!controller.cashEnabled || controller.openCash != null),
                  onIncrement: (line) {
                    if (!controller.addToCart(
                      controller.productById(line.product.id)!,
                    )) {
                      widget.onMessage('Cantidad máxima disponible alcanzada.');
                    }
                  },
                  onClear: _clear,
                  onFinish: _checkout,
                );
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 6, child: catalog),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: cart),
                    ],
                  );
                }
                // En una pantalla estrecha cada tarea ocupa el área disponible.
                // El carrito permanece en el controlador al alternar las dos vistas.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WorkspaceTabs(
                      labels: ['Catálogo', 'Venta (${controller.cart.length})'],
                      selected: _mobileCart ? 1 : 0,
                      onSelected: (i) => setState(() => _mobileCart = i == 1),
                    ),
                    const SizedBox(height: 10),
                    Expanded(child: _mobileCart ? cart : catalog),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
