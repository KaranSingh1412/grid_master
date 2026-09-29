import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../effects/bump.dart';
import '../effects/count_up_text.dart';
import '../tactile/tactile.dart';

/// Symbol of the Blockpunkte currency: one small tile, like on the board
class BlockPointIcon extends StatelessWidget {
  final TactilePalette palette;
  final double size;
  final bool muted;

  const BlockPointIcon({
    super.key,
    required this.palette,
    this.size = 18,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final tone = muted
        ? palette.raised.muted(palette.surface.face)
        : palette.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: TactilePainter(
          tone: tone,
          radius: size * 0.28,
          depth: TactileDepth(lip: size * 0.18, lipPressed: 0),
        ),
      ),
    );
  }
}

/// Blockpunkte balance pill, used in the shop and on the lootbox card
class BlockPointBalance extends StatelessWidget {
  final TactilePalette palette;
  final int value;

  const BlockPointBalance({
    super.key,
    required this.palette,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Bump(
      trigger: value,
      scale: 1.18,
      rotate: 0.05,
      child: TactileSurface(
        tone: palette.surface,
        radius: TactileRadii.pill,
        depth: TactileDepth.small,
        padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlockPointIcon(palette: palette, size: 18),
            const SizedBox(width: 6),
            CountUpText(
              value: value,
              format: formatBlockPoints,
              style: TactileText(palette).number(
                18,
                color: palette.primary.face,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 950 -> "950", 12500 -> "12.5k", 250000 -> "250k"
String formatBlockPoints(int value) {
  if (value < 10000) return value.toString();
  final k = value / 1000;
  return '${k.toStringAsFixed(k >= 100 || value % 1000 == 0 ? 0 : 1)}k';
}
