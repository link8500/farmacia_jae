import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_pill.dart';

/// Gestión básica de incidentes y soporte de TI.
///
/// Responde a la brecha de soporte identificada en el diagnóstico y deja
/// visible el KPI MTTR para que la administración pueda darle seguimiento.
class IncidentsPage extends StatelessWidget {
  /// Crea la pantalla de incidentes.
  const IncidentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(34, 28, 34, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Incidentes TI',
            description:
                'Registra, prioriza y da seguimiento al soporte tecnológico.',
            action: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo incidente'),
            ),
          ),
          const SizedBox(height: 24),
          const Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              StatCard(
                label: 'Abiertos',
                value: '2',
                detail: 'Requieren atención',
                icon: Icons.error_outline,
                color: AppColors.red,
                background: Color(0xFFFFEFF0),
                width: 245,
              ),
              StatCard(
                label: 'En atención',
                value: '1',
                detail: 'Dentro del SLA',
                icon: Icons.timelapse_outlined,
                color: AppColors.orange,
                background: Color(0xFFFFF4E8),
                width: 245,
              ),
              StatCard(
                label: 'MTTR promedio',
                value: '42 min',
                detail: 'Últimos 30 días',
                icon: Icons.timer_outlined,
                color: AppColors.blue,
                background: AppColors.paleBlue,
                width: 245,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionCard(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Column(
              children: [
                IncidentRow(
                  title: 'Pérdida intermitente de conexión',
                  detail: 'Red local · Reportado hace 18 min',
                  status: 'En atención',
                  color: AppColors.orange,
                ),
                IncidentRow(
                  title: 'Revisión de respaldo automático',
                  detail: 'Base de datos · Programado para hoy',
                  status: 'Pendiente',
                  color: AppColors.blue,
                ),
                IncidentRow(
                  title: 'Actualización de equipo POS',
                  detail: 'Mantenimiento · Cerrado ayer',
                  status: 'Resuelto',
                  color: AppColors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila reutilizable para un incidente.
class IncidentRow extends StatelessWidget {
  /// Crea una fila con detalle y estado.
  const IncidentRow({
    required this.title,
    required this.detail,
    required this.status,
    required this.color,
    super.key,
  });

  final String title;
  final String detail;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isCompactWidth(constraints.maxWidth)) {
          // En móvil el estado pasa debajo del incidente para que el título
          // y el detalle conserven una línea legible.
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.support_agent_outlined, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 34, top: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          detail,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      StatusPill(text: status, color: color),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.support_agent_outlined, color: color),
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            detail,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
          trailing: StatusPill(text: status, color: color),
        );
      },
    );
  }
}
