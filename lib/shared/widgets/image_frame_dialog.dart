import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/services/image_file_picker.dart';
import '../../core/utils/local_image_data.dart';
import '../themes/app_palette.dart';
import 'form_dialog.dart';

/// Abre el editor solo después de comprobar y decodificar el archivo.
Future<String?> editImageFrame(
  BuildContext context,
  Uint8List bytes,
  LocalImageKind kind,
) async {
  if (bytes.length > LocalImageKind.maxOriginalBytes) {
    throw const FormatException('El archivo original no debe superar 8 MB.');
  }
  if (LocalImageKind.formatOf(bytes) == null) {
    throw const FormatException('Selecciona una imagen JPG, PNG o WebP.');
  }
  final parent = ModalRoute.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  late ui.Image image;
  try {
    final codec = await ui.instantiateImageCodecWithSize(
      await ui.ImmutableBuffer.fromUint8List(bytes),
      getTargetSize: (width, height) {
        final scale = math.min(1.0, 2000 / math.max(width, height));
        return ui.TargetImageSize(
          width: math.max(1, (width * scale).round()),
          height: math.max(1, (height * scale).round()),
        );
      },
    );
    try {
      image = (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  } catch (_) {
    throw const FormatException(
      'No se pudo abrir el archivo. Elige una imagen JPG, PNG o WebP válida.',
    );
  }
  if (!context.mounted || !navigator.mounted || parent?.isCurrent == false) {
    image.dispose();
    return null;
  }
  final route = DialogRoute<String>(
    context: context,
    themes: themes,
    barrierDismissible: false,
    barrierColor: DialogTheme.of(context).barrierColor ?? Colors.black54,
    builder: (_) => _ImageFrameDialog(image: image, kind: kind),
  );
  // Si se cierra el formulario de origen durante la edición, retira su
  // encuadre también. Solo se retira la ruta del editor, nunca la del login.
  parent?.completed.then((_) {
    if (navigator.mounted && route.isActive) navigator.removeRoute(route);
  });
  return navigator.push(route);
}

enum _ImageFrame { square, wide, original }

class _ImageFrameDialog extends StatefulWidget {
  const _ImageFrameDialog({required this.image, required this.kind});
  final ui.Image image;
  final LocalImageKind kind;

  @override
  State<_ImageFrameDialog> createState() => _ImageFrameDialogState();
}

class _ImageFrameDialogState extends State<_ImageFrameDialog> {
  late _ImageFrame _frame = _defaultFrame;
  late bool _fill = _defaultFill;
  int _turns = 0;
  double _zoom = 1;
  Offset _position = Offset.zero;
  bool _exporting = false;
  String? _error;

  _ImageFrame get _defaultFrame => widget.kind == LocalImageKind.promotion
      ? _ImageFrame.wide
      : _ImageFrame.square;
  bool get _defaultFill => widget.kind != LocalImageKind.product;

  double get _originalRatio => _turns.isOdd
      ? widget.image.height / widget.image.width
      : widget.image.width / widget.image.height;

  double get _ratio => switch (_frame) {
    _ImageFrame.square => 1,
    _ImageFrame.wide => 16 / 9,
    _ImageFrame.original => _originalRatio,
  };

  Size get _outputSize {
    final side = widget.kind.maxSide.toDouble();
    return _ratio >= 1
        ? Size(side, (side / _ratio).roundToDouble())
        : Size((side * _ratio).roundToDouble(), side);
  }

  _FramePainter get _painter => _FramePainter(
    image: widget.image,
    turns: _turns,
    zoom: _zoom,
    position: _position,
    fill: _fill,
  );

  @override
  void dispose() {
    widget.image.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
    _frame = _defaultFrame;
    _fill = _defaultFill;
    _turns = 0;
    _zoom = 1;
    _position = Offset.zero;
    _error = null;
  });

  Future<void> _confirm() async {
    if (_exporting) return;
    setState(() {
      _exporting = true;
      _error = null;
    });
    ui.Picture? picture;
    ui.Image? output;
    try {
      final size = _outputSize;
      final recorder = ui.PictureRecorder();
      _painter.paint(Canvas(recorder), size);
      picture = recorder.endRecording();
      output = await picture.toImage(size.width.toInt(), size.height.toInt());
      final png = await output.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) {
        throw const FormatException('No se pudo generar la imagen.');
      }
      final photo = await compressFramedImage(
        png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
        widget.kind,
      );
      if (mounted) Navigator.pop(context, photo);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo preparar la imagen. Reintenta o selecciona otra.',
        );
      }
    } finally {
      output?.dispose();
      picture?.dispose();
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _preview() => LayoutBuilder(
    builder: (context, box) {
      final ratio = _outputSize.aspectRatio;
      final width = math.min(math.max(1.0, box.maxWidth - 2), 270 * ratio);
      final size = Size(width, width / ratio);
      final painter = _painter;
      final preview = GestureDetector(
        key: const Key('image-frame-preview'),
        onPanUpdate: _exporting
            ? null
            : (event) {
                final range = painter.movement(size);
                setState(
                  () => _position = Offset(
                    range.dx == 0
                        ? 0
                        : (_position.dx + event.delta.dx / range.dx).clamp(
                            -1.0,
                            1.0,
                          ),
                    range.dy == 0
                        ? 0
                        : (_position.dy + event.delta.dy / range.dy).clamp(
                            -1.0,
                            1.0,
                          ),
                  ),
                );
              },
        child: CustomPaint(painter: painter, size: size),
      );
      return Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: context.palette.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: widget.kind == LocalImageKind.avatar
                ? ClipOval(child: preview)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: preview,
                  ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_exporting,
    child: FormDialog(
      title: 'Ajustar fotografía',
      description:
          'Mueve la imagen dentro del encuadre y confirma la vista previa.',
      canClose: !_exporting,
      maxWidth: 620,
      actions: [
        TextButton(
          onPressed: _exporting ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          key: const Key('image-frame-confirm'),
          onPressed: _exporting ? null : _confirm,
          icon: const Icon(Icons.check, size: 18),
          label: Text(_exporting ? 'Preparando…' : 'Usar este encuadre'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _preview(),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.kind != LocalImageKind.avatar)
                for (final (frame, label) in [
                  (_ImageFrame.square, 'Cuadrada'),
                  if (widget.kind == LocalImageKind.promotion)
                    (_ImageFrame.wide, 'Horizontal'),
                  if (_originalRatio >= .25 && _originalRatio <= 4)
                    (_ImageFrame.original, 'Original'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _frame == frame,
                    onSelected: _exporting
                        ? null
                        : (_) => setState(() {
                            _frame = frame;
                            _position = Offset.zero;
                          }),
                  ),
              FilterChip(
                label: const Text('Rellenar encuadre'),
                selected: _fill,
                onSelected: _exporting
                    ? null
                    : (fill) => setState(() {
                        _fill = fill;
                        _position = Offset.zero;
                      }),
              ),
              IconButton.outlined(
                key: const Key('image-frame-rotate'),
                tooltip: 'Girar 90°',
                onPressed: _exporting
                    ? null
                    : () => setState(() {
                        _turns = (_turns + 1) % 4;
                        _position = Offset.zero;
                      }),
                icon: const Icon(Icons.rotate_right, size: 19),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.zoom_out, size: 18),
              Expanded(
                child: Slider(
                  value: _zoom,
                  min: 1,
                  max: 4,
                  label: '${_zoom.toStringAsFixed(1)}×',
                  semanticFormatterCallback: (value) =>
                      'Zoom ${value.toStringAsFixed(1)} veces',
                  onChanged: _exporting
                      ? null
                      : (zoom) => setState(() => _zoom = zoom),
                ),
              ),
              const Icon(Icons.zoom_in, size: 18),
            ],
          ),
          Align(
            child: TextButton(
              onPressed: _exporting ? null : _reset,
              child: const Text('Restablecer encuadre'),
            ),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
  );
}

/// Una sola transformación para previsualización y exportación, como en UniRed.
class _FramePainter extends CustomPainter {
  const _FramePainter({
    required this.image,
    required this.turns,
    required this.zoom,
    required this.position,
    required this.fill,
  });

  final ui.Image image;
  final int turns;
  final double zoom;
  final Offset position;
  final bool fill;

  Size get _rotatedSize => turns.isOdd
      ? Size(image.height.toDouble(), image.width.toDouble())
      : Size(image.width.toDouble(), image.height.toDouble());

  double _scale(Size size) {
    final horizontal = size.width / _rotatedSize.width;
    final vertical = size.height / _rotatedSize.height;
    return (fill
            ? math.max(horizontal, vertical)
            : math.min(horizontal, vertical)) *
        zoom;
  }

  Offset movement(Size size) {
    final scale = _scale(size);
    return Offset(
      math.max(0, (_rotatedSize.width * scale - size.width) / 2),
      math.max(0, (_rotatedSize.height * scale - size.height) / 2),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final range = movement(size);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawColor(Colors.white, BlendMode.src);
    canvas.translate(
      size.width / 2 + range.dx * position.dx,
      size.height / 2 + range.dy * position.dy,
    );
    canvas.rotate(turns * math.pi / 2);
    canvas.scale(_scale(size));
    canvas.drawImage(
      image,
      Offset(-image.width / 2, -image.height / 2),
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) =>
      image != oldDelegate.image ||
      turns != oldDelegate.turns ||
      zoom != oldDelegate.zoom ||
      position != oldDelegate.position ||
      fill != oldDelegate.fill;
}
