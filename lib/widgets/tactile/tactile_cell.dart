import 'package:flutter/material.dart';
import '../../theme/tactile_tokens.dart';
import 'tactile_surface.dart';

/// One grid tile. Pure paint, no blur, so 25 of them stay cheap.
class TactileCell extends StatelessWidget {
  final TactileTone tone;
  final double radius;
  final double press;
  final bool filled;
  final Color? ringColor;
  final double ringWidth;
  final Color? haloColor;

  const TactileCell({
    super.key,
    required this.tone,
    required this.radius,
    this.press = 0,
    this.filled = true,
    this.ringColor,
    this.ringWidth = 0,
    this.haloColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TactilePainter(
        tone: tone,
        radius: radius,
        // Empty wells sit lower than colored tiles
        depth: filled ? TactileDepth.regular : TactileDepth.small,
        press: press,
        sheen: filled,
        ringColor: ringColor,
        ringWidth: ringWidth,
        haloColor: haloColor,
      ),
      child: const SizedBox.expand(),
    );
  }
}
