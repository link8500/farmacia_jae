import 'package:flutter/material.dart';
import '../../../shared/widgets/page_header.dart';
import '../widgets/setting_group.dart';

/// Configuración de farmacia, seguridad, respaldos y continuidad.
class SettingsPage extends StatelessWidget {
  /// Crea la pantalla de configuración.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(34, 28, 34, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Configuración',
            description:
                'Ajusta los datos que mantienen segura y ordenada la operación.',
          ),
          const SizedBox(height: 24),
          const SettingGroup(
            title: 'Farmacia',
            rows: [
              'Nombre comercial  ·  Farmacia JAE',
              r'Moneda  ·  Córdoba nicaragüense (C$)',
              'Zona horaria  ·  America/Managua',
            ],
          ),
          const SizedBox(height: 16),
          const SettingGroup(
            title: 'Seguridad y acceso',
            rows: [
              'Usuarios y permisos  ·  4 usuarios con rol asignado',
              'Último respaldo  ·  Correcto, hoy a las 06:00 a. m.',
              'Auditoría de operaciones  ·  Activa, 128 eventos',
              'Seguridad perimetral  ·  Firewall pendiente de configuración',
            ],
          ),
          const SizedBox(height: 16),
          const SettingGroup(
            title: 'Calidad y continuidad',
            rows: [
              'Procesos digitalizados  ·  68%',
              'Disponibilidad del sistema  ·  99.8%',
              'Política de contingencia  ·  En revisión',
            ],
          ),
        ],
      ),
    );
  }
}
