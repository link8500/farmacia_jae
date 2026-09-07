import 'package:flutter/material.dart';
import '../../../shared/themes/app_colors.dart';
import '../models/navigation_item.dart';

/// Menú lateral principal de la aplicación.
class Sidebar extends StatelessWidget {
  /// Crea el menú indicando la pantalla activa y su callback de navegación.
  const Sidebar({required this.selected, required this.onSelect, super.key});

  /// Índice de la opción activa.
  final int selected;

  /// Callback que cambia la pantalla principal.
  final ValueChanged<int> onSelect;

  static const _mainItems = [
    NavigationItem(index: 0, label: 'Resumen', icon: Icons.grid_view_rounded),
    NavigationItem(
      index: 1,
      label: 'Punto de venta',
      icon: Icons.point_of_sale_rounded,
    ),
    NavigationItem(
      index: 2,
      label: 'Inventario',
      icon: Icons.inventory_2_rounded,
      badge: '8',
    ),
  ];

  static const _operationItems = [
    NavigationItem(
      index: 3,
      label: 'Compras',
      icon: Icons.shopping_bag_rounded,
    ),
    NavigationItem(
      index: 4,
      label: 'Proveedores',
      icon: Icons.local_shipping_rounded,
    ),
    NavigationItem(index: 5, label: 'Clientes', icon: Icons.people_alt_rounded),
  ];

  static const _managementItems = [
    NavigationItem(index: 6, label: 'Reportes', icon: Icons.bar_chart_rounded),
    NavigationItem(
      index: 7,
      label: 'Incidentes TI',
      icon: Icons.support_agent_rounded,
    ),
    NavigationItem(
      index: 8,
      label: 'Configuración',
      icon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Brand(),
                const _MenuLabel('PRINCIPAL'),
                ..._mainItems.map(_buildItem),
                const _MenuLabel('OPERACIÓN', top: 22),
                ..._operationItems.map(_buildItem),
                const _MenuLabel('GESTIÓN', top: 22),
                ..._managementItems.map(_buildItem),
                const SizedBox(height: 26),
                const _UserCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye una opción del menú a partir de su configuración.
  Widget _buildItem(NavigationItem item) {
    final active = item.index == selected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: active ? AppColors.paleBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: () => onSelect(item.index),
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 19,
                  color: active ? AppColors.blue : AppColors.muted,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: active ? AppColors.blue : AppColors.ink,
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (item.badge != null)
                  Text(
                    item.badge!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Marca visual de la farmacia en el menú.
class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 20, 28),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.local_pharmacy_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 11),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Farmacia JAE',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                'Gestión inteligente',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Separador textual que agrupa opciones relacionadas.
class _MenuLabel extends StatelessWidget {
  const _MenuLabel(this.text, {this.top = 0});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, top: top, bottom: 9),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// Información resumida del usuario activo.
class _UserCard extends StatelessWidget {
  const _UserCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paleBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.navy,
            child: Text(
              'AD',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Administrador',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Text(
                'Sesión activa',
                style: TextStyle(color: AppColors.green, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
