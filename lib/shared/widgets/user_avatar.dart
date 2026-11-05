import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/auth/models/session_user.dart';
import '../../models/profile/models/profile_appearance.dart';

/// El mismo avatar para perfil, cabecera, menú y móvil. Los mapas constantes
/// permiten eliminar iconos no usados al compilar; no interpretamos códigos externos.
class UserAvatar extends StatefulWidget {
  const UserAvatar({required this.user, this.size = 36, super.key});
  final SessionUser user;
  final double size;
  static const symbols = <ProfileSymbol, IconData>{
    ProfileSymbol.person: Icons.person_outline_rounded,
    ProfileSymbol.smile: Icons.sentiment_satisfied_alt_rounded,
    ProfileSymbol.flower: Icons.local_florist_outlined,
    ProfileSymbol.star: Icons.star_outline_rounded,
    ProfileSymbol.heart: Icons.favorite_border_rounded,
    ProfileSymbol.pharmacy: Icons.local_pharmacy_outlined,
    ProfileSymbol.work: Icons.work_outline_rounded,
  };
  static const tones = <ProfileTone, Color>{
    ProfileTone.navy: Color(0xff17324e),
    ProfileTone.blue: Color(0xff1d4ed8),
    ProfileTone.teal: Color(0xff0f766e),
    ProfileTone.purple: Color(0xff6d28d9),
    ProfileTone.rose: Color(0xff9f1239),
    ProfileTone.amber: Color(0xff92400e),
  };
  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  Uint8List? _bytes;
  @override
  void initState() {
    super.initState();
    _bytes = ProfilePhoto.decode(widget.user.avatarPhoto);
  }

  @override
  void didUpdateWidget(covariant UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.avatarPhoto != widget.user.avatarPhoto) {
      _bytes = ProfilePhoto.decode(widget.user.avatarPhoto);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final fallback = Center(
      child: user.avatarSymbol == ProfileSymbol.initials
          ? FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Text(
                  user.initials.isEmpty ? '?' : user.initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.size * .32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          : Icon(
              UserAvatar.symbols[user.avatarSymbol],
              color: Colors.white,
              size: widget.size * .53,
            ),
    );
    return Semantics(
      image: true,
      label: 'Avatar de ${user.name}',
      excludeSemantics: true,
      child: Container(
        width: widget.size,
        height: widget.size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: UserAvatar.tones[user.avatarTone],
          shape: BoxShape.circle,
        ),
        child: _bytes == null
            ? user.avatarAsset.isNotEmpty &&
                      user.avatarSymbol == ProfileSymbol.initials
                  ? Image.asset(
                      user.avatarAsset,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      errorBuilder: (_, _, _) => fallback,
                    )
                  : fallback
            : Padding(
                padding: EdgeInsets.all(widget.size > 60 ? 3 : 1.5),
                child: ClipOval(
                  child: Image.memory(
                    _bytes!,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => fallback,
                  ),
                ),
              ),
      ),
    );
  }
}
