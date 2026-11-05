import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/routing/app_paths.dart';
import '../../../core/services/public_links.dart';
import '../widgets/presentation_shell.dart';
import '../widgets/public_editorial.dart';

/// Contacto editorial: utiliza los datos del establecimiento ya incluidos en el
/// proyecto. No solicita información personal ni envía formularios sin backend.
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});
  static const phone = '+505 8851 0466';
  static const mapUrl =
      'https://www.google.com/maps/search/?api=1&query=La%20Paz%20Centro%2C%20Le%C3%B3n%2C%20Nicaragua';
  Future<void> _open(BuildContext context, String url, String copied) async {
    if (openPublicLink(url)) return;
    await Clipboard.setData(ClipboardData(text: copied));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Información copiada al portapapeles.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PresentationShell(
    path: AppPaths.presentationContact,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PublicTitle(
          eyebrow: 'Ubicación y contacto',
          title: 'Nos vemos en la farmacia.',
          description:
              'Consulta el horario y los datos de contacto. Para confirmar un producto, ten a mano su nombre, concentración y presentación.',
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, box) {
            final details = Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: PublicStyle.mint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'FARMACIA JAE',
                    style: TextStyle(
                      letterSpacing: 1.5,
                      color: PublicStyle.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final item in const [
                    (
                      Icons.location_on_outlined,
                      'Ubicación',
                      'La Paz Centro, León, Nicaragua',
                    ),
                    (
                      Icons.schedule_outlined,
                      'Horario de atención',
                      '8:00 a. m. – 7:00 p. m.',
                    ),
                    (Icons.phone_outlined, 'Teléfono', phone),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(item.$1, size: 22, color: PublicStyle.green),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.$2,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: PublicStyle.muted,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SelectableText(
                                  item.$3,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: PublicStyle.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        key: const Key('public-phone'),
                        onPressed: () =>
                            _open(context, 'tel:+50588510466', phone),
                        icon: const Icon(Icons.call_outlined, size: 17),
                        label: const Text('Llamar a la farmacia'),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            const ClipboardData(text: phone),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Teléfono copiado.'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_outlined, size: 16),
                        label: const Text('Copiar teléfono'),
                      ),
                    ],
                  ),
                ],
              ),
            );
            final visit = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PublicPhoto(
                  asset: 'images/promotions/botiquin.jpg',
                  label: 'Artículos de primeros auxilios',
                  height: 240,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Planea tu visita',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: PublicStyle.ink,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Puedes consultar la zona de La Paz Centro en el mapa. Comunícate con la farmacia para confirmar la dirección y las referencias de llegada.',
                  style: TextStyle(
                    color: PublicStyle.muted,
                    height: 1.7,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _open(context, mapUrl, mapUrl),
                    icon: const Icon(Icons.map_outlined, size: 17),
                    label: const Text('Ver zona en el mapa'),
                  ),
                ),
              ],
            );
            return box.maxWidth < 720
                ? Column(children: [details, const SizedBox(height: 24), visit])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: details),
                      const SizedBox(width: 36),
                      Expanded(child: visit),
                    ],
                  );
          },
        ),
        const SizedBox(height: 28),
        const Text(
          'Antes de venir',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: PublicStyle.ink,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Confirma la disponibilidad por teléfono. Si tu medicamento requiere receta, preséntala al personal. Las condiciones de cada campaña están detalladas en Promociones.',
          style: TextStyle(fontSize: 13, height: 1.8, color: PublicStyle.muted),
        ),
      ],
    ),
  );
}
