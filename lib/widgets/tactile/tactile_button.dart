import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/tactile_tokens.dart';
import 'tactile_surface.dart';

/// Pressable key. The face sinks onto its lip while the finger is down and
/// springs back on release; [onTap] fires on release like a real key.
class TactileButton extends StatefulWidget {
  final TactileTone tone;
  final VoidCallback? onTap;
  final Widget child;
  final double radius;
  final TactileDepth depth;
  final EdgeInsetsGeometry padding;
  final bool expand;
  final bool softShadow;
  final bool haptic;
  final double? width;
  final double? height;

  /// Tone used while [onTap] is null
  final TactileTone? disabledTone;

  const TactileButton({
    super.key,
    required this.tone,
    required this.onTap,
    required this.child,
    this.radius = TactileRadii.md,
    this.depth = TactileDepth.regular,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.expand = false,
    this.softShadow = false,
    this.haptic = true,
    this.width,
    this.height,
    this.disabledTone,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: TactileDurations.press,
    reverseDuration: TactileDurations.release,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _press,
    curve: TactileCurves.press,
    reverseCurve: Curves.easeInBack,
  );

  bool get _enabled => widget.onTap != null;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    if (widget.haptic) HapticFeedback.selectionClick();
    _press.forward();
  }

  void _up(TapUpDetails _) {
    _press.reverse();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final tone = _enabled ? widget.tone : (widget.disabledTone ?? widget.tone);
    final ink = tone.ink;

    Widget content = DefaultTextStyle.merge(
      style: TextStyle(color: ink, fontWeight: FontWeight.w600),
      child: IconTheme.merge(
        data: IconThemeData(color: ink),
        child: widget.child,
      ),
    );
    if (widget.expand || widget.width != null || widget.height != null) {
      content = Center(child: content);
    }

    return Semantics(
      button: true,
      enabled: _enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? _down : null,
        onTapUp: _enabled ? _up : null,
        onTapCancel: _enabled ? () => _press.reverse() : null,
        child: SizedBox(
          width: widget.expand ? double.infinity : widget.width,
          height: widget.height,
          child: AnimatedBuilder(
            animation: _curve,
            builder: (context, child) => TactileSurface(
              tone: tone,
              radius: widget.radius,
              depth: widget.depth,
              press: _curve.value.clamp(0.0, 1.0),
              softShadow: widget.softShadow && _enabled,
              padding: widget.padding,
              child: child,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Round or square icon key
class TactileIconButton extends StatelessWidget {
  final IconData icon;
  final TactileTone tone;
  final VoidCallback? onTap;
  final double size;
  final double? radius;
  final Color? iconColor;
  final TactileTone? disabledTone;

  const TactileIconButton({
    super.key,
    required this.icon,
    required this.tone,
    required this.onTap,
    this.size = 48,
    this.radius,
    this.iconColor,
    this.disabledTone,
  });

  @override
  Widget build(BuildContext context) {
    return TactileButton(
      tone: tone,
      disabledTone: disabledTone,
      onTap: onTap,
      width: size,
      height: size,
      radius: radius ?? size * 0.34,
      depth: TactileDepth.small,
      padding: EdgeInsets.zero,
      child: Icon(icon, size: size * 0.5, color: iconColor),
    );
  }
}
