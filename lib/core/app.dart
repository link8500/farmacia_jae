import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../shared/themes/app_theme.dart';
import 'routing/app_router.dart';
import 'services/auth_controller.dart';
import 'services/pharmacy_controller.dart';
import 'services/preferences_controller.dart';
import 'services/preferences_store.dart';
import 'services/local_administration_store.dart';
import 'services/promotion_store.dart';
import 'services/promotions_controller.dart';

/// Widget raíz de Farmacia JAE.
///
/// Aquí se registra la configuración global de Flutter. La navegación y el
/// estado operativo se mantienen en los módulos que corresponden a cada área.
class FarmaciaApp extends StatefulWidget {
  /// Crea la aplicación principal.
  const FarmaciaApp({
    this.auth,
    this.preferences,
    this.administrationStore,
    this.promotionStore,
    this.seedDemoHistory = false,
    this.initialLocation,
    super.key,
  });

  /// Inyección para comprobar las rutas sin una sesión global.
  final AuthController? auth;
  final PreferencesController? preferences;
  final AdministrationStore? administrationStore;
  final PromotionStore? promotionStore;
  final bool seedDemoHistory;
  final String? initialLocation;

  @override
  State<FarmaciaApp> createState() => _FarmaciaAppState();
}

class _FarmaciaAppState extends State<FarmaciaApp> {
  late final AuthController _auth;
  late final PreferencesController _preferences;
  PharmacyController? _pharmacy;
  late final PromotionsController _promotions;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _auth = widget.auth ?? AuthController(profiles: LocalDemoProfilesStore());
    _preferences =
        widget.preferences ?? PreferencesController(LocalPreferencesStore());
    _preferences.useAccount(_auth.user?.id);
    PharmacyController operations() => _pharmacy ??= PharmacyController(
      seedDemoHistory: widget.seedDemoHistory,
      store: widget.administrationStore ?? LocalAdministrationStore(),
      userProvider: () => _auth.user,
    );
    // El directorio se carga al enviar el login, nunca desde Presentación.
    _auth.accountProvider = () async {
      final accounts = await operations().localLoginAccounts();
      return accounts.map((account) {
        final original = AuthController.demoUsers.where(
          (u) => u.id == account.id,
        );
        return original.isEmpty
            ? account
            : original.single
                  .withDirectoryRole(account.role)
                  .copyWith(
                    name: account.name,
                    avatarAsset: account.avatarAsset,
                  );
      }).toList();
    };
    _promotions = PromotionsController(
      seedDemo: widget.seedDemoHistory,
      store: widget.promotionStore ?? LocalPromotionStore(),
      canManage: () =>
          _auth.user?.isAdministrator == true && operations().isAdministrator,
    );
    _router = createAppRouter(
      auth: _auth,
      preferences: _preferences,
      promotions: _promotions,
      // El estado operativo no se crea al visitar la presentación pública.
      pharmacyProvider: () {
        final controller = operations();
        controller.initialize();
        return controller;
      },
      initialLocation: widget.initialLocation,
    );
    _auth.addListener(_clearSessionData);
  }

  /// No traslada ventas pendientes entre sesiones de distintos usuarios.
  void _clearSessionData() {
    _preferences.useAccount(_auth.user?.id);
    _pharmacy?.recordSessionChange(_auth.user);
    if (!_auth.isAuthenticated) _pharmacy?.clearCart();
  }

  @override
  void dispose() {
    _auth.removeListener(_clearSessionData);
    _auth.accountProvider = null;
    _router.dispose();
    _promotions.dispose();
    _pharmacy?.dispose();
    if (widget.auth == null) _auth.dispose();
    if (widget.preferences == null) _preferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Farmacia JAE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
