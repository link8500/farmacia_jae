import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_paths.dart';
import '../../../core/services/auth_controller.dart';
import '../../../core/services/preferences_controller.dart';
import '../../../core/services/pharmacy_controller.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/themes/app_palette.dart';
import '../widgets/notifications_sheet.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';
import '../../../shared/widgets/administration_breadcrumbs.dart';
import '../../../shared/widgets/user_avatar.dart';

/// Shell de administración. La URL es la fuente de la navegación, de modo
/// que volver y abrir enlaces directos conserva la pantalla correcta.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.auth,
    required this.selectedPage,
    required this.child,
    this.preferences,
    this.controller,
    this.uri,
    super.key,
  });
  final AuthController auth;
  final PreferencesController? preferences;
  final PharmacyController? controller;
  final int selectedPage;
  final Uri? uri;
  final Widget child;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffold = GlobalKey<ScaffoldState>();
  Widget _body() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AdministrationBreadcrumbs(
        section: widget.selectedPage,
        uri: widget.uri ?? Uri.parse(AppPaths.sections[widget.selectedPage]),
        onNavigate: context.go,
      ),
      if (widget.controller?.storageError != null)
        Material(
          color: context.palette.negativeSurface,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.controller!.storageError!,
                  style: TextStyle(color: context.palette.ink),
                ),
                TextButton(
                  onPressed: () {
                    if (widget.controller!.loadFailed) {
                      widget.controller!.retryLoading();
                    } else {
                      widget.controller!.retrySaving();
                    }
                  },
                  child: const Text('Reintentar almacenamiento'),
                ),
              ],
            ),
          ),
        ),
      Expanded(child: widget.child),
    ],
  );

  /// Cierra solo el drawer: nunca hace pop de una ruta de escritorio.
  void _navigateTo(int index) {
    _scaffold.currentState?.closeDrawer();
    context.go(AppPaths.sections[index]);
  }

  void _notifications() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => NotificationsSheet(controller: widget.controller),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([
      widget.auth,
      ?widget.preferences,
      ?widget.controller,
    ]),
    builder: (context, _) {
      final user = widget.auth.user;
      if (user == null) return const SizedBox.shrink();
      final title = AppPaths.titles[widget.selectedPage];
      final sidebar = Sidebar(
        selected: widget.selectedPage,
        user: user,
        onSelect: _navigateTo,
        onProfile: () => _navigateTo(9),
        onLogout: widget.auth.signOut,
      );
      return LayoutBuilder(
        builder: (context, constraints) {
          if (isMobileWidth(constraints.maxWidth)) {
            return Scaffold(
              key: _scaffold,
              drawer: Drawer(child: sidebar),
              appBar: AppBar(
                title: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Notificaciones',
                    onPressed: _notifications,
                    icon: Badge(
                      smallSize: 7,
                      backgroundColor: AppColors.red,
                      isLabelVisible:
                          (widget.preferences?.value.showNotificationBadges ??
                              true) &&
                          (widget.controller?.alertsCount ?? 0) > 0,
                      child: const Icon(Icons.notifications_none_rounded),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Mi perfil',
                    onPressed: () => _navigateTo(9),
                    icon: UserAvatar(user: user, size: 30),
                  ),
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    onPressed: widget.auth.signOut,
                    icon: const Icon(Icons.logout_rounded, size: 20),
                  ),
                ],
              ),
              body: _body(),
            );
          }
          return Scaffold(
            key: _scaffold,
            body: Row(
              // La navegación ocupa toda la altura, también en pantallas altas.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sidebar,
                Expanded(
                  child: Column(
                    children: [
                      TopBar(
                        showNotificationBadges:
                            (widget.preferences?.value.showNotificationBadges ??
                                true) &&
                            (widget.controller?.alertsCount ?? 0) > 0,
                        title: title,
                        user: user,
                        onNotifications: _notifications,
                        onProfile: () => _navigateTo(9),
                        onPreferences: () => _navigateTo(14),
                        onLogout: widget.auth.signOut,
                      ),
                      Expanded(child: _body()),
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
