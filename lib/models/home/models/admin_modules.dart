import 'package:flutter/material.dart';
import '../../../core/config/administration_features.dart';
import 'navigation_item.dart';

/// Procesos del negocio, no una copia de una lista genérica de pantallas.
/// Productos define las fichas; Lotes recibe y consulta sus existencias.
/// Los índices conservan las URLs anteriores, aunque cambia su agrupación.
/// El módulo Inventario agrupa Productos, Lotes, Compras y Proveedores.
/// Se conservan los IDs internos para no alterar navegación, permisos o enlaces.
const adminModules = <NavigationModule>[
  NavigationModule(
    id: 'supervision',
    label: 'Dashboard',
    icon: Icons.insights_rounded,
    items: [
      NavigationItem(
        index: 0,
        label: 'Resumen',
        icon: Icons.dashboard_outlined,
      ),
      NavigationItem(
        index: 6,
        label: 'Reportes',
        icon: Icons.bar_chart_rounded,
      ),
    ],
  ),
  NavigationModule(
    id: 'abastecimiento',
    label: 'Inventario',
    icon: Icons.local_shipping_outlined,
    items: [
      NavigationItem(
        index: 10,
        label: 'Productos',
        icon: Icons.medication_outlined,
      ),
      NavigationItem(
        index: 2,
        label: 'Lotes',
        icon: Icons.inventory_2_outlined,
      ),
      NavigationItem(
        index: 3,
        label: 'Compras',
        icon: Icons.shopping_bag_outlined,
      ),
      NavigationItem(
        index: 4,
        label: 'Proveedores',
        icon: Icons.local_shipping_rounded,
      ),
    ],
  ),
  NavigationModule(
    id: 'ventas',
    label: 'Ventas',
    icon: Icons.storefront_outlined,
    items: [
      // El código permanece disponible para una reactivación posterior.
      if (AdministrationFeatures.cashEnabled)
        NavigationItem(
          index: 11,
          label: 'Caja y arqueos',
          icon: Icons.account_balance_wallet_outlined,
        ),
      NavigationItem(
        index: 13,
        label: 'Cajas de facturación',
        icon: Icons.point_of_sale_outlined,
      ),
      NavigationItem(
        index: 1,
        label: 'Facturación',
        icon: Icons.point_of_sale_rounded,
      ),
      NavigationItem(
        index: 5,
        label: 'Clientes',
        icon: Icons.people_alt_outlined,
      ),
    ],
  ),
  NavigationModule(
    id: 'administracion',
    label: 'Gestión de la farmacia',
    icon: Icons.admin_panel_settings_outlined,
    items: [
      NavigationItem(
        index: 15,
        label: 'Promociones',
        icon: Icons.local_offer_outlined,
      ),
      NavigationItem(
        index: 12,
        label: 'Personal y asignaciones',
        icon: Icons.account_tree_outlined,
      ),
      NavigationItem(
        index: 8,
        label: 'Datos y mantenimiento',
        icon: Icons.storage_outlined,
      ),
    ],
  ),
  NavigationModule(
    id: 'cuenta',
    label: 'Mi cuenta',
    icon: Icons.person_outline_rounded,
    items: [
      NavigationItem(index: 9, label: 'Mi perfil', icon: Icons.badge_outlined),
      NavigationItem(
        index: 14,
        label: 'Preferencias',
        icon: Icons.tune_rounded,
      ),
      NavigationItem(
        index: 7,
        label: 'Ayuda y soporte',
        icon: Icons.help_outline_rounded,
      ),
    ],
  ),
];
