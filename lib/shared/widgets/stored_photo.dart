import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/utils/local_image_data.dart';

/// Mantiene estable la clave de Image.memory mientras se actualiza la vista.
class StoredPhoto extends StatefulWidget {
  const StoredPhoto({
    required this.photo,
    required this.kind,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    super.key,
  });
  final String photo;
  final LocalImageKind kind;
  final Widget fallback;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  State<StoredPhoto> createState() => _StoredPhotoState();
}

class _StoredPhotoState extends State<StoredPhoto> {
  late Uint8List? _bytes = widget.kind.decode(widget.photo);

  @override
  void didUpdateWidget(covariant StoredPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo != widget.photo || oldWidget.kind != widget.kind) {
      _bytes = widget.kind.decode(widget.photo);
    }
  }

  @override
  Widget build(BuildContext context) => _bytes == null
      ? widget.fallback
      : Image.memory(
          _bytes!,
          fit: widget.fit,
          semanticLabel: widget.semanticLabel,
          excludeFromSemantics: widget.semanticLabel == null,
          errorBuilder: (_, _, _) => widget.fallback,
        );
}
