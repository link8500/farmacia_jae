import 'dart:convert';
import 'dart:typed_data';

import '../utils/local_image_data.dart';

bool get supportsImagePicker => false;
Future<Uint8List?> selectImageFile() async => null;

Future<String> compressFramedImage(Uint8List png, LocalImageKind kind) async {
  if (png.length > kind.maxBytes) {
    throw const FormatException(
      'No se pudo reducir la imagen al tamaño permitido.',
    );
  }
  return 'data:image/png;base64,${base64Encode(png)}';
}
