import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../utils/local_image_data.dart';

bool get supportsImagePicker => true;

/// Lee el archivo original para que el encuadre pueda ajustarse antes de reducirlo.
Future<Uint8List?> selectImageFile() {
  final result = Completer<Uint8List?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.jpg,.jpeg,.png,.webp,image/jpeg,image/png,image/webp';
  input.style.display = 'none';
  web.document.body?.appendChild(input);
  input.oncancel = ((web.Event _) {
    if (!result.isCompleted) result.complete(null);
  }).toJS;
  input.onchange = ((web.Event _) {
    () async {
      try {
        final file = input.files?.item(0);
        if (file == null) {
          if (!result.isCompleted) result.complete(null);
          return;
        }
        if (file.size > LocalImageKind.maxOriginalBytes) {
          throw const FormatException(
            'El archivo original no debe superar 8 MB.',
          );
        }
        final buffer = await file.arrayBuffer().toDart.timeout(
          const Duration(seconds: 15),
        );
        if (!result.isCompleted) {
          result.complete(buffer.toDart.asUint8List());
        }
      } catch (error) {
        if (!result.isCompleted) result.completeError(error);
      }
    }();
  }).toJS;
  input.click();
  return result.future.whenComplete(() => input.remove());
}

/// Reduce únicamente la imagen ya encuadrada. No cambia su proporción.
Future<String> compressFramedImage(Uint8List png, LocalImageKind kind) async {
  final url = web.URL.createObjectURL(
    web.Blob([png.toJS].toJS, web.BlobPropertyBag(type: 'image/png')),
  );
  try {
    final image = web.HTMLImageElement()..src = url;
    await image.decode().toDart.timeout(const Duration(seconds: 15));
    final canvas = web.HTMLCanvasElement();
    for (final scale in [1.0, .8, .6, .45]) {
      canvas
        ..width = math.max(1, (image.naturalWidth * scale).round())
        ..height = math.max(1, (image.naturalHeight * scale).round());
      final drawing = canvas.getContext('2d') as web.CanvasRenderingContext2D;
      drawing.drawImage(image, 0, 0, canvas.width, canvas.height);
      for (final quality in [.88, .74, .60, .46]) {
        final photo = canvas.toDataURL('image/jpeg', quality.toJS);
        if (kind.decode(photo) != null) return photo;
      }
    }
    throw const FormatException(
      'No se pudo reducir la imagen al tamaño permitido.',
    );
  } finally {
    web.URL.revokeObjectURL(url);
  }
}
