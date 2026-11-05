import 'package:flutter/material.dart';
import '../../../core/routing/app_paths.dart';
import '../../../core/services/promotion_store.dart';
import '../../../core/services/promotions_controller.dart';
import '../../../shared/widgets/adaptive_grid.dart';
import '../../promotions/widgets/public_promotion_card.dart';
import '../widgets/presentation_shell.dart';

/// Única vista pública con contenido gestionado. Solo lee el documento público
/// local; las demás vistas de presentación permanecen completamente estáticas.
class PublicPromotionsPage extends StatefulWidget {
  const PublicPromotionsPage({this.controller, super.key});
  final PromotionsController? controller;
  @override
  State<PublicPromotionsPage> createState() => _PublicPromotionsPageState();
}

class _PublicPromotionsPageState extends State<PublicPromotionsPage> {
  late final PromotionsController _data;
  @override
  void initState() {
    super.initState();
    _data =
        widget.controller ??
        PromotionsController(
          store: MemoryPromotionStore(),
          canManage: () => false,
        );
    _data.loadPublic();
  }

  @override
  void dispose() {
    if (widget.controller == null) _data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PresentationShell(
    path: AppPaths.publicPromotions,
    child: AnimatedBuilder(
      animation: _data,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PublicTitle(
            eyebrow: 'Novedades de la farmacia',
            title: 'Promociones para ti.',
            description:
                'Conoce las campañas publicadas y vigentes. Revisa siempre sus fechas y condiciones; la disponibilidad se confirma en el establecimiento.',
          ),
          const SizedBox(height: 30),
          if (_data.publicError != null)
            PublicInfoCard(
              icon: Icons.cloud_off_outlined,
              title: 'No se pudo cargar el contenido',
              description: _data.publicError!,
            )
          else if (!_data.publicLoaded)
            const Center(child: CircularProgressIndicator())
          else if (_data.visible.isEmpty)
            const PublicInfoCard(
              icon: Icons.local_offer_outlined,
              title: 'Pronto compartiremos novedades',
              description:
                  'No hay promociones publicadas vigentes por ahora. Puedes consultar las novedades directamente en la farmacia.',
            )
          else
            AdaptiveGrid(
              minItemWidth: 300,
              children: [
                for (final p in _data.visible)
                  PublicPromotionCard(promotion: p),
              ],
            ),
          if (_data.publicError != null)
            TextButton(
              onPressed: () => _data.loadPublic(retry: true),
              child: const Text('Reintentar'),
            ),
        ],
      ),
    ),
  );
}
