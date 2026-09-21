import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../tactile/tactile.dart';

/// Small stat tile shared by the pause and game-over overlays
class OverlayStat extends StatelessWidget {
  final TactilePalette palette;
  final String label;
  final String value;
  final Color? valueColor;

  const OverlayStat({
    super.key,
    required this.palette,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final text = TactileText(palette);
    return TactileWell(
      color: palette.backgroundDeep,
      radius: TactileRadii.md,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: text.label.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: text.number(24, color: valueColor)),
          ),
        ],
      ),
    );
  }
}

/// Full-width key used inside overlays
class OverlayButton extends StatelessWidget {
  final TactilePalette palette;
  final String label;
  final TactileTone tone;
  final VoidCallback onTap;
  final bool large;
  final IconData? icon;

  const OverlayButton({
    super.key,
    required this.palette,
    required this.label,
    required this.tone,
    required this.onTap,
    this.large = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final text = TactileText(palette);
    return TactileButton(
      tone: tone,
      onTap: onTap,
      expand: true,
      softShadow: large,
      padding: EdgeInsets.symmetric(vertical: large ? 14 : 11, horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: large ? 26 : 22),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              style: text.button.copyWith(fontSize: large ? 20 : 16),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
