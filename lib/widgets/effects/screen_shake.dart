import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/tactile_tokens.dart';

/// Short decaying horizontal shake, started through [ScreenShakeState.shake]
class ScreenShake extends StatefulWidget {
  final Widget child;
  final double amplitude;

  const ScreenShake({super.key, required this.child, this.amplitude = 9});

  @override
  State<ScreenShake> createState() => ScreenShakeState();
}

class ScreenShakeState extends State<ScreenShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: TactileDurations.shake,
    value: 1,
  );

  void shake() {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        if (t >= 1) return child!;
        final dx = sin(t * pi * 7) * widget.amplitude * (1 - t);
        final dy = cos(t * pi * 5) * widget.amplitude * 0.3 * (1 - t);
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      child: widget.child,
    );
  }
}
