import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_paths.dart';
import '../widgets/presentation_shell.dart';
import '../widgets/public_editorial.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) => PresentationShell(
    path: AppPaths.presentationAbout,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PublicTitle(
                  eyebrow: 'Nuestra farmacia',
                  title: 'El cuidado empieza\ncon cercanía.',
                  description:
                      'Somos Farmacia JAE, en La Paz Centro, León. Este es nuestro espacio para compartir las áreas de productos, las campañas y la información que necesitas antes de visitarnos.',
                ),
                const SizedBox(height: 20),
                const Text(
                  'Medicamentos, bienestar y cuidado personal en un mismo lugar. El establecimiento es el punto de encuentro para consultar las presentaciones y confirmar la disponibilidad.',
                  style: TextStyle(
                    height: 1.8,
                    color: PublicStyle.muted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () => context.go(AppPaths.presentationContact),
                  child: const Text('Conoce cómo visitarnos →'),
                ),
              ],
            );
            const photo = PublicPhoto(
              asset: 'images/promotions/bienestar.jpg',
              label: 'Artículos de bienestar y cuidado cotidiano',
              height: 340,
            );
            return box.maxWidth < 720
                ? Column(children: [copy, const SizedBox(height: 24), photo])
                : Row(
                    children: [
                      Expanded(child: copy),
                      const SizedBox(width: 48),
                      const Expanded(child: photo),
                    ],
                  );
          },
        ),
        const SizedBox(height: 32),
        const PublicSectionHeading(
          eyebrow: 'Lo que puedes encontrar',
          title: 'Una visita, información más clara.',
        ),
        const SizedBox(height: 18),
        for (final item in const [
          (
            '01',
            'Conoce cada presentación',
            'Nombre, concentración y formato para identificar mejor el artículo que buscas.',
          ),
          (
            '02',
            'Revisa las campañas',
            'Fechas y condiciones visibles para que conozcas los detalles antes de visitarnos.',
          ),
          (
            '03',
            'Consulta en el establecimiento',
            'Confirma precios, disponibilidad y requisitos de dispensación con el personal de la farmacia.',
          ),
        ])
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xffdce7df))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.$1,
                  style: const TextStyle(
                    color: PublicStyle.green,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$2,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: PublicStyle.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.$3,
                        style: const TextStyle(
                          color: PublicStyle.muted,
                          height: 1.6,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 28),
        const PublicVisitBanner(),
      ],
    ),
  );
}
