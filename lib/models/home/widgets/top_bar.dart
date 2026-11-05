import 'package:flutter/material.dart';
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
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          color: context.palette.surface,
          border: Border(bottom: BorderSide(color: context.palette.border)),
        ),
        child: Row(
          children: [
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
            IconButton(
              tooltip: 'Notificaciones',
              onPressed: onNotifications,
              icon: Badge(
                isLabelVisible: showNotificationBadges,
                smallSize: 7,
                backgroundColor: AppColors.red,
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: context.palette.muted,
                ),
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
                      Icon(Icons.person_outline, size: 18),
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
                        Icon(Icons.tune_rounded, size: 18),
                        SizedBox(width: 9),
                        Text('Mis preferencias'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18),
                      SizedBox(width: 9),
                      Text('Cerrar sesión'),
                    ],
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
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
                          Text(
                            user.name,
                            style: TextStyle(
                              color: context.palette.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
                        Icons.keyboard_arrow_down_rounded,
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
