import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/tactile_tokens.dart';

/// Gives its child a short scale (and optional rotate) kick whenever
/// [trigger] changes.
class Bump extends StatefulWidget {
  final Object? trigger;
  final double scale;
  final double rotate;
  final Alignment alignment;
  final Duration delay;
  final bool animateOnAppear;
  final Widget child;

  const Bump({
    super.key,
    required this.trigger,
    required this.child,
    this.scale = 1.25,
    this.rotate = 0,
    this.alignment = Alignment.center,
    this.delay = Duration.zero,
    this.animateOnAppear = false,
  });

  @override
  State<Bump> createState() => _BumpState();
}

class _BumpState extends State<Bump> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: TactileDurations.bump + widget.delay,
    value: 1,
  );
  bool _appeared = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_appeared) {
      _appeared = true;
      if (widget.animateOnAppear) _kick();
    }
  }

  @override
  void didUpdateWidget(Bump oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) _kick();
  }

  void _kick() {
    if (MediaQuery.of(context).disableAnimations) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _controller.duration!.inMilliseconds;
    final start = widget.delay.inMilliseconds / total;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final v = _controller.value;
        if (v >= 1 || v <= start) return child!;
        final t = (v - start) / (1 - start);
        // Fast up, elastic settle
        final k = t < 0.28
            ? Curves.easeOut.transform(t / 0.28)
            : 1 - Curves.elasticOut.transform((t - 0.28) / 0.72);
        return Transform.rotate(
          angle: widget.rotate * k * sin(t * pi * 2),
          child: Transform.scale(
            scale: 1 + (widget.scale - 1) * k,
            alignment: widget.alignment,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
