import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/auth/views/login_page.dart';
import '../../models/dashboard/views/dashboard_page.dart';
import '../../models/home/views/home.dart';
import '../../models/incidents/views/incidents_page.dart';
import '../../models/inventory/views/inventory_page.dart';
import '../../models/inventory/views/lot_details_page.dart';
import '../../models/contacts/views/contacts_page.dart';
import '../../models/contacts/views/contact_details_page.dart';
import '../../models/contacts/models/contact.dart';
import '../../models/purchases/views/purchases_page.dart';
import '../../models/purchases/views/purchase_details_page.dart';
import '../../models/cash/views/cash_page.dart';
import '../../models/organization/views/organization_page.dart';
import '../../models/organization/views/registers_page.dart';
import '../../models/presentation/views/presentation_page.dart';
import '../../models/presentation/views/about_page.dart';
import '../../models/presentation/views/services_page.dart';
import '../../models/presentation/views/contact_page.dart';
import '../../models/presentation/views/public_promotions_page.dart';
import '../../models/promotions/views/promotions_admin_page.dart';
import '../../models/profile/views/profile_page.dart';
import '../../models/products/views/products_page.dart';
import '../../models/products/views/product_details_page.dart';
import '../../models/reports/views/reports_page.dart';
import '../../models/sales/views/sales_page.dart';
import '../../models/settings/views/settings_page.dart';
import '../../models/settings/views/system_tools_page.dart';
import '../../models/settings/models/app_preferences.dart';
import '../services/auth_controller.dart';
import '../services/pharmacy_controller.dart';
import '../services/preferences_controller.dart';
import '../services/promotions_controller.dart';
import '../../shared/widgets/administration_appearance.dart';
import '../../shared/widgets/administration_page.dart';
import '../../models/settings/widgets/data_tools.dart';
import 'app_paths.dart';
import 'auth_guard.dart';

/// Un router por aplicación. El shell privado solo se construye al superar
/// el guard. La presentación pública no usa el estado operativo ni de sesión.
GoRouter createAppRouter({
  required AuthController auth,
  required PharmacyController Function() pharmacyProvider,
  PreferencesController? preferences,
  PromotionsController? promotions,
  String? initialLocation,
}) {
  // Cada ficha tiene un enlace válido por sí solo. Reflejar el push permite
  // recargar o compartir ese detalle sin perder el identificador de la URL.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  final guard = AuthGuard(auth);
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: auth,
    redirect: (context, state) => guard.redirect(state.uri),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppPaths.presentation),
      GoRoute(
        path: AppPaths.presentation,
        builder: (_, _) => const PresentationPage(),
      ),
      GoRoute(
        path: AppPaths.presentationAbout,
        builder: (_, _) => const AboutPage(),
      ),
      GoRoute(
        path: AppPaths.presentationServices,
        builder: (_, state) =>
            ServicesPage(category: state.uri.queryParameters['categoria']),
      ),
      GoRoute(
        path: AppPaths.presentationContact,
        builder: (_, _) => const ContactPage(),
      ),
      GoRoute(
        path: AppPaths.publicPromotions,
        builder: (_, _) => PublicPromotionsPage(controller: promotions),
      ),
      GoRoute(
        path: AppPaths.legacyLogin,
        redirect: (_, _) => AppPaths.administration,
      ),
      ShellRoute(
        builder: (context, state, child) => AnimatedBuilder(
          animation: auth,
          builder: (context, _) {
            if (!auth.isAuthenticated) {
              final login = LoginPage(auth: auth);
              return preferences == null
                  ? login
                  : AdministrationAppearance(
                      preferences: preferences,
                      child: login,
                    );
            }
            final shell = HomeScreen(
              auth: auth,
              preferences: preferences,
              controller: auth.isAuthenticated ? pharmacyProvider() : null,
              selectedPage: AppPaths.indexOf(state.uri.path),
              uri: state.uri,
              child: child,
            );
            return preferences == null
                ? shell
                : AdministrationAppearance(
                    preferences: preferences,
                    child: shell,
                  );
          },
        ),
        routes: [
          for (var index = 0; index < AppPaths.sections.length; index++)
            GoRoute(
              path: AppPaths.sections[index],
              builder: (context, state) => AnimatedBuilder(
                animation: auth,
                builder: (context, _) {
                  if (!auth.isAuthenticated) return const SizedBox.shrink();
                  // Solo las rutas privadas autorizadas instancian datos
                  // operativos. La presentación nunca invoca este proveedor.
                  final pharmacy = pharmacyProvider();
                  return AnimatedBuilder(
                    animation: Listenable.merge([auth, pharmacy, ?preferences]),
                    builder: (context, _) => !pharmacy.isLoaded
                        ? const Center(child: CircularProgressIndicator())
                        : _buildAdministrationPage(
                            context,
                            index,
                            auth,
                            pharmacy,
                            preferences,
                            state.uri,
                            promotions,
                          ),
                  );
                },
              ),
            ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_outlined, size: 48),
              const SizedBox(height: 18),
              const Text(
                'Página no encontrada',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text('Revisa la dirección que escribiste.'),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => context.go(AppPaths.presentation),
                child: const Text('Volver a presentación'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildAdministrationPage(
  BuildContext context,
  int index,
  AuthController auth,
  PharmacyController pharmacy,
  PreferencesController? preferences,
  Uri uri,
  PromotionsController? promotions,
) {
  if (auth.user == null) return const SizedBox.shrink();
  if (pharmacy.loadFailed && index != 8 && index != 9 && index != 14) {
    return AdministrationPage(
      title: 'Recuperación de datos locales',
      description:
          'La lectura falló. No se muestran registros de ejemplo como si fueran tus datos ni se permite sobrescribirlos.',
      children: [
        if (auth.user!.isAdministrator)
          DataTools(controller: pharmacy)
        else
          const Text(
            'Solicita al administrador que recupere los datos. Puedes seguir usando tus preferencias personales.',
          ),
      ],
    );
  }
  void navigate(int target) => context.go(AppPaths.sections[target]);
  void backTo(String path) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(path);
    }
  }

  void message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
  return switch (index) {
    0 => DashboardPage(
      controller: pharmacy,
      onNavigate: navigate,
      isAdministrator: auth.user!.isAdministrator,
    ),
    1 => SalesPage(
      historyView: uri.queryParameters['vista'] == 'historial',
      onHistoryView: (history) => context.go(AppPaths.salesLocation(history)),
      controller: pharmacy,
      onMessage: message,
      confirmClearSale: preferences?.value.confirmClearSale ?? true,
      catalogLayout: preferences?.value.catalogLayout ?? CatalogLayout.cards,
      onCatalogLayout: preferences?.setCatalogLayout,
      onCash: AppPaths.disabledSections.contains(11)
          ? null
          : () => navigate(11),
    ),
    2 when uri.queryParameters['lote']?.isNotEmpty == true => LotDetailsPage(
      controller: pharmacy,
      lotId: uri.queryParameters['lote']!,
      onBack: () => backTo(
        AppPaths.inventoryLocation(
          productId: uri.queryParameters['producto'],
          lots: true,
        ),
      ),
    ),
    2 => InventoryPage(
      controller: pharmacy,
      productId: uri.queryParameters['producto'],
      lotsView: uri.queryParameters['vista'] == 'lotes',
      onProductLots: (id) =>
          context.push(AppPaths.inventoryLocation(productId: id)),
      onAllLots: () => context.go(AppPaths.inventoryLocation(lots: true)),
      onSummary: () => context.go(AppPaths.sections[2]),
      onLot: (id) => context.push(
        AppPaths.inventoryLocation(
          productId: uri.queryParameters['producto'],
          lotId: id,
          lots: true,
        ),
      ),
      onProducts: () => context.go(AppPaths.products),
    ),
    3 when uri.queryParameters['compra']?.isNotEmpty == true =>
      PurchaseDetailsPage(
        controller: pharmacy,
        purchaseId: uri.queryParameters['compra']!,
        onBack: () => backTo(
          uri.queryParameters['proveedor']?.isNotEmpty == true
              ? AppPaths.contactLocation(4, uri.queryParameters['proveedor']!)
              : AppPaths.sections[3],
        ),
        backLabel: uri.queryParameters['proveedor']?.isNotEmpty == true
            ? 'Volver al proveedor'
            : 'Volver al listado',
        onProduct: (id) => context.push(AppPaths.productLocation(id)),
      ),
    3 => PurchasesPage(
      controller: pharmacy,
      onOpen: (id) => context.push(AppPaths.purchaseLocation(id)),
    ),
    4 || 5 when uri.queryParameters['contacto']?.isNotEmpty == true =>
      ContactDetailsPage(
        controller: pharmacy,
        kind: index == 4 ? ContactKind.supplier : ContactKind.customer,
        contactId: uri.queryParameters['contacto']!,
        onBack: () => backTo(AppPaths.sections[index]),
        onPurchase: (id) => context.push(
          AppPaths.purchaseLocation(
            id,
            supplierId: uri.queryParameters['contacto'],
          ),
        ),
      ),
    4 => ContactsPage(
      controller: pharmacy,
      kind: ContactKind.supplier,
      onOpen: (id) => context.push(AppPaths.contactLocation(4, id)),
    ),
    5 => ContactsPage(
      controller: pharmacy,
      kind: ContactKind.customer,
      onOpen: (id) => context.push(AppPaths.contactLocation(5, id)),
    ),
    6 => ReportsPage(
      controller: pharmacy,
      detailsView: uri.queryParameters['vista'] == 'detalle',
      onView: (details) => context.go(AppPaths.reportLocation(details)),
    ),
    7 => IncidentsPage(
      controller: pharmacy,
      recordId: uri.queryParameters['solicitud'],
      onOpen: (id) => context.push(AppPaths.supportLocation(id)),
      onBack: () => backTo(AppPaths.sections[7]),
    ),
    8 => SystemToolsPage(
      controller: pharmacy,
      onPreferences: () => navigate(14),
    ),
    9 => ProfilePage(auth: auth, operations: pharmacy),
    10 when uri.queryParameters['producto']?.isNotEmpty == true =>
      ProductDetailsPage(
        controller: pharmacy,
        productId: uri.queryParameters['producto']!,
        onBack: () => backTo(AppPaths.products),
        onLots: () => context.push(
          AppPaths.inventoryLocation(
            productId: uri.queryParameters['producto'],
          ),
        ),
      ),
    10 => ProductsPage(
      controller: pharmacy,
      onInventory: () => navigate(2),
      onOpen: (id) => context.push(AppPaths.productLocation(id)),
    ),
    11 => CashPage(controller: pharmacy),
    12 => OrganizationPage(
      controller: pharmacy,
      selectedSection: AppPaths.organizationSection(uri),
      onSection: (i) => context.go(AppPaths.organizationLocation(i)),
    ),
    13 => RegistersPage(
      controller: pharmacy,
      onManage: () => navigate(12),
      registerId: uri.queryParameters['caja'],
      start: DateTime.tryParse(uri.queryParameters['desde'] ?? ''),
      end: DateTime.tryParse(uri.queryParameters['hasta'] ?? ''),
      onOpen: (id, start, end) =>
          context.push(AppPaths.registerLocation(id, start: start, end: end)),
      onBack: () => backTo(AppPaths.billingRegisters),
    ),
    14 => SettingsPage(
      preferences: preferences,
      selectedSection: AppPaths.preferenceSection(uri),
      onSection: (section) => context.go(AppPaths.preferenceLocation(section)),
    ),
    15 =>
      promotions == null
          ? const Center(child: Text('Gestor de promociones no disponible.'))
          : PromotionsAdminPage(
              controller: promotions,
              promotionId: uri.queryParameters['promocion'],
              onOpen: (id) => context.push(AppPaths.promotionLocation(id)),
              onBack: () => backTo(AppPaths.promotions),
              onPublicPage: () => context.go(AppPaths.publicPromotions),
            ),
    _ => const SizedBox.shrink(),
  };
}
