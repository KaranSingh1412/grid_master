import 'package:flutter/material.dart';
import '../../theme/tactile_tokens.dart';

/// Number that counts from its previous value to the new one
class CountUpText extends StatefulWidget {
  final int value;
  final TextStyle style;
  final String Function(int value)? format;
  final Duration duration;

  const CountUpText({
    super.key,
    required this.value,
    required this.style,
    this.format,
    this.duration = TactileDurations.countUp,
  });

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );
  late int _from = widget.value;

  int get _shown {
    final t = TactileCurves.countUp.transform(_controller.value);
    return (_from + (widget.value - _from) * t).round();
  }

  @override
  void didUpdateWidget(CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    // Counting only ever runs upwards; resets snap
    final climbs = widget.value > oldWidget.value;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (climbs && !reduceMotion) {
      _from = oldWidget.value;
      _controller.forward(from: 0);
    } else {
      _from = widget.value;
      _controller.value = 1;
    }
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
      builder: (context, _) {
        final v = _shown;
        return Text(widget.format?.call(v) ?? '$v', style: widget.style);
      },
    );
  }
}
