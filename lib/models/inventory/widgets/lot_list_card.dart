import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../products/models/product.dart';
import '../models/inventory_lot.dart';

/// Lista reutilizable de lotes con la ficha resuelta por ID, no duplicada.
class LotListCard extends StatelessWidget {
  const LotListCard({
    required this.lots,
    required this.productById,
    required this.today,
    this.onAdjust,
    super.key,
  });
  final List<InventoryLot> lots;
  final Product? Function(String) productById;
  final DateTime today;
  final ValueChanged<InventoryLot>? onAdjust;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalle de lotes · ${lots.length} ${lots.length == 1 ? 'resultado' : 'resultados'}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: context.palette.ink,
          ),
        ),
        const SizedBox(height: 12),
        if (lots.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No hay lotes que coincidan con el filtro.'),
          ),
        for (final lot in lots) _row(context, lot),
      ],
    ),
  );

  Widget _row(BuildContext context, InventoryLot lot) {
    final product = productById(lot.productId)!;
    final exhausted = lot.quantity == 0;
    final expired = lot.isExpired(today);
    final expiring = lot.isExpiring(today);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${lot.code} · ${product.name}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          // Metadatos apilables en móvil; ninguna tabla exige scroll horizontal.
          Wrap(
            spacing: 18,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${lot.quantity} · ${product.unit}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: context.palette.blue,
                ),
              ),
              Text('Vence ${formatDate(lot.expiry)}'),
              Text(
                'Recibido ${formatDate(lot.receivedAt)}',
                style: TextStyle(color: context.palette.muted),
              ),
              StatusPill(
                text: exhausted
                    ? 'Agotado'
                    : expired
                    ? 'Vencido · no vender'
                    : expiring
                    ? 'Por vencer'
                    : 'Disponible',
                color: exhausted
                    ? context.palette.muted
                    : expired || expiring
                    ? AppColors.red
                    : AppColors.green,
              ),
            ],
          ),
          Divider(height: 24, color: context.palette.border),
          if (onAdjust != null)
            TextButton.icon(
              onPressed: () => onAdjust!(lot),
              icon: const Icon(Icons.tune),
              label: const Text('Ajustar cantidad'),
            ),
        ],
      ),
    );
  }
}
