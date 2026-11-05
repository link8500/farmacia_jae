import 'package:flutter/material.dart';
import '../themes/app_palette.dart';

/// Identidad reutilizable de JAE, sin copiar la marca de la referencia Saba.
class PharmacyBrand extends StatelessWidget {
  const PharmacyBrand({
    this.color = AppColors.verde,
    this.compact = false,
    this.subtitle = 'Farmacia JAE',
    super.key,
  });
  final Color color;
  final bool compact;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: compact ? 38 : 44,
        height: compact ? 38 : 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const CircleAvatar(
          backgroundColor: Colors.transparent,
          backgroundImage: AssetImage('images/icon.png'),
        ),
      ),
      const SizedBox(width: 11),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farmacia JAE',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.palette.ink,
                fontSize: compact ? 16 : 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
              ),
            ),
            Text(
              subtitle == 'Farmacia JAE' ? 'Cerca de tu bienestar' : subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.palette.muted, fontSize: 10),
            ),
          ],
        ),
      ),
    ],
  );
}
