import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/stat_card.dart';
import '../widgets/dashboard_sections.dart';

/// Resumen compacto: indicadores, comparativo y alertas. El historial y las
/// herramientas operativas se consultan en sus módulos, no alargan la portada.
class DashboardPage extends StatelessWidget {
  /// Crea el dashboard con el estado de farmacia y la navegación disponible.
  const DashboardPage({
    required this.controller,
    required this.onNavigate,
    this.isAdministrator = true,
    super.key,
  });

  /// Estado compartido de productos y ventas.
  final PharmacyController controller;

  /// Permite saltar a otra sección desde una acción rápida.
  final ValueChanged<int> onNavigate;

  /// Las acciones administrativas no se presentan al personal operativo.
  final bool isAdministrator;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Los paneles dejan de competir por espacio y se apilan en tabletas
        // pequeñas y móviles para mantener legibles sus contenidos.
        final padding = MediaQuery.sizeOf(context).width < 600 ? 16.0 : 24.0;
        final contentWidth = constraints.maxWidth - padding * 2;
        final columns = contentWidth >= 880
            ? 4
            : contentWidth >= 520
            ? 2
            : 1;
        final statWidth = (contentWidth - 16 * (columns - 1)) / columns;
        final widePanel = contentWidth >= 860
            ? (contentWidth - 20) * .66
            : contentWidth;
        final alertPanel = contentWidth >= 860
            ? (contentWidth - 20) * .34
            : contentWidth;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buenos días, equipo',
                style: TextStyle(
                  color: context.palette.ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Vista operativa de la farmacia · Registros locales del prototipo.',
                style: TextStyle(color: context.palette.muted, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  StatCard(
                    width: statWidth,
                    label: 'Ventas del día',
                    value: 'C\$ ${controller.revenueToday.toStringAsFixed(2)}',
                    detail: 'Ventas vigentes de hoy',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.green,
                    background: context.palette.positiveSurface,
                  ),
                  StatCard(
                    width: statWidth,
                    label: 'Productos en stock',
                    value: controller.stockTotal.toString(),
                    detail: 'Saldo físico actual',
                    icon: Icons.inventory_2_rounded,
                    color: context.palette.blue,
                    background: context.palette.paleBlue,
                  ),
                  StatCard(
                    width: statWidth,
                    label: 'Bajo mínimo',
                    value: controller.lowStockCount.toString(),
                    detail: 'Requieren atención',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.orange,
                    background: context.palette.warningSurface,
                  ),
                  StatCard(
                    width: statWidth,
                    label: 'Lotes por vencer',
                    value: controller.expiringCount.toString(),
                    detail: 'En próximos 90 días',
                    icon: Icons.event_busy_rounded,
                    color: AppColors.red,
                    background: context.palette.negativeSurface,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  SizedBox(
                    width: widePanel,
                    child: SalesChartCard(controller: controller),
                  ),
                  SizedBox(
                    width: alertPanel,
                    child: InventoryAlertsCard(
                      entries: controller.inventory,
                      onNavigate: onNavigate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              QuickActionsCard(
                onNavigate: onNavigate,
                isAdministrator: isAdministrator,
              ),
            ],
          ),
        );
      },
    );
  }
}
