import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../presentation/widgets/presentation_shell.dart';
import 'promotion_artwork.dart';
import '../models/promotion.dart';

/// Solo contenido editorial ya publicado; no recibe precios o stock privados.
class PublicPromotionCard extends StatelessWidget {
  const PublicPromotionCard({required this.promotion, super.key});
  final Promotion promotion;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffdfe9df)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (promotion.illustrationKey.isNotEmpty)
            PromotionArtwork(imageKey: promotion.illustrationKey, height: 150)
          else
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: PublicStyle.mint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_offer_outlined,
                color: PublicStyle.green,
                size: 52,
              ),
            ),
          const SizedBox(height: 18),
          Text(
            promotion.badge.toUpperCase(),
            style: const TextStyle(
              color: PublicStyle.green,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            promotion.title,
            style: const TextStyle(
              color: PublicStyle.ink,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            promotion.description,
            style: const TextStyle(
              color: PublicStyle.muted,
              height: 1.6,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Vigencia: ${formatDate(promotion.startsAt)} — ${formatDate(promotion.endsAt)}',
            style: const TextStyle(
              color: PublicStyle.green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (promotion.conditions.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Ver condiciones',
                style: TextStyle(fontSize: 13),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    promotion.conditions,
                    style: const TextStyle(
                      color: PublicStyle.muted,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          const Text(
            'Consulta disponibilidad y condiciones en la farmacia.',
            style: TextStyle(color: PublicStyle.muted, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}
