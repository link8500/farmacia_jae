import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'package:web/web.dart' as web;
import '../../models/profile/models/profile_appearance.dart';

bool get supportsProfilePhoto => true;

/// Lee y reduce la foto en el propio navegador. Nunca se sube a un servidor:
/// solo se conserva un JPEG de hasta 256 px y 128 KB en el perfil de la cuenta.
Future<String?> selectProfilePhoto() {
  final result = Completer<String?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/jpeg,image/png,image/webp';
  // Mantener el input conectado al documento hace fiable la selección de
  // archivos en navegadores y herramientas de accesibilidad; se retira al acabar.
  input.style.display = 'none';
  web.document.body?.appendChild(input);
  input.oncancel = ((web.Event _) {
    if (!result.isCompleted) result.complete(null);
  }).toJS;
  input.onchange = ((web.Event _) {
    () async {
      final file = input.files?.item(0);
      if (file == null) {
        if (!result.isCompleted) result.complete(null);
        return;
      }
      try {
        if (!{'image/jpeg', 'image/png', 'image/webp'}.contains(file.type)) {
          throw const FormatException('Elige una foto JPG, PNG o WebP.');
        }
        if (file.size > 5 * 1024 * 1024) {
          throw const FormatException('La foto original no debe superar 5 MB.');
        }
        final url = web.URL.createObjectURL(file);
        try {
          final image = web.HTMLImageElement()..src = url;
          await image.decode().toDart.timeout(const Duration(seconds: 15));
          if (image.naturalWidth <= 0 || image.naturalHeight <= 0) {
            throw const FormatException('No se pudo leer la foto.');
          }
          final ratio = math.min(
            1,
            256 / math.max(image.naturalWidth, image.naturalHeight),
          );
          final canvas = web.HTMLCanvasElement()
            ..width = math.max(1, (image.naturalWidth * ratio).round())
            ..height = math.max(1, (image.naturalHeight * ratio).round());
          final drawing =
              canvas.getContext('2d') as web.CanvasRenderingContext2D;
          drawing.fillStyle = '#ffffff'.toJS;
          drawing.fillRect(0, 0, canvas.width, canvas.height);
          drawing.drawImage(image, 0, 0, canvas.width, canvas.height);
          final photo = canvas.toDataURL('image/jpeg', 0.85.toJS);
          if (ProfilePhoto.decode(photo) == null) {
            throw const FormatException(
              'No se pudo optimizar la foto. Prueba con otra imagen.',
            );
          }
          if (!result.isCompleted) result.complete(photo);
        } finally {
          web.URL.revokeObjectURL(url);
        }
      } catch (error) {
        if (!result.isCompleted) {
          result.completeError(
            error is FormatException
                ? error
                : const FormatException(
                    'No se pudo procesar la foto. Prueba con otra imagen.',
                  ),
          );
        }
      }
    }();
  }).toJS;
  input.click();
  return result.future.whenComplete(() => input.remove());
}
