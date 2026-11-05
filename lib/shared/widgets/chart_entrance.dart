import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Progreso de entrada compartido por todos los gráficos. Espera a que el área
/// del gráfico sea visible; cambiar filtros reinicia la entrada, un repintado no.
class ChartEntrance extends StatefulWidget {
  const ChartEntrance({
    required this.revision,
    required this.builder,
    super.key,
  });
  final Object revision;
  final Widget Function(BuildContext, double progress) builder;
  static const duration = Duration(milliseconds: 1400);

  /// Avanza de izquierda a derecha, desde cero hasta el valor de cada barra.
  static double factor(double progress, int index, int count) =>
      (progress * count - index).clamp(0.0, 1.0);

  @override
  State<ChartEntrance> createState() => _ChartEntranceState();
}

class _ChartEntranceState extends State<ChartEntrance>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ChartEntrance.duration,
  );
  ScrollPosition? _scroll;
  ScrollableState? _scrollable;
  bool _started = false, _reduced = false, _checkPending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollable = Scrollable.maybeOf(context);
    if (_scroll != scrollable?.position) {
      _scroll?.removeListener(_scheduleCheck);
      _scrollable = scrollable;
      _scroll = scrollable?.position;
      _scroll?.addListener(_scheduleCheck);
    }
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
      _started = true;
      _controller.value = 1;
    }
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(covariant ChartEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision && !_reduced) {
      _started = false;
      _controller.reset();
      _scheduleCheck();
    }
  }

  @override
  void didChangeMetrics() => _scheduleCheck();
  void _scheduleCheck() {
    if (!mounted || _started || _checkPending) return;
    _checkPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPending = false;
      if (!mounted || _started) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final area = box.localToGlobal(Offset.zero) & box.size;
      final viewport = _scrollable?.context.findRenderObject();
      final bounds = viewport is RenderBox && viewport.hasSize
          ? viewport.localToGlobal(Offset.zero) & viewport.size
          : Offset.zero & MediaQuery.sizeOf(context);
      final visible = area.intersect(bounds);
      if (visible.width > 0 &&
          visible.height >= math.min(80, area.height * .25)) {
        _started = true;
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll?.removeListener(_scheduleCheck);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => widget.builder(
        context,
        _reduced ? 1 : Curves.easeInOutCubic.transform(_controller.value),
      ),
    ),
  );
}

/// Revela el gráfico circular desde las doce en sentido horario. Solo recorta
/// la pintura de fl_chart: no altera sus porcentajes ni fabrica secciones.
class ChartSweepClipper extends CustomClipper<Path> {
  const ChartSweepClipper(this.progress);
  final double progress;
  @override
  Path getClip(Size size) {
    if (progress >= 1) return Path()..addRect(Offset.zero & size);
    if (progress <= 0) return Path();
    final center = size.center(Offset.zero);
    final radius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;
    return Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx, center.dy - radius)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
      )
      ..close();
  }

  @override
  bool shouldReclip(ChartSweepClipper oldClipper) =>
      progress != oldClipper.progress;
}
