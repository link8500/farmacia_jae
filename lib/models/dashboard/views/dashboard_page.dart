import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../shared/widgets/stat_card.dart';
import '../widgets/dashboard_sections.dart';

/// Dashboard operativo con indicadores del negocio y de TI.
///
/// Resume las prioridades del diagnóstico: control financiero, existencias,
/// continuidad, trazabilidad y supervisión administrativa.
class DashboardPage extends StatelessWidget {
  /// Crea el dashboard con el estado de farmacia y la navegación disponible.
  const DashboardPage({
    required this.controller,
    required this.onNavigate,
    super.key,
  });

  /// Estado compartido de productos y ventas.
  final PharmacyController controller;

  /// Permite saltar a otra sección desde una acción rápida.
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Los paneles dejan de competir por espacio y se apilan en tabletas
        // pequeñas y móviles para mantener legibles sus contenidos.
        final widePanel = constraints.maxWidth < AppBreakpoints.tabletContent
            ? constraints.maxWidth
            : 620.0;
        final alertPanel = constraints.maxWidth < AppBreakpoints.tabletContent
            ? constraints.maxWidth
            : 340.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(34, 28, 34, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Buenos días, equipo 👋',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Este es el estado de tu farmacia para hoy.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  const StatCard(
                    label: 'Ventas del día',
                    value: r'C$ 1,248.50',
                    detail: '+12.8%',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.green,
                    background: Color(0xFFEAF8F1),
                  ),
                  StatCard(
                    label: 'Productos en stock',
                    value: controller.stockTotal.toString(),
                    detail: '+4.2%',
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.blue,
                    background: AppColors.paleBlue,
                  ),
                  StatCard(
                    label: 'Bajo mínimo',
                    value: controller.lowStockCount.toString(),
                    detail: 'Requieren atención',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.orange,
                    background: Color(0xFFFFF4E8),
                  ),
                  StatCard(
                    label: 'Por vencer',
                    value: controller.expiringCount.toString(),
                    detail: 'En próximos 90 días',
                    icon: Icons.event_busy_rounded,
                    color: AppColors.red,
                    background: Color(0xFFFFEFF0),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  SizedBox(width: widePanel, child: const SalesChartCard()),
                  SizedBox(
                    width: alertPanel,
                    child: InventoryAlertsCard(
                      products: controller.products,
                      onNavigate: onNavigate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              QuickActionsCard(onNavigate: onNavigate),
              const SizedBox(height: 20),
              const RecentActivityCard(),
              const SizedBox(height: 20),
              ControlsCard(onNavigate: onNavigate),
            ],
          ),
        );
      },
    );
  }
}
