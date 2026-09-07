import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/inventory/models/product.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_pill.dart';

/// Tarjeta con la tendencia de ventas de los últimos siete días.
class SalesChartCard extends StatelessWidget {
  /// Crea el gráfico de ventas.
  const SalesChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de ventas',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ingresos de los últimos 7 días',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: SalesChartPainter(),
              child: const SizedBox.expand(),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                'Lun',
                style: TextStyle(color: AppColors.muted, fontSize: 10),
              ),
              Text(
                'Mar',
                style: TextStyle(color: AppColors.muted, fontSize: 10),
              ),
              Text(
                'Mié',
                style: TextStyle(color: AppColors.muted, fontSize: 10),
              ),
              Text(
                'Jue',
                style: TextStyle(color: AppColors.muted, fontSize: 10),
              ),
              Text(
                'Vie',
                style: TextStyle(color: AppColors.muted, fontSize: 10),
              ),
              Text(
                'Sáb',
                style: TextStyle(color: AppColors.muted, fontSize: 10),
              ),
              Text(
                'Dom',
                style: TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Gráfico ligero que no necesita una dependencia externa.
class SalesChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index++) {
      final y = 18 + (size.height - 32) * index / 3;
      canvas.drawLine(Offset(24, y), Offset(size.width, y), grid);
    }

    const values = <double>[0.68, 0.45, 0.58, 0.32, 0.65, 0.22, 0.40];
    final points = [
      for (var index = 0; index < values.length; index++)
        Offset(
          24 + (size.width - 30) * index / 6,
          18 + (size.height - 45) * values[index],
        ),
    ];
    final line = Paint()
      ..color = AppColors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      path.lineTo(points[index].dx, points[index].dy);
    }
    canvas.drawPath(path, line);
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = Colors.white);
      canvas.drawCircle(
        point,
        4,
        Paint()
          ..color = AppColors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Muestra existencias bajo mínimo y productos próximos a vencer.
class InventoryAlertsCard extends StatelessWidget {
  /// Crea el resumen de alertas de inventario.
  const InventoryAlertsCard({
    required this.products,
    required this.onNavigate,
    super.key,
  });

  /// Productos sobre los que se calculan las alertas.
  final List<Product> products;

  /// Navegación hacia el inventario completo.
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final items = products
        .where((item) => item.isLow || item.isExpiring)
        .take(3)
        .toList();
    return SectionCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Alertas de inventario',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onNavigate(2),
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
          ...items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(
                item.isLow
                    ? Icons.inventory_2_outlined
                    : Icons.event_busy_outlined,
                color: item.isLow ? AppColors.orange : AppColors.red,
                size: 19,
              ),
              title: Text(
                item.name,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                item.isLow
                    ? 'Stock actual: ${item.stock}'
                    : 'Vence ${formatDate(item.expiry)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
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
  const QuickActionsCard({required this.onNavigate, super.key});

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
          const Text(
            'Accesos rápidos',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          _QuickAction(
            label: 'Nueva venta',
            icon: Icons.add_shopping_cart_rounded,
            color: AppColors.blue,
            onTap: () => onNavigate(1),
          ),
          _QuickAction(
            label: 'Registrar compra',
            icon: Icons.add_box_rounded,
            color: AppColors.green,
            onTap: () => onNavigate(3),
          ),
          _QuickAction(
            label: 'Ver inventario',
            icon: Icons.inventory_rounded,
            color: AppColors.orange,
            onTap: () => onNavigate(2),
          ),
          _QuickAction(
            label: 'Generar reporte',
            icon: Icons.assessment_rounded,
            color: AppColors.navy,
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
            Text(
              label,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Actividad reciente de ventas y compras.
class RecentActivityCard extends StatelessWidget {
  /// Crea el panel de actividad reciente.
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actividad reciente',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.point_of_sale_rounded, color: AppColors.blue),
            title: Text('Venta #000482'),
            subtitle: Text(
              'Paracetamol 500 mg y 2 productos más  •  Hace 8 min',
            ),
            trailing: Text(r'C$ 18.20'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.shopping_bag_rounded, color: AppColors.green),
            title: Text('Compra #000127'),
            subtitle: Text('Distribuidora Nacional  •  Hace 42 min'),
            trailing: Text(r'C$ 426.00'),
          ),
        ],
      ),
    );
  }
}

/// Estado de controles de seguridad, calidad y continuidad.
class ControlsCard extends StatelessWidget {
  /// Crea el panel de gobernanza.
  const ControlsCard({required this.onNavigate, super.key});

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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gobernanza y continuidad',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Controles del PETI para una operación segura y trazable.',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const StatusPill(
                text: 'Nivel 1 → Nivel 3',
                color: AppColors.blue,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 26,
            runSpacing: 14,
            children: [
              ControlItem(
                icon: Icons.verified_user_outlined,
                title: 'Accesos',
                value: '4 usuarios con rol',
                color: AppColors.green,
              ),
              ControlItem(
                icon: Icons.cloud_done_outlined,
                title: 'Respaldo',
                value: 'Correcto · 06:00 a. m.',
                color: AppColors.blue,
              ),
              ControlItem(
                icon: Icons.fact_check_outlined,
                title: 'Auditoría',
                value: 'Activa · 128 eventos',
                color: AppColors.orange,
              ),
              ControlItem(
                icon: Icons.speed_outlined,
                title: 'Disponibilidad',
                value: '99.8% este mes',
                color: AppColors.navy,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => onNavigate(8),
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: const Text('Revisar controles'),
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
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
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
