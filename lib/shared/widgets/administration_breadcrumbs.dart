import 'package:flutter/material.dart';
import '../../core/routing/app_paths.dart';
import '../themes/app_palette.dart';

/// Ubicación consistente en todas las pantallas. Wrap evita recortar rutas
/// largas en móviles y con texto grande; los padres se operan con teclado.
class AdministrationBreadcrumbs extends StatelessWidget {
  const AdministrationBreadcrumbs({
    required this.section,
    required this.uri,
    required this.onNavigate,
    super.key,
  });
  final int section;
  final Uri uri;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final items = AppPaths.breadcrumbs(section, uri);
    final palette = context.palette;
    return Semantics(
      container: true,
      label: 'Ruta de navegación',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
          12,
          MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
          0,
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            for (var i = 0; i < items.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i != 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: palette.muted,
                      ),
                    ),
                  Flexible(
                    child: i == items.length - 1
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 4,
                            ),
                            child: Text(
                              items[i].label,
                              key: const Key('breadcrumb-current'),
                              style: TextStyle(
                                color: palette.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : TextButton(
                            onPressed: () => onNavigate(items[i].location!),
                            style: TextButton.styleFrom(
                              foregroundColor: palette.muted,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 12,
                              ),
                              textStyle: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(fontSize: 12),
                            ),
                            child: Text(items[i].label),
                          ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
