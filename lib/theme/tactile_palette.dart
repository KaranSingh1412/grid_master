import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../models/game_models.dart';
import 'tactile_tokens.dart';

/// Every color a screen needs, resolved for the equipped cosmetic theme.
/// Lips are computed from the faces so purchased themes get the same depth.
@immutable
class TactilePalette {
  final Color background;

  /// Sunken ground: board tray, track of the timer bar, banner fence
  final Color backgroundDeep;

  /// Panels, cards, neutral keys
  final TactileTone surface;

  /// Raised neutral key on top of a panel
  final TactileTone raised;

  /// Empty grid cell
  final TactileTone well;

  final TactileTone primary;
  final TactileTone secondary;
  final TactileTone cta;
  final TactileTone danger;
  final TactileTone hint;

  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color scrim;

  /// Tones for ColorType.red .. ColorType.pink, in enum order
  final List<TactileTone> gameTones;

  const TactilePalette({
    required this.background,
    required this.backgroundDeep,
    required this.surface,
    required this.raised,
    required this.well,
    required this.primary,
    required this.secondary,
    required this.cta,
    required this.danger,
    required this.hint,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.scrim,
    required this.gameTones,
  });

  static const List<TactileTone> _defaultGameTones = [
    TactileColors.red,
    TactileColors.blue,
    TactileColors.green,
    TactileColors.yellow,
    TactileColors.purple,
    TactileColors.orange,
    TactileColors.pink,
  ];

  static const TactilePalette standard = TactilePalette(
    background: TactileColors.background,
    backgroundDeep: TactileColors.backgroundDeep,
    surface: TactileColors.well,
    raised: TactileTone(Color(0xFF3A4074), Color(0xFF272C57)),
    well: TactileColors.well,
    primary: TactileColors.green,
    secondary: TactileColors.blue,
    cta: TactileColors.cta,
    danger: TactileColors.red,
    hint: TactileColors.purple,
    accent: TactileColors.accent,
    textPrimary: TactileColors.textPrimary,
    textSecondary: TactileColors.textSecondary,
    textMuted: Color(0xFF969DCB),
    scrim: Color(0xE60E1024),
    gameTones: _defaultGameTones,
  );

  factory TactilePalette.fromTheme(
    CosmeticThemeType type,
    CosmeticThemeColors c,
  ) {
    if (type == CosmeticThemeType.defaultTheme) return standard;

    final gameTones = <TactileTone>[
      for (int i = 0; i < _defaultGameTones.length; i++)
        i < c.gameColors.length
            ? TactileTone.from(c.gameColors[i])
            : _defaultGameTones[i],
    ];

    return TactilePalette(
      background: c.background,
      backgroundDeep: Color.lerp(c.background, Colors.black, 0.32)!,
      surface: TactileTone.from(c.surface),
      raised: TactileTone.from(Color.lerp(c.surface, c.textPrimary, 0.12)!),
      well: TactileTone.from(c.surface),
      primary: TactileTone.from(c.primary),
      secondary: TactileTone.from(c.secondary),
      cta: TactileColors.cta,
      danger: TactileColors.red,
      hint: TactileTone.from(c.secondary),
      accent: c.accent,
      textPrimary: c.textPrimary,
      textSecondary: c.textSecondary,
      textMuted: Color.lerp(c.textSecondary, c.background, 0.3)!,
      scrim: Color.lerp(
        c.background,
        Colors.black,
        0.45,
      )!.withValues(alpha: 0.9),
      gameTones: gameTones,
    );
  }

  /// Tone of a pattern color; ColorType.none is the empty well
  TactileTone toneOf(ColorType type) {
    if (type == ColorType.none) return well;
    return gameTones[type.index];
  }
}
