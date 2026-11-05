import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';

/// Alertas derivadas del inventario real del prototipo, no cifras fijas.
class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({this.controller, super.key});
  final PharmacyController? controller;
  @override
  Widget build(BuildContext context) {
    final data = controller;
    if (data == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No hay datos operativos disponibles.'),
      );
    }
    return AnimatedBuilder(
      animation: data,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alertas de inventario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            if (data.alertsCount == 0)
              const Text('No hay alertas de stock o vencimiento.'),
            for (final entry in data.inventory.where(
              (e) => e.product.active && e.isLow,
            ))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.warning_amber_rounded),
                title: Text(entry.product.name),
                subtitle: Text(
                  '${entry.availableQuantity} disponibles · Mínimo ${entry.product.minimum}',
                ),
              ),
            for (final lot in data.lots.where(
              (l) =>
                  l.quantity > 0 &&
                  (l.isExpiring(data.today) || l.isExpired(data.today)),
            ))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_busy),
                title: Text(
                  '${data.productById(lot.productId)!.name} · ${lot.code}',
                ),
                subtitle: Text(
                  '${lot.isExpired(data.today) ? 'Vencido: no vender' : 'Por vencer'} · ${formatDate(lot.expiry)} · ${lot.quantity} unidades',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
