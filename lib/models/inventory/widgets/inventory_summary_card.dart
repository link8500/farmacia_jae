import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_pill.dart';
import '../models/inventory_summary.dart';

/// Resumen por producto derivado de todos sus lotes, no una ficha con stock.
class InventorySummaryCard extends StatelessWidget {
  const InventorySummaryCard({required this.entries, super.key});
  final List<InventorySummary> entries;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Existencias por producto · ${entries.length} ${entries.length == 1 ? 'resultado' : 'resultados'}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: context.palette.ink,
          ),
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No hay existencias que coincidan con el filtro.'),
          ),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.product.code} · ${entry.product.name}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                // Wrap conserva cantidades, alertas y fechas sin columnas rígidas.
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${entry.availableQuantity} disponibles · ${entry.product.unit}',
                      style: TextStyle(
                        color: context.palette.blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text('${entry.lotCount} lotes con saldo'),
                    Text('Mínimo: ${entry.product.minimum}'),
                    StatusPill(
                      text: entry.hasExpiredLots
                          ? 'Con vencidos'
                          : entry.isLow
                          ? 'Bajo mínimo'
                          : entry.hasExpiringLots
                          ? 'Por vencer'
                          : 'Disponible',
                      color: entry.hasExpiredLots
                          ? AppColors.red
                          : entry.isLow
                          ? AppColors.orange
                          : entry.hasExpiringLots
                          ? AppColors.red
                          : AppColors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  entry.nextExpiry == null
                      ? 'Sin lotes disponibles para venta'
                      : 'Próximo vencimiento: ${formatDate(entry.nextExpiry!)}',
                  style: TextStyle(color: context.palette.muted, fontSize: 12),
                ),
                if (entry.totalQuantity != entry.availableQuantity)
                  Text(
                    'Saldo físico: ${entry.totalQuantity}; no disponibles: ${entry.totalQuantity - entry.availableQuantity}',
                    style: const TextStyle(color: AppColors.red, fontSize: 12),
                  ),
                Divider(height: 24, color: context.palette.border),
              ],
            ),
          ),
      ],
    ),
  );
}
