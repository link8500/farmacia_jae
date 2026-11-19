import 'dart:typed_data';

import '../../../core/utils/local_image_data.dart';

/// Claves estables y permitidas para el avatar; nunca se guardan IconData,
/// permisos, URLs de terceros ni rutas a archivos personales.
enum ProfileSymbol {
  initials('Iniciales'),
  person('Persona'),
  smile('Sonrisa'),
  flower('Flor'),
  star('Estrella'),
  heart('Corazón'),
  pharmacy('Farmacia'),
  work('Trabajo');

  const ProfileSymbol(this.label);
  final String label;
}

enum ProfileTone {
  navy('Azul marino'),
  blue('Azul'),
  teal('Verde'),
  purple('Violeta'),
  rose('Rosa'),
  amber('Ámbar');

  const ProfileTone(this.label);
  final String label;
}

abstract final class ProfileFields {
  static String? name(String? value) => (value?.trim().isEmpty ?? true)
      ? 'El nombre no puede quedar vacío.'
      : value!.trim().length > 100
      ? 'Usa un nombre de hasta 100 caracteres.'
      : null;
  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final digits = text.replaceAll(RegExp(r'\D'), '');
    return text.length <= 32 &&
            RegExp(r'^[+0-9() .-]+$').hasMatch(text) &&
            digits.length >= 7 &&
            digits.length <= 20
        ? null
        : 'Indica un teléfono válido o deja el campo vacío.';
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ||
            (text.length <= 254 &&
                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text))
        ? null
        : 'Indica un correo válido o deja el campo vacío.';
  }
}

/// La foto es una miniatura local pequeña. Se rechazan SVG, URLs y datos
/// excesivos tanto al seleccionar como al recuperar el perfil guardado.
abstract final class ProfilePhoto {
  static int get maxBytes => LocalImageKind.avatar.maxBytes;

  static Uint8List? decode(String value) => LocalImageKind.avatar.decode(value);
}
