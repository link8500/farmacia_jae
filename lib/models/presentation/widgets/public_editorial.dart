import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_paths.dart';
import 'presentation_shell.dart';

/// Recursos editoriales locales: la web pública no consulta inventario privado.
class PublicPhoto extends StatelessWidget {
  const PublicPhoto({
    required this.asset,
    required this.label,
    this.height = 300,
    super.key,
  });
  final String asset, label;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: Image.asset(
      asset,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      semanticLabel: label,
    ),
  );
}

class PublicSectionHeading extends StatelessWidget {
  const PublicSectionHeading({
    required this.eyebrow,
    required this.title,
    this.action,
    super.key,
  });
  final String eyebrow, title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.end,
    runSpacing: 12,
    spacing: 20,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: PublicStyle.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 25,
              height: 1.2,
              color: PublicStyle.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      ?action,
    ],
  );
}

/// Cierre común para contactar con el establecimiento, sin formularios sin destino.
class PublicVisitBanner extends StatelessWidget {
  const PublicVisitBanner({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: PublicStyle.green,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 24,
      runSpacing: 18,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu próxima visita empieza aquí.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'La Paz Centro, León · 8:00 a. m. – 7:00 p. m.',
              style: TextStyle(color: Color(0xffcce5db), fontSize: 13),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: () => context.go(AppPaths.presentationContact),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: PublicStyle.green,
          ),
          icon: const Icon(Icons.arrow_forward, size: 17),
          label: const Text('Ubicación y contacto'),
        ),
      ],
    ),
  );
}
