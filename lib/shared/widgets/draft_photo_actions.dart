import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/services/image_file_picker.dart';
import '../../core/utils/local_image_data.dart';
import 'image_frame_dialog.dart';

/// El archivo y su encuadre quedan en el borrador del formulario. Cancelar el
/// selector o el editor conserva la foto que ya estaba elegida.
class DraftPhotoActions extends StatefulWidget {
  const DraftPhotoActions({
    required this.id,
    required this.kind,
    required this.photo,
    required this.onChanged,
    required this.onBusyChanged,
    this.hasAsset = false,
    this.enabled = true,
    this.pickFile,
    super.key,
  });

  final String id, photo;
  final LocalImageKind kind;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onBusyChanged;
  final bool hasAsset, enabled;
  final Future<Uint8List?> Function()? pickFile;

  @override
  State<DraftPhotoActions> createState() => _DraftPhotoActionsState();
}

class _DraftPhotoActionsState extends State<DraftPhotoActions> {
  bool _busy = false;
  String? _error;

  Future<void> _edit({bool existing = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    widget.onBusyChanged(true);
    final parent = ModalRoute.of(context);
    try {
      final bytes = existing
          ? widget.kind.decode(widget.photo)
          : await (widget.pickFile ?? selectImageFile)();
      if (bytes == null || !mounted || parent?.isCurrent == false) return;
      final photo = await editImageFrame(context, bytes, widget.kind);
      if (mounted && parent?.isActive != false && photo != null) {
        widget.onChanged(photo);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is FormatException
              ? error.message
              : 'No se pudo abrir la foto. Vuelve a intentarlo.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusyChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && !_busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (supportsImagePicker || widget.pickFile != null)
              OutlinedButton.icon(
                key: Key('${widget.id}-pick'),
                onPressed: enabled ? _edit : null,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: Text(_busy ? 'Preparando foto…' : 'Cargar foto'),
              ),
            if (widget.photo.isNotEmpty)
              OutlinedButton.icon(
                key: Key('${widget.id}-adjust'),
                onPressed: enabled ? () => _edit(existing: true) : null,
                icon: const Icon(Icons.crop_rotate, size: 18),
                label: const Text('Ajustar foto'),
              ),
            if (widget.photo.isNotEmpty || widget.hasAsset)
              TextButton(
                key: Key('${widget.id}-remove'),
                onPressed: enabled
                    ? () {
                        setState(() => _error = null);
                        widget.onChanged('');
                      }
                    : null,
                child: const Text('Quitar foto'),
              ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              key: Key('${widget.id}-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}
