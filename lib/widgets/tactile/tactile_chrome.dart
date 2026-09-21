import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/tactile_palette.dart';
import '../../theme/tactile_tokens.dart';
import 'tactile_button.dart';
import 'tactile_surface.dart';

/// Page header for pushed screens: back key, title, optional trailing piece
class TactileTopBar extends StatelessWidget {
  final TactilePalette palette;
  final String title;
  final String backLabel;
  final VoidCallback onBack;
  final Widget? trailing;

  const TactileTopBar({
    super.key,
    required this.palette,
    required this.title,
    required this.backLabel,
    required this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          TactileIconButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: backLabel,
            tone: palette.raised,
            iconColor: palette.textPrimary,
            size: 48,
            onTap: onBack,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(title, style: TactileText(palette).heading),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

/// Tabs as a row of keys. The chosen key stays pushed in.
class TactileTabs extends StatelessWidget {
  final TactilePalette palette;
  final TabController controller;
  final List<String> labels;

  const TactileTabs({
    super.key,
    required this.palette,
    required this.controller,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final text = TactileText(palette);

    return AnimatedBuilder(
      animation: controller.animation!,
      builder: (context, _) {
        final current = controller.animation!.value.round();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Row(
            children: [
              for (int i = 0; i < labels.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                i == current
                    ? Semantics(
                        selected: true,
                        button: true,
                        child: TactileSurface(
                          tone: palette.primary,
                          radius: TactileRadii.sm,
                          depth: TactileDepth.small,
                          press: 1,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Text(
                            labels[i],
                            style: text.button.copyWith(
                              fontSize: 15,
                              color: palette.primary.ink,
                            ),
                          ),
                        ),
                      )
                    : TactileButton(
                        tone: palette.raised,
                        radius: TactileRadii.sm,
                        depth: TactileDepth.small,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        onTap: () => controller.animateTo(i),
                        child: Text(
                          labels[i],
                          style: text.button.copyWith(fontSize: 15),
                        ),
                      ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Slider thumb built like every other key: a round face on a darker lip
class TactileSliderThumbShape extends SliderComponentShape {
  final TactileTone tone;
  final double radius;

  const TactileSliderThumbShape({required this.tone, this.radius = 14});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(radius + 2);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    // Dragging pushes the face down onto its lip
    final press = activationAnimation.value;
    const lip = 4.0;
    final travel = (lip - 1.5) * press;

    canvas.drawCircle(
      center.translate(0, lip),
      radius,
      Paint()..color = tone.lip,
    );
    final faceCenter = center.translate(0, travel);
    canvas.drawCircle(
      faceCenter,
      radius,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(tone.face, Colors.white, 0.35)!, tone.face],
        ).createShader(Rect.fromCircle(center: faceCenter, radius: radius)),
    );
  }
}
