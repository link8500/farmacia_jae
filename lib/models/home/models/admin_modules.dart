import 'package:forui/forui.dart' show FLucideIcons;
import '../../../core/config/administration_features.dart';
import 'navigation_item.dart';

/// Procesos del negocio, no una copia de una lista genérica de pantallas.
/// Productos define las fichas, Compras recibe y Lotes consulta existencias.
/// Los índices conservan las URLs anteriores, aunque cambia su agrupación.
/// El módulo Inventario agrupa Productos, Lotes, Compras y Proveedores.
/// Se conservan los IDs internos para no alterar navegación, permisos o enlaces.
const adminModules = <NavigationModule>[
  NavigationModule(
    id: 'supervision',
    label: 'Dashboard',
    icon: FLucideIcons.layoutDashboard,
    items: [
      NavigationItem(
        index: 0,
        label: 'Resumen',
        icon: FLucideIcons.layoutDashboard,
      ),
      NavigationItem(
        index: 6,
        label: 'Reportes',
        icon: FLucideIcons.chartNoAxesColumn,
      ),
    ],
  ),
  NavigationModule(
    id: 'abastecimiento',
    label: 'Inventario',
    icon: FLucideIcons.boxes,
    items: [
      NavigationItem(index: 10, label: 'Productos', icon: FLucideIcons.pill),
      NavigationItem(index: 2, label: 'Lotes', icon: FLucideIcons.package),
      NavigationItem(
        index: 3,
        label: 'Compras',
        icon: FLucideIcons.shoppingBag,
      ),
      NavigationItem(index: 4, label: 'Proveedores', icon: FLucideIcons.truck),
    ],
  ),
  NavigationModule(
    id: 'ventas',
    label: 'Ventas',
    icon: FLucideIcons.store,
    items: [
      // El código permanece disponible para una reactivación posterior.
      if (AdministrationFeatures.cashEnabled)
        NavigationItem(
          index: 11,
          label: 'Caja y arqueos',
          icon: FLucideIcons.wallet,
        ),
      NavigationItem(
        index: 13,
        label: 'Cajas de facturación',
        icon: FLucideIcons.wallet,
      ),
      NavigationItem(
        index: 1,
        label: 'Facturación',
        icon: FLucideIcons.receipt,
      ),
      NavigationItem(index: 5, label: 'Clientes', icon: FLucideIcons.users),
    ],
  ),
  NavigationModule(
    id: 'administracion',
    label: 'Gestión de la farmacia',
    icon: FLucideIcons.shieldCheck,
    items: [
      NavigationItem(index: 15, label: 'Promociones', icon: FLucideIcons.tag),
      NavigationItem(
        index: 12,
        label: 'Personal y asignaciones',
        icon: FLucideIcons.network,
      ),
      NavigationItem(
        index: 8,
        label: 'Datos y mantenimiento',
        icon: FLucideIcons.database,
      ),
      NavigationItem(
        index: 17,
        label: 'Solicitudes de soporte',
        icon: FLucideIcons.inbox,
      ),
    ],
  ),
  NavigationModule(
    id: 'cuenta',
    label: 'Mi cuenta',
    icon: FLucideIcons.circleUser,
    items: [
      NavigationItem(
        index: 9,
        label: 'Mi perfil',
        icon: FLucideIcons.circleUser,
      ),
      NavigationItem(
        index: 14,
        label: 'Preferencias',
        icon: FLucideIcons.slidersHorizontal,
      ),
      NavigationItem(
        index: 7,
        label: 'Ayuda y soporte',
        icon: FLucideIcons.circleHelp,
      ),
    ],
  ),
];
