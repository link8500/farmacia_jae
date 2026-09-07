import 'package:flutter/material.dart';
import '../../../shared/widgets/page_header.dart';
import '../widgets/report_card.dart';

/// Catálogo de reportes administrativos, financieros y de TI.
class ReportsPage extends StatelessWidget {
  /// Crea la pantalla de reportes.
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(34, 28, 34, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Reportes',
            description: 'Convierte la operación diaria en decisiones claras.',
          ),
          const SizedBox(height: 24),
          const Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ReportCard(
                title: 'Ventas por período',
                description:
                    'Ingresos, productos más vendidos y métodos de pago',
                icon: Icons.show_chart_rounded,
                color: Color(0xFF2563EB),
              ),
              ReportCard(
                title: 'Inventario valorizado',
                description: 'Existencias, lotes y productos por vencer',
                icon: Icons.inventory_2_outlined,
                color: Color(0xFF199B67),
              ),
              ReportCard(
                title: 'Compras y proveedores',
                description: 'Historial y comportamiento de proveedores',
                icon: Icons.local_shipping_outlined,
                color: Color(0xFFF08B3E),
              ),
              ReportCard(
                title: 'Movimientos de caja',
                description: 'Aperturas, cierres e ingresos',
                icon: Icons.account_balance_wallet_outlined,
                color: Color(0xFF102B57),
              ),
              ReportCard(
                title: 'Auditoría de operaciones',
                description:
                    'Ventas, cambios de inventario y acciones por usuario',
                icon: Icons.fact_check_outlined,
                color: Color(0xFFF08B3E),
              ),
              ReportCard(
                title: 'Indicadores de TI',
                description:
                    'Disponibilidad, SLA, MTTR y procesos digitalizados',
                icon: Icons.speed_outlined,
                color: Color(0xFF2563EB),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
