import 'package:flutter/material.dart';
import 'package:forui/forui.dart' show FLucideIcons;
import '../../../models/auth/models/session_user.dart';
import '../../../shared/themes/app_palette.dart';
import '../../../shared/widgets/user_avatar.dart';

/// Cabecera del área privada con cuenta activa y cierre de sesión.
class TopBar extends StatelessWidget {
  const TopBar({
    required this.title,
    required this.user,
    required this.onNotifications,
    required this.onProfile,
    required this.onLogout,
    this.showNotificationBadges = true,
    this.onPreferences,
    super.key,
  });
  final String title;
  final SessionUser user;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final VoidCallback onLogout;
  final VoidCallback? onPreferences;
  final bool showNotificationBadges;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final showUserName = constraints.maxWidth >= 680;
      return Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          color: context.palette.surface,
          border: Border(bottom: BorderSide(color: context.palette.border)),
        ),
        child: Row(
          children: [
            if (constraints.maxWidth >= 460) ...[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.palette.paleBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  FLucideIcons.layoutDashboard,
                  size: 18,
                  color: context.palette.blue,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ADMINISTRACIÓN',
                    style: TextStyle(
                      color: context.palette.muted,
                      fontSize: 9,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.palette.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (onPreferences != null)
              IconButton(
                tooltip: 'Apariencia',
                onPressed: onPreferences,
                icon: Icon(
                  Theme.brightnessOf(context) == Brightness.dark
                      ? FLucideIcons.moon
                      : FLucideIcons.sun,
                  size: 19,
                ),
              ),
            IconButton(
              tooltip: 'Notificaciones',
              onPressed: onNotifications,
              icon: Badge(
                isLabelVisible: showNotificationBadges,
                smallSize: 7,
                backgroundColor: AppColors.red,
                child: Icon(FLucideIcons.bell, color: context.palette.muted),
              ),
            ),
            const SizedBox(width: 15),
            Container(height: 31, width: 1, color: context.palette.border),
            const SizedBox(width: 18),
            PopupMenuButton<String>(
              tooltip: 'Menú de cuenta',
              onSelected: (value) {
                if (value == 'profile') {
                  onProfile();
                } else if (value == 'preferences') {
                  onPreferences?.call();
                } else {
                  onLogout();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(FLucideIcons.circleUser, size: 18),
                      SizedBox(width: 9),
                      Text('Mi perfil'),
                    ],
                  ),
                ),
                if (onPreferences != null)
                  const PopupMenuItem(
                    value: 'preferences',
                    child: Row(
                      children: [
                        Icon(FLucideIcons.slidersHorizontal, size: 18),
                        SizedBox(width: 9),
                        Text('Mis preferencias'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(FLucideIcons.logOut, size: 18),
                      SizedBox(width: 9),
                      Text('Cerrar sesión'),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: context.palette.subtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UserAvatar(user: user),
                    if (showUserName) ...[
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.palette.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user.role.label,
                            style: TextStyle(
                              color: context.palette.muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        FLucideIcons.chevronDown,
                        size: 17,
                        color: context.palette.muted,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
