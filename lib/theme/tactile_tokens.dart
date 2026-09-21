import 'package:flutter/material.dart';

/// Corner radii
class TactileRadii {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 999;
}

/// Spacing scale
class TactileSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Depth of a tactile piece: the solid lip under the face and how far the
/// face travels when pressed.
class TactileDepth {
  final double lip;
  final double lipPressed;

  const TactileDepth({required this.lip, required this.lipPressed});

  /// Distance the face moves down on press
  double get travel => lip - lipPressed;

  /// Lip height at a press progress of 0 (rest) to 1 (fully down)
  double lipAt(double press) => lip - travel * press;

  static const regular = TactileDepth(lip: 6, lipPressed: 2);
  static const small = TactileDepth(lip: 4, lipPressed: 1.5);
  static const flat = TactileDepth(lip: 0, lipPressed: 0);
}

/// Animation durations
class TactileDurations {
  static const press = Duration(milliseconds: 90);
  static const release = Duration(milliseconds: 180);
  static const pop = Duration(milliseconds: 380);
  static const stagger = Duration(milliseconds: 70);
  static const particles = Duration(milliseconds: 520);
  static const gridPulse = Duration(milliseconds: 250);
  static const select = Duration(milliseconds: 220);
  static const wiggle = Duration(milliseconds: 320);
  static const shake = Duration(milliseconds: 260);
  static const countUp = Duration(milliseconds: 700);
  static const bump = Duration(milliseconds: 420);
  static const floatUp = Duration(milliseconds: 900);
  static const overlayIn = Duration(milliseconds: 280);

  /// Window between a solved level and the next one
  static const levelUp = Duration(milliseconds: 1200);
}

/// Animation curves
class TactileCurves {
  static const press = Curves.easeOut;
  static const release = Curves.easeOutBack;
  static const settle = Curves.easeOutCubic;
  static const countUp = Curves.easeOutCubic;
  static const particles = Curves.easeOut;
  static const overlayIn = Curves.easeOutBack;

  /// Overshoot pop: 0.6 -> 1.12 -> 0.96 -> 1
  static final Animatable<double> popScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.6,
        end: 1.12,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 45,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.12,
        end: 0.96,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.96,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 25,
    ),
  ]);

  /// Short hop used by the level-up wave: up and back with a small squash
  static final Animatable<double> hop = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.bounceOut)),
      weight: 60,
    ),
  ]);
}

/// Face and lip of one tactile piece
@immutable
class TactileTone {
  final Color face;
  final Color lip;

  const TactileTone(this.face, this.lip);

  /// Lip computed from the face: same hue, a little more saturation,
  /// about a quarter darker.
  factory TactileTone.from(Color face) => TactileTone(face, lipOf(face));

  static Color lipOf(Color face) {
    final hsv = HSVColor.fromColor(face);
    return hsv
        .withSaturation((hsv.saturation * 1.08).clamp(0.0, 1.0))
        .withValue((hsv.value * 0.76).clamp(0.0, 1.0))
        .toColor();
  }

  /// Muted version for disabled pieces
  TactileTone muted(Color ground) => TactileTone(
    Color.lerp(face, ground, 0.62)!,
    Color.lerp(lip, ground, 0.62)!,
  );

  /// Readable ink on the face
  Color get ink => face.computeLuminance() > 0.42
      ? Color.lerp(lip, Colors.black, 0.62)!
      : Colors.white;

  @override
  bool operator ==(Object other) =>
      other is TactileTone && other.face == face && other.lip == lip;

  @override
  int get hashCode => Object.hash(face, lip);
}

/// Default theme colors (face / lip)
class TactileColors {
  static const Color background = Color(0xFF1B1F3B);
  static const Color backgroundDeep = Color(0xFF14172E);

  static const TactileTone well = TactileTone(
    Color(0xFF2A2F57),
    Color(0xFF1D2142),
  );

  static const TactileTone red = TactileTone(
    Color(0xFFFF6B5E),
    Color(0xFFC4463B),
  );
  static const TactileTone blue = TactileTone(
    Color(0xFF3BA3F5),
    Color(0xFF2372B5),
  );
  static const TactileTone green = TactileTone(
    Color(0xFF2CCB8C),
    Color(0xFF1C9063),
  );
  static const TactileTone yellow = TactileTone(
    Color(0xFFFFC83D),
    Color(0xFFC9901A),
  );
  static const TactileTone purple = TactileTone(
    Color(0xFF9D7BFF),
    Color(0xFF6B4FC9),
  );
  static const TactileTone orange = TactileTone(
    Color(0xFFFF9447),
    Color(0xFFC46522),
  );
  static const TactileTone pink = TactileTone(
    Color(0xFFFF72B6),
    Color(0xFFC4468A),
  );

  static const TactileTone cta = yellow;

  static const Color textPrimary = Color(0xFFF4F5FF);
  static const Color textSecondary = Color(0xFFA3A9D6);
  static const Color accent = Color(0xFF5FE0B0);
}
