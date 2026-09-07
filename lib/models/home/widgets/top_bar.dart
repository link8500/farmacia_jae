import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/themes/app_colors.dart';

/// Barra superior para escritorio.
class TopBar extends StatelessWidget {
  /// Crea la barra con el título actual y acceso a notificaciones.
  const TopBar({required this.title, required this.onNotifications, super.key});

  /// Nombre de la pantalla activa.
  final String title;

  /// Acción del botón de notificaciones.
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // La búsqueda y el texto del usuario son accesorios: se ocultan
        // antes de provocar overflow para priorizar título y notificaciones.
        final showSearch = constraints.maxWidth >= AppBreakpoints.desktop;
        final showUserName = constraints.maxWidth >= 760;

        return Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 34),
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              if (showSearch)
                const SizedBox(
                  width: 250,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar en el sistema',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
              IconButton(
                onPressed: onNotifications,
                icon: const Badge(
                  smallSize: 7,
                  backgroundColor: AppColors.red,
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.muted,
                  ),
                ),
              ),
              const CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.navy,
                child: Text(
                  'AD',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
              if (showUserName) ...[
                const SizedBox(width: 9),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Administrador',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Farmacia JAE',
                      style: TextStyle(color: AppColors.muted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
