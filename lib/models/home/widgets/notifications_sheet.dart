import 'package:flutter/material.dart';
import '../../../shared/themes/app_colors.dart';

/// Hoja inferior con alertas operativas importantes.
class NotificationsSheet extends StatelessWidget {
  /// Crea el contenido de notificaciones.
  const NotificationsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notificaciones',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 15),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.warning_amber_rounded, color: AppColors.orange),
            title: Text('2 productos están bajo mínimo'),
            subtitle: Text('Revisa el inventario para generar una reposición.'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.event_busy_rounded, color: AppColors.red),
            title: Text('3 lotes próximos a vencer'),
            subtitle: Text(
              'Hay existencias que vencen en los próximos 90 días.',
            ),
          ),
        ],
      ),
    );
  }
}
