import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/game_constants.dart';
import '../models/game_models.dart';
import 'tactile_palette.dart';

/// Material theme derived from the tactile palette. Fredoka everywhere.
class AppTheme {
  static ThemeData get darkTheme => fromPalette(TactilePalette.standard);

  /// Get themed version based on cosmetic theme
  static ThemeData getThemedDark(CosmeticThemeType themeType) {
    return fromPalette(
      TactilePalette.fromTheme(
        themeType,
        CosmeticThemeColors.getTheme(themeType),
      ),
    );
  }

  static ThemeData fromPalette(TactilePalette p) {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: p.background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      colorScheme: ColorScheme.dark(
        primary: p.primary.face,
        secondary: p.cta.face,
        surface: p.surface.face,
        error: p.danger.face,
        onPrimary: p.primary.ink,
        onSecondary: p.cta.ink,
        onSurface: p.textPrimary,
        onError: p.danger.ink,
      ),
      textTheme: GoogleFonts.fredokaTextTheme(
        base.textTheme,
      ).apply(bodyColor: p.textPrimary, displayColor: p.textPrimary),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.accent.withValues(alpha: 0.35),
        selectionHandleColor: p.accent,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.primary.face,
        inactiveTrackColor: p.backgroundDeep,
        thumbColor: p.textPrimary,
        overlayColor: p.primary.face.withValues(alpha: 0.18),
        trackHeight: 12,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.raised.face,
        contentTextStyle: GoogleFonts.fredoka(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: p.textPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

/// Text styles on top of the palette. Numbers always use tabular figures so
/// counters do not jitter while they change.
class TactileText {
  final TactilePalette p;

  const TactileText(this.p);

  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  TextStyle get wordmark => GoogleFonts.fredoka(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: p.textPrimary,
    letterSpacing: -1,
    height: 1,
  );

  TextStyle get title => GoogleFonts.fredoka(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: p.textPrimary,
    height: 1.05,
  );

  TextStyle get heading => GoogleFonts.fredoka(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: p.textPrimary,
  );

  TextStyle get body => GoogleFonts.fredoka(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: p.textSecondary,
  );

  TextStyle get label => GoogleFonts.fredoka(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: p.textMuted,
    letterSpacing: 1.2,
  );

  TextStyle get button =>
      GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600);

  TextStyle number(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.fredoka(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w700,
        color: color ?? p.textPrimary,
        fontFeatures: tabular,
        height: 1.05,
      );
}
