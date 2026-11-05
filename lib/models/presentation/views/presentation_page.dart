import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_paths.dart';
import '../../../shared/widgets/adaptive_grid.dart';
import '../models/presentation_content.dart';
import '../widgets/presentation_shell.dart';
import '../widgets/public_editorial.dart';

/// Portada publicitaria breve: cada llamada abre una página con contenido propio.
class PresentationPage extends StatelessWidget {
  const PresentationPage({super.key});
  @override
  Widget build(BuildContext context) => PresentationShell(
    path: AppPaths.presentation,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final compact = box.maxWidth < 760;
            final copy = Padding(
              padding: EdgeInsets.all(compact ? 24 : 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FARMACIA JAE / LA PAZ CENTRO',
                    style: TextStyle(
                      color: PublicStyle.green,
                      fontSize: 11,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cuidado que\nacompaña tu día.',
                    style: TextStyle(
                      fontSize: compact ? 34 : 48,
                      height: 1.08,
                      letterSpacing: -1.5,
                      fontWeight: FontWeight.w800,
                      color: PublicStyle.ink,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Medicamentos, cuidado personal y artículos para tu botiquín. Encuentra información clara y prepara tu próxima visita a nuestra farmacia.',
                    style: TextStyle(
                      color: PublicStyle.muted,
                      fontSize: 14,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        key: const Key('home-promotions'),
                        onPressed: () => context.go(AppPaths.publicPromotions),
                        icon: const Icon(Icons.arrow_forward, size: 17),
                        label: const Text('Descubrir promociones'),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.go(AppPaths.presentationServices),
                        child: const Text('Explorar productos'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: PublicStyle.green,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'La Paz Centro, León · Atención presencial',
                          style: TextStyle(
                            fontSize: 11,
                            color: PublicStyle.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
            final picture = Stack(
              children: [
                PublicPhoto(
                  asset: 'images/promotions/cuidado.jpg',
                  label: 'Artículos de cuidado personal',
                  height: compact ? 210 : 370,
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .95),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.spa_outlined,
                          color: PublicStyle.green,
                          size: 26,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'El bienestar está en lo cotidiano.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: PublicStyle.ink,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Conoce nuestras áreas de cuidado.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: PublicStyle.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
            return Container(
              decoration: BoxDecoration(
                color: PublicStyle.mint,
                borderRadius: BorderRadius.circular(22),
              ),
              clipBehavior: Clip.antiAlias,
              child: compact
                  ? Column(
                      children: [
                        copy,
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: picture,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 6, child: copy),
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: picture,
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
        const SizedBox(height: 32),
        PublicSectionHeading(
          eyebrow: 'Para cada momento',
          title: 'Explora nuestras categorías',
          action: TextButton(
            onPressed: () => context.go(AppPaths.presentationServices),
            child: const Text('Ver productos →'),
          ),
        ),
        const SizedBox(height: 16),
        AdaptiveGrid(
          minItemWidth: 210,
          maxColumns: 4,
          children: [
            for (var i = 0; i < PresentationContent.categories.length; i++)
              _CategoryLink(index: i),
          ],
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, box) {
            final image = const PublicPhoto(
              asset: 'images/promotions/botiquin.jpg',
              label: 'Artículos para organizar el botiquín',
              height: 210,
            );
            final copy = Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EN NUESTRA FARMACIA',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.4,
                      color: PublicStyle.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Un botiquín mejor organizado.',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: PublicStyle.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Conoce los artículos de primeros auxilios y revisa las campañas vigentes antes de visitarnos.',
                    style: TextStyle(
                      color: PublicStyle.muted,
                      height: 1.6,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go(AppPaths.publicPromotions),
                    child: const Text('Ver novedades y condiciones →'),
                  ),
                ],
              ),
            );
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffdde7e0)),
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              child: box.maxWidth < 650
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [image, copy],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 4, child: image),
                        Expanded(flex: 6, child: copy),
                      ],
                    ),
            );
          },
        ),
      ],
    ),
  );
}

class _CategoryLink extends StatelessWidget {
  const _CategoryLink({required this.index});
  final int index;
  @override
  Widget build(BuildContext context) {
    final category = PresentationContent.categories[index];
    const icons = [
      Icons.medication_outlined,
      Icons.spa_outlined,
      Icons.favorite_border,
      Icons.medical_services_outlined,
    ];
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xffdce7df)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(
          '${AppPaths.presentationServices}?categoria=${Uri.encodeQueryComponent(category.title)}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icons[index], color: PublicStyle.green, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  category.title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: PublicStyle.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.north_east, size: 15, color: PublicStyle.muted),
            ],
          ),
        ),
      ),
    );
  }
}
