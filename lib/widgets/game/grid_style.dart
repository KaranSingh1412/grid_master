import 'package:flutter/material.dart';
import '../../theme/tactile_palette.dart';

/// Visual recipe of an equipped grid style. The default is already tactile;
/// every purchasable style adds something on top of it.
class GridStyleSpec {
  final double trayRadius;
  final double cellRadius;
  final Color? trayBorder;
  final double trayBorderWidth;
  final List<BoxShadow>? trayGlow;

  /// Outline on colored tiles
  final Color? cellRing;
  final double cellRingWidth;

  /// Blur-free halo behind colored tiles, tinted with the tile color
  final double cellHaloAlpha;

  const GridStyleSpec({
    required this.trayRadius,
    required this.cellRadius,
    this.trayBorder,
    this.trayBorderWidth = 0,
    this.trayGlow,
    this.cellRing,
    this.cellRingWidth = 0,
    this.cellHaloAlpha = 0,
  });

  factory GridStyleSpec.of(String gridStyleId, TactilePalette p) {
    switch (gridStyleId) {
      case 'rounded_grid':
        return GridStyleSpec(
          trayRadius: 34,
          cellRadius: 20,
          trayBorder: p.surface.face,
          trayBorderWidth: 3,
        );
      case 'sharp_grid':
        return GridStyleSpec(
          trayRadius: 6,
          cellRadius: 3,
          trayBorder: p.textMuted.withValues(alpha: 0.5),
          trayBorderWidth: 2,
        );
      case 'glow_grid':
        return GridStyleSpec(
          trayRadius: 24,
          cellRadius: 12,
          trayBorder: p.primary.face.withValues(alpha: 0.7),
          trayBorderWidth: 3,
          trayGlow: [
            BoxShadow(
              color: p.primary.face.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
          cellHaloAlpha: 0.32,
        );
      case 'neon_border_grid':
        return GridStyleSpec(
          trayRadius: 14,
          cellRadius: 6,
          trayBorder: p.accent,
          trayBorderWidth: 3,
          trayGlow: [
            BoxShadow(
              color: p.accent.withValues(alpha: 0.55),
              blurRadius: 16,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: p.accent.withValues(alpha: 0.22),
              blurRadius: 34,
              spreadRadius: 4,
            ),
          ],
          cellRing: p.accent,
          cellRingWidth: 2,
          cellHaloAlpha: 0.18,
        );
      default:
        return const GridStyleSpec(trayRadius: 22, cellRadius: 12);
    }
  }
}
