import 'package:flutter/material.dart';
import '../../../shared/themes/app_palette.dart';
import '../models/product_illustration.dart';

/// Miniatura reutilizable en ficha, formulario y facturación. Mantiene el
/// encuadre completo, una superficie blanca en ambos temas y un fallback local.
/// La imagen es orientativa: el nombre/código del producto sigue siendo la
/// identificación operativa, nunca el color o la forma de las tabletas.
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({
    required this.illustrationKey,
    this.width,
    this.height = 110,
    this.showCaption = false,
    super.key,
  });

  final String illustrationKey;
  final double? width;
  final double height;
  final bool showCaption;

  @override
  Widget build(BuildContext context) {
    final image = ProductIllustrations.find(illustrationKey);
    final label = image?.name ?? 'Sin imagen de producto';
    final fallback = Center(
      child: Icon(
        Icons.medication_outlined,
        color: const Color(0xff64748b),
        size: height < 80 ? 24 : 36,
      ),
    );
    return Semantics(
      image: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: height,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: context.palette.border),
                ),
                child: image == null
                    ? fallback
                    : Padding(
                        padding: const EdgeInsets.all(5),
                        child: Image.asset(
                          image.assetPath,
                          fit: BoxFit.contain,
                          cacheWidth: 512,
                          excludeFromSemantics: true,
                          // Un error de recurso no debe confundirse con una
                          // ficha que nunca tuvo una imagen seleccionada.
                          errorBuilder: (_, _, _) => Tooltip(
                            message:
                                'No se pudo cargar la imagen. Recarga la aplicación; si estás desarrollando, realiza un Hot Restart para actualizar los recursos.',
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: const Color(0xff64748b),
                                size: height < 80 ? 24 : 36,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              // Las imágenes cargadas se muestran sin etiqueta al pie.
              if (showCaption && image == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Sin imagen',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.palette.muted,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
