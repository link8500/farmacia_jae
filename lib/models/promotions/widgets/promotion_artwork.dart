import 'package:flutter/material.dart';
import '../../products/widgets/product_thumbnail.dart';
import '../models/promotion_image.dart';

/// Un mismo recurso en el editor, el detalle administrativo y la página pública.
class PromotionArtwork extends StatelessWidget {
  const PromotionArtwork({
    required this.imageKey,
    this.height = 160,
    this.width,
    super.key,
  });
  final String imageKey;
  final double height;
  final double? width;
  @override
  Widget build(BuildContext context) {
    final photo = PromotionImages.values[imageKey];
    if (photo == null) {
      return ProductThumbnail(
        illustrationKey: imageKey,
        height: height,
        width: width,
        showCaption: height >= 80,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        photo.asset,
        width: width,
        height: height,
        fit: BoxFit.cover,
        semanticLabel: photo.name,
        errorBuilder: (_, _, _) => SizedBox(
          width: width,
          height: height,
          child: const Center(child: Icon(Icons.image_not_supported_outlined)),
        ),
      ),
    );
  }
}
