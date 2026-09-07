import 'package:flutter/material.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/themes/app_colors.dart';
import '../../dashboard/views/dashboard_page.dart';
import '../../incidents/views/incidents_page.dart';
import '../../inventory/views/inventory_page.dart';
import '../../operations/views/info_page.dart';
import '../../reports/views/reports_page.dart';
import '../../sales/views/sales_page.dart';
import '../../settings/views/settings_page.dart';
import '../widgets/notifications_sheet.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';

/// Contenedor principal que coordina navegación y estado compartido.
class HomeScreen extends StatefulWidget {
  /// Crea la pantalla principal.
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PharmacyController controller;
  int selectedPage = 0;

  static const pageTitles = <String>[
    'Resumen general',
    'Punto de venta',
    'Inventario',
    'Compras',
    'Proveedores',
    'Clientes',
    'Reportes',
    'Incidentes TI',
    'Configuración',
  ];

  @override
  void initState() {
    super.initState();
    controller = PharmacyController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Cambia la pantalla activa y cierra el drawer en móvil si está abierto.
  void navigateTo(int index) {
    setState(() => selectedPage = index);
    Navigator.of(context).maybePop();
  }

  /// Muestra un mensaje breve sin acoplar los módulos al estado global.
  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  /// Muestra el formulario mínimo para registrar un producto.
  Future<void> openProductDialog() async {
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar producto'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nombre del producto'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim().isNotEmpty),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (saved == true) {
      this.controller.addProduct(controller.text.trim());
      showMessage('Producto guardado en el inventario');
    }
    controller.dispose();
  }

  /// Abre la hoja de notificaciones globales.
  void openNotifications() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const NotificationsSheet(),
    );
  }

  /// Decide qué vista corresponde al índice seleccionado.
  Widget buildCurrentPage() {
    if (selectedPage == 0) {
      return DashboardPage(controller: controller, onNavigate: navigateTo);
    }
    if (selectedPage == 1) {
      return SalesPage(controller: controller, onMessage: showMessage);
    }
    if (selectedPage == 2) {
      return InventoryPage(
        controller: controller,
        onAddProduct: openProductDialog,
      );
    }
    if (selectedPage == 6) return const ReportsPage();
    if (selectedPage == 7) return const IncidentsPage();
    if (selectedPage == 8) return const SettingsPage();
    return InfoPage(title: pageTitles[selectedPage], pageIndex: selectedPage);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // En móvil cambiamos la navegación lateral por un drawer para
            // conservar el ancho útil de los módulos principales.
            if (isMobileWidth(constraints.maxWidth)) {
              return Scaffold(
                drawer: Drawer(
                  child: Sidebar(selected: selectedPage, onSelect: navigateTo),
                ),
                appBar: AppBar(
                  title: Text(
                    pageTitles[selectedPage],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  actions: [
                    IconButton(
                      onPressed: openNotifications,
                      icon: const Badge(
                        smallSize: 7,
                        backgroundColor: AppColors.red,
                        child: Icon(Icons.notifications_none_rounded),
                      ),
                    ),
                  ],
                ),
                body: buildCurrentPage(),
              );
            }

            return Scaffold(
              body: Row(
                children: [
                  Sidebar(selected: selectedPage, onSelect: navigateTo),
                  Expanded(
                    child: Column(
                      children: [
                        TopBar(
                          title: pageTitles[selectedPage],
                          onNotifications: openNotifications,
                        ),
                        Expanded(child: buildCurrentPage()),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
