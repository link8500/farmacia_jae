import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../inventory/models/inventory_summary.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../products/widgets/product_thumbnail.dart';

// Se mantiene la importación pública del módulo, pero el gráfico vive en su
// propio widget para no mezclar configuración de fl_chart con las alertas.
export 'sales_chart_card.dart';

/// Muestra existencias bajo mínimo y productos próximos a vencer.
class InventoryAlertsCard extends StatelessWidget {
  /// Crea el resumen de alertas de inventario.
  const InventoryAlertsCard({
    required this.entries,
    required this.onNavigate,
    super.key,
  });

  /// Proyecciones de stock y caducidad calculadas desde los lotes.
  final List<InventorySummary> entries;

  /// Navegación hacia el inventario completo.
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final items = entries
        .where(
          (item) => item.isLow || item.hasExpiringLots || item.hasExpiredLots,
        )
        .take(3)
        .toList();
    return SectionCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Alertas de inventario',
                  style: TextStyle(
                    color: context.palette.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onNavigate(2),
                icon: Icon(
                  Icons.arrow_forward_rounded,
                  color: context.palette.blue,
                ),
              ),
            ],
          ),
          ...items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              // La miniatura usa la misma asociación que Productos y Lotes.
              // El estado sigue indicado por texto, sin depender de la foto.
              leading: ProductThumbnail(
                illustrationKey: item.product.illustrationKey,
                width: 40,
                height: 40,
              ),
              title: Text(
                item.product.name,
                style: TextStyle(
                  color: context.palette.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                item.isLow
                    ? 'Disponibles: ${item.availableQuantity} · ${item.product.unit}'
                    : item.hasExpiredLots
                    ? 'Hay lotes vencidos: no vender'
                    : 'Próximo lote: ${formatDate(item.nextExpiry!)}',
                style: TextStyle(color: context.palette.muted, fontSize: 10),
              ),
              trailing: Text(
                item.isLow ? 'Reponer' : 'Revisar',
                style: TextStyle(
                  color: item.isLow ? AppColors.orange : AppColors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Acciones frecuentes de la operación diaria.
class QuickActionsCard extends StatelessWidget {
  /// Crea el grupo de accesos rápidos.
  const QuickActionsCard({
    required this.onNavigate,
    this.isAdministrator = true,
    super.key,
  });

  final bool isAdministrator;

  /// Navegación usada por cada acceso.
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Wrap(
        spacing: 20,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Accesos rápidos',
            style: TextStyle(
              color: context.palette.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          _QuickAction(
            label: 'Nueva venta',
            icon: Icons.add_shopping_cart_rounded,
            color: context.palette.blue,
            onTap: () => onNavigate(1),
          ),
          if (isAdministrator)
            _QuickAction(
              label: 'Registrar compra',
              icon: Icons.add_box_rounded,
              color: AppColors.green,
              onTap: () => onNavigate(3),
            ),
          _QuickAction(
            label: 'Ver lotes',
            icon: Icons.inventory_rounded,
            color: AppColors.orange,
            onTap: () => onNavigate(2),
          ),
          if (isAdministrator)
            _QuickAction(
              label: 'Generar reporte',
              icon: Icons.assessment_rounded,
              color: context.palette.blue,
              onTap: () => onNavigate(6),
            ),
        ],
      ),
    );
  }
}

/// Botón pequeño reutilizado por los accesos rápidos.
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            // El tamaño de lectura configurable no debe forzar una fila más
            // ancha que el panel: la etiqueta puede ocupar una segunda línea.
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: context.palette.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Actividad generada por comandos del estado local, no ventas ficticias.
class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({required this.controller, super.key});
  final PharmacyController controller;
  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actividad reciente',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        if (controller.audit.isEmpty)
          const Text('Todavía no hay operaciones registradas.'),
        for (final entry in controller.audit.reversed.take(6))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(entry.action),
            subtitle: Text('${entry.actorName} · ${entry.detail}'),
            trailing: Text(
              '${entry.at.hour.toString().padLeft(2, '0')}:${entry.at.minute.toString().padLeft(2, '0')}',
            ),
          ),
      ],
    ),
  );
}

/// Estado de controles de seguridad, calidad y continuidad.
class ControlsCard extends StatelessWidget {
  /// Crea el panel de gobernanza.
  const ControlsCard({
    required this.onNavigate,
    required this.controller,
    super.key,
  });
  final PharmacyController controller;

  /// Navegación hacia configuración y controles.
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado de la operación',
                      style: TextStyle(
                        color: context.palette.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Estado del prototipo en este navegador; no representa monitoreo de un servidor.',
                      style: TextStyle(
                        color: context.palette.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(text: 'Sin backend', color: context.palette.blue),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 26,
            runSpacing: 14,
            children: [
              ControlItem(
                icon: Icons.verified_user_outlined,
                title: 'Accesos',
                value: '${controller.staff.length} cuentas locales',
                color: AppColors.green,
              ),
              ControlItem(
                icon: Icons.cloud_done_outlined,
                title: 'Respaldo',
                value: controller.lastBackupAt == null
                    ? 'No generado'
                    : formatDate(controller.lastBackupAt!),
                color: context.palette.blue,
              ),
              ControlItem(
                icon: Icons.fact_check_outlined,
                title: 'Auditoría',
                value: '${controller.audit.length} operaciones',
                color: AppColors.orange,
              ),
              ControlItem(
                icon: Icons.speed_outlined,
                title: 'Caja',
                value: !controller.cashEnabled
                    ? 'Desactivada'
                    : controller.openCash == null
                    ? 'Cerrada'
                    : 'Abierta',
                color: context.palette.blue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => onNavigate(8),
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: const Text('Datos y mantenimiento'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicador individual dentro del panel de gobernanza.
class ControlItem extends StatelessWidget {
  /// Crea un indicador de control.
  const ControlItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Row(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: context.palette.muted, fontSize: 10),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.palette.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
