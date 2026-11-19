import 'dart:convert';
import 'dart:typed_data';

/// Las imágenes se guardan comprimidas en los documentos locales existentes.
/// Se conservan los formatos admitidos por los perfiles de versiones anteriores.
enum LocalImageKind {
  avatar(256, 128 * 1024),
  product(512, 36 * 1024),
  promotion(896, 72 * 1024);

  const LocalImageKind(this.maxSide, this.maxBytes);
  final int maxSide, maxBytes;

  static const maxOriginalBytes = 8 * 1024 * 1024;
  static final _prefix = RegExp(r'^data:image/(jpeg|png|webp);base64,');

  Uint8List? decode(String data) {
    if (data.length > ((maxBytes + 2) ~/ 3) * 4 + 64) return null;
    final prefix = _prefix.firstMatch(data);
    if (prefix == null) return null;
    try {
      final bytes = base64Decode(data.substring(prefix.end));
      return bytes.length <= maxBytes && formatOf(bytes) == prefix.group(1)
          ? bytes
          : null;
    } on FormatException {
      return null;
    }
  }

  static String? formatOf(Uint8List bytes) {
    bool startsWith(List<int> signature, [int start = 0]) {
      if (bytes.length < start + signature.length) return false;
      for (var i = 0; i < signature.length; i++) {
        if (bytes[start + i] != signature[i]) return false;
      }
      return true;
    }

    if (startsWith(const [255, 216, 255])) return 'jpeg';
    if (startsWith(const [137, 80, 78, 71, 13, 10, 26, 10])) return 'png';
    if (startsWith(const [82, 73, 70, 70]) &&
        startsWith(const [87, 69, 66, 80], 8)) {
      return 'webp';
    }
    return null;
  }
}
