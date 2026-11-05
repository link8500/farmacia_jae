import 'package:flutter/material.dart';
import '../themes/app_palette.dart';

/// Foto local compartida por los directorios. El respaldo conserva el nombre
/// visible si una imagen falta, sin peticiones externas durante la ejecución.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    required this.name,
    required this.asset,
    this.size = 36,
    super.key,
  });
  final String name, asset;
  final double size;
  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => String.fromCharCode(p.runes.first))
        .join()
        .toUpperCase();
    final fallback = Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: context.palette.blue,
          fontWeight: FontWeight.w700,
          fontSize: size * .3,
        ),
      ),
    );
    return Semantics(
      image: true,
      label: 'Foto de $name',
      child: ClipOval(
        child: Container(
          width: size,
          height: size,
          color: context.palette.paleBlue,
          child: asset.isEmpty
              ? fallback
              : Image.asset(
                  asset,
                  key: ValueKey('person-photo-$asset'),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}
