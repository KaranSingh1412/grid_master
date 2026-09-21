import 'package:flutter/material.dart';
import '../../theme/tactile_tokens.dart';

/// Paints one tactile piece: a solid lip with the face sitting on top of it.
/// [press] moves the face down and shrinks the lip; the outer size never
/// changes, so nothing around it shifts.
class TactilePainter extends CustomPainter {
  final TactileTone tone;
  final double radius;
  final TactileDepth depth;
  final double press;
  final bool softShadow;
  final bool sheen;
  final Color? ringColor;
  final double ringWidth;

  /// Blur-free glow: two stacked translucent outlines behind the piece
  final Color? haloColor;

  const TactilePainter({
    required this.tone,
    required this.radius,
    this.depth = TactileDepth.regular,
    this.press = 0,
    this.softShadow = false,
    this.sheen = true,
    this.ringColor,
    this.ringWidth = 0,
    this.haloColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final travel = depth.travel * press;
    final lip = depth.lipAt(press);
    final r = Radius.circular(radius);

    final body = RRect.fromLTRBR(0, travel, size.width, size.height, r);
    final face = RRect.fromLTRBR(0, travel, size.width, size.height - lip, r);

    if (softShadow) {
      final shadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.28 * (1 - press * 0.5))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawRRect(body.shift(Offset(0, 6 - travel)), shadow);
    }

    if (haloColor != null) {
      canvas.drawRRect(
        body.inflate(5),
        Paint()..color = haloColor!.withValues(alpha: haloColor!.a * 0.35),
      );
      canvas.drawRRect(body.inflate(2.5), Paint()..color = haloColor!);
    }

    if (lip > 0) {
      canvas.drawRRect(body, Paint()..color = tone.lip);
    }

    final facePaint = Paint();
    if (sheen) {
      facePaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(tone.face, Colors.white, 0.10)!,
          tone.face,
          Color.lerp(tone.face, tone.lip, 0.18)!,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(face.outerRect);
    } else {
      facePaint.color = tone.face;
    }
    canvas.drawRRect(face, facePaint);

    if (sheen && size.height - lip > 14) {
      // Top-lit edge: a thin bright line that follows the upper corners
      final edge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [
            Colors.white.withValues(alpha: 0.30),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(face.outerRect);
      canvas.drawRRect(face.deflate(0.75), edge);
    }

    if (ringColor != null && ringWidth > 0) {
      canvas.drawRRect(
        face.deflate(ringWidth / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ringWidth
          ..color = ringColor!,
      );
    }
  }

  @override
  bool shouldRepaint(TactilePainter old) =>
      old.tone != tone ||
      old.radius != radius ||
      old.press != press ||
      old.depth.lip != depth.lip ||
      old.depth.lipPressed != depth.lipPressed ||
      old.softShadow != softShadow ||
      old.sheen != sheen ||
      old.ringColor != ringColor ||
      old.ringWidth != ringWidth ||
      old.haloColor != haloColor;
}

/// Static tactile panel or, with [press], the body of a key.
class TactileSurface extends StatelessWidget {
  final TactileTone tone;
  final double radius;
  final TactileDepth depth;
  final double press;
  final bool softShadow;
  final bool sheen;
  final Color? ringColor;
  final double ringWidth;
  final EdgeInsetsGeometry padding;
  final Widget? child;

  const TactileSurface({
    super.key,
    required this.tone,
    this.radius = TactileRadii.lg,
    this.depth = TactileDepth.regular,
    this.press = 0,
    this.softShadow = false,
    this.sheen = true,
    this.ringColor,
    this.ringWidth = 0,
    this.padding = EdgeInsets.zero,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final travel = depth.travel * press;
    return CustomPaint(
      painter: TactilePainter(
        tone: tone,
        radius: radius,
        depth: depth,
        press: press,
        softShadow: softShadow,
        sheen: sheen,
        ringColor: ringColor,
        ringWidth: ringWidth,
      ),
      child: Padding(
        // Content rides on the face
        padding: EdgeInsets.only(top: travel, bottom: depth.lipAt(press)),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Sunken area (board tray, timer track): darker ground with an inner top
/// shadow instead of a lip.
class TactileWell extends StatelessWidget {
  final Color color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? glow;
  final Widget? child;

  const TactileWell({
    super.key,
    required this.color,
    this.radius = TactileRadii.lg,
    this.padding = EdgeInsets.zero,
    this.borderColor,
    this.borderWidth = 0,
    this.glow,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: glow,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: borderColor != null && borderWidth > 0
              ? Border.all(color: borderColor!, width: borderWidth)
              : null,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(color, Colors.black, 0.35)!,
              color,
              Color.lerp(color, Colors.white, 0.04)!,
            ],
            stops: const [0.0, 0.12, 1.0],
          ),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
