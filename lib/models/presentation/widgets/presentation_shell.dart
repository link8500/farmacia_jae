import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_paths.dart';
import '../../../shared/widgets/pharmacy_brand.dart';

abstract final class PublicStyle {
  static const green = Color(0xff126a51),
      ink = Color(0xff183c34),
      muted = Color(0xff63756c),
      mint = Color(0xfff0f5ef);
  static const links = [
    (AppPaths.presentation, 'Inicio'),
    (AppPaths.presentationAbout, 'Nosotros'),
    (AppPaths.presentationServices, 'Servicios'),
    (AppPaths.publicPromotions, 'Promociones'),
    (AppPaths.presentationContact, 'Contacto'),
  ];
}

/// Marco público reutilizable. La navegación cambia rutas reales, no posiciones
/// de scroll. No expone login ni enlaces a la administración.
class PresentationShell extends StatelessWidget {
  const PresentationShell({required this.path, required this.child, super.key});
  final String path;
  final Widget child;
  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Arial',
      fontFamilyFallback: const ['Roboto'],
      colorScheme: ColorScheme.fromSeed(
        seedColor: PublicStyle.green,
        brightness: Brightness.light,
      ).copyWith(primary: PublicStyle.green),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: PublicStyle.green),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    child: Scaffold(
      backgroundColor: const Color(0xfffcfdfb),
      body: LayoutBuilder(
        builder: (context, box) {
          final compact = box.maxWidth < 1000;
          return Column(
            children: [
              Container(
                width: double.infinity,
                color: PublicStyle.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: const Text(
                  'La Paz Centro, León   ·   Cuidado y atención cerca de ti',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
              Material(
                color: Colors.white,
                child: PublicContainer(
                  vertical: 16,
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => context.go(AppPaths.presentation),
                          child: const PharmacyBrand(
                            compact: true,
                            color: PublicStyle.green,
                            subtitle: 'Salud y cuidado cotidiano',
                          ),
                        ),
                      ),
                      if (compact)
                        PopupMenuButton<String>(
                          key: const Key('public-menu'),
                          tooltip: 'Abrir menú de presentación',
                          icon: const Icon(
                            Icons.menu_rounded,
                            color: PublicStyle.green,
                          ),
                          onSelected: context.go,
                          itemBuilder: (_) => [
                            for (final link in PublicStyle.links)
                              PopupMenuItem(
                                value: link.$1,
                                child: Text(link.$2),
                              ),
                          ],
                        )
                      else
                        for (final link in PublicStyle.links)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: TextButton(
                              key: Key('public-nav-${link.$2}'),
                              onPressed: () => context.go(link.$1),
                              style: TextButton.styleFrom(
                                foregroundColor: path == link.$1
                                    ? PublicStyle.green
                                    : PublicStyle.muted,
                              ),
                              child: Text(
                                link.$2,
                                style: TextStyle(
                                  fontWeight: path == link.$1
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  key: PageStorageKey(path),
                  child: Column(
                    children: [
                      PublicContainer(child: child),
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Color(0xffe2ebe3)),
                          ),
                        ),
                        child: PublicContainer(
                          vertical: 22,
                          child: const _PublicFooter(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class PublicContainer extends StatelessWidget {
  const PublicContainer({required this.child, this.vertical = 26, super.key});
  final Widget child;
  final double vertical;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: MediaQuery.sizeOf(context).width < 600 ? 20 : 48,
      vertical: vertical,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );
}

class PublicTitle extends StatelessWidget {
  const PublicTitle({
    required this.eyebrow,
    required this.title,
    required this.description,
    super.key,
  });
  final String eyebrow, title, description;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow.toUpperCase(),
        style: const TextStyle(
          color: PublicStyle.green,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 1.4,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        title,
        style: TextStyle(
          color: PublicStyle.ink,
          fontSize: MediaQuery.sizeOf(context).width < 600 ? 30 : 40,
          fontWeight: FontWeight.w800,
          height: 1.15,
          letterSpacing: -.8,
        ),
      ),
      const SizedBox(height: 14),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 740),
        child: Text(
          description,
          style: const TextStyle(
            color: PublicStyle.muted,
            fontSize: 14,
            height: 1.65,
          ),
        ),
      ),
    ],
  );
}

class PublicInfoCard extends StatelessWidget {
  const PublicInfoCard({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });
  final IconData icon;
  final String title, description;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xffdfe9df)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: PublicStyle.green),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(
            color: PublicStyle.ink,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(
            color: PublicStyle.muted,
            height: 1.6,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

/// Pie editorial con rutas públicas reales y los datos del establecimiento.
class _PublicFooter extends StatelessWidget {
  const _PublicFooter();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 40,
        runSpacing: 24,
        children: [
          const SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Farmacia JAE',
                  style: TextStyle(
                    color: PublicStyle.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Medicamentos, cuidado personal y bienestar para tu día a día.',
                  style: TextStyle(
                    color: PublicStyle.muted,
                    fontSize: 12,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EXPLORA LA FARMACIA',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.3,
                  color: PublicStyle.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              for (final link in PublicStyle.links.where(
                (l) => l.$1 != AppPaths.presentation,
              ))
                TextButton(
                  onPressed: () => context.go(link.$1),
                  child: Text(link.$2, style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(
            width: 240,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VISÍTANOS',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.3,
                    color: PublicStyle.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'La Paz Centro, León\n8:00 a. m. – 7:00 p. m.\n+505 8851 0466',
                  style: TextStyle(
                    color: PublicStyle.muted,
                    fontSize: 12,
                    height: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const Divider(height: 32, color: Color(0xffdce7e0)),
      const Text(
        'Farmacia JAE · Información de productos y campañas. La disponibilidad y dispensación se confirman en el establecimiento.',
        style: TextStyle(fontSize: 10, color: PublicStyle.muted, height: 1.6),
      ),
    ],
  );
}
