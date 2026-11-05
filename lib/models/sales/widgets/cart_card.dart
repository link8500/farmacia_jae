import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/sales/models/cart_line.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/section_card.dart';
import '../../products/widgets/product_thumbnail.dart';

/// Detalle de factura con controles legibles y cobro siempre localizado en el
/// pie. Cantidad, precio y total son datos del dominio, no copias modificables.
class CartCard extends StatelessWidget {
  const CartCard({
    required this.cart,
    required this.total,
    required this.onRemove,
    required this.onClear,
    required this.onFinish,
    this.onIncrement,
    this.onDelete,
    this.checkoutEnabled = true,
    super.key,
  });
  final List<CartLine> cart;
  final double total;
  final ValueChanged<CartLine> onRemove;
  final VoidCallback onClear, onFinish;
  final ValueChanged<CartLine>? onIncrement, onDelete;
  final bool checkoutEnabled;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final palette = context.palette;
      final units = cart.fold<int>(0, (n, l) => n + l.quantity);
      final bounded =
          box.hasBoundedHeight &&
          box.maxHeight >=
              (MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 540 : 360);
      final scrollBody = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cart.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 44),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: palette.canvas,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 32,
                      color: palette.muted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Tu venta empieza aquí',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona productos del catálogo para preparar la factura.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Column(
                children: [
                  for (final line in cart)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProductThumbnail(
                                illustrationKey: line.product.illustrationKey,
                                width: 36,
                                height: 36,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  line.product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (onDelete != null)
                                IconButton(
                                  tooltip:
                                      'Eliminar ${line.product.name} de la venta',
                                  onPressed: () => onDelete!(line),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            '${formatCordobas(line.product.price)} / ${line.product.unit}',
                            style: TextStyle(
                              color: palette.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 14,
                            runSpacing: 10,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: palette.border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip:
                                          'Quitar una unidad de ${line.product.name}',
                                      onPressed: () => onRemove(line),
                                      icon: const Icon(
                                        Icons.remove_rounded,
                                        size: 18,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      child: Text(
                                        '${line.quantity}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip:
                                          'Añadir una unidad de ${line.product.name}',
                                      onPressed: onIncrement == null
                                          ? null
                                          : () => onIncrement!(line),
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatCordobas(line.subtotal),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
      final panel = SectionCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalle de factura',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Venta en preparación',
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (cart.isNotEmpty)
                      TextButton.icon(
                        onPressed: onClear,
                        icon: const Icon(Icons.delete_sweep_outlined, size: 17),
                        label: const Text('Vaciar'),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: palette.border),
              if (bounded)
                Expanded(child: SingleChildScrollView(child: scrollBody))
              else
                scrollBody,
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: palette.canvas,
                  border: Border(top: BorderSide(color: palette.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 5,
                      children: [
                        Text(
                          '${cart.length} ${cart.length == 1 ? 'producto' : 'productos'} · $units ${units == 1 ? 'unidad' : 'unidades'} de venta',
                          style: TextStyle(color: palette.muted, fontSize: 11),
                        ),
                        const Text(
                          'Comprobante interno',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        const Text(
                          'Total a pagar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          formatCordobas(total),
                          style: TextStyle(
                            color: palette.blue,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.7,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: cart.isEmpty || !checkoutEnabled
                          ? null
                          : onFinish,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Completar venta'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Revisa los productos antes de confirmar el cobro.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      return box.hasBoundedHeight && !bounded
          ? SingleChildScrollView(child: panel)
          : panel;
    },
  );
}
