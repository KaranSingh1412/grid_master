import 'package:flutter/material.dart';
import '../../theme/tactile_tokens.dart';

/// Scrim fades in, the card scales up with a small overshoot
class OverlayEntrance extends StatelessWidget {
  final Color scrim;
  final Widget child;

  const OverlayEntrance({super.key, required this.scrim, required this.child});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion
          ? const Duration(milliseconds: 120)
          : TactileDurations.overlayIn,
      builder: (context, t, child) {
        final fade = Curves.easeOut.transform((t * 1.6).clamp(0.0, 1.0));
        final scale = reduceMotion
            ? 1.0
            : 0.86 + 0.14 * TactileCurves.overlayIn.transform(t);
        return ColoredBox(
          color: scrim.withValues(alpha: scrim.a * fade),
          child: Opacity(
            opacity: fade,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: child,
    );
  }
}
