import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/game_constants.dart';
import '../models/game_models.dart';

/// App theme matching the React implementation's design system
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GameColors.slate900,
      colorScheme: ColorScheme.dark(
        primary: GameColors.emerald500,
        secondary: GameColors.amber400,
        surface: GameColors.slate800,
        error: GameColors.rose500,
        onPrimary: Colors.white,
        onSecondary: GameColors.slate900,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: GameColors.slate900,
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GameColors.slate300,
          side: const BorderSide(color: GameColors.slate700),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  /// Get themed version based on cosmetic theme
  static ThemeData getThemedDark(CosmeticThemeType themeType) {
    final colors = CosmeticThemeColors.getTheme(themeType);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.dark(
        primary: colors.primary,
        secondary: colors.secondary,
        surface: colors.surface,
        error: GameColors.rose500,
        onPrimary: colors.textPrimary,
        onSecondary: colors.background,
        onSurface: colors.textPrimary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: colors.textPrimary, displayColor: colors.textPrimary),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: colors.background,
          backgroundColor: colors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textSecondary,
          side: BorderSide(color: colors.surface),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

/// Dynamic text styles that adapt to cosmetic theme
class ThemedTextStyles {
  final CosmeticThemeColors colors;

  const ThemedTextStyles(this.colors);

  factory ThemedTextStyles.fromThemeType(CosmeticThemeType type) {
    return ThemedTextStyles(CosmeticThemeColors.getTheme(type));
  }

  TextStyle get title => GoogleFonts.outfit(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    color: colors.textPrimary,
    letterSpacing: -2,
  );

  TextStyle get titleAccent => GoogleFonts.outfit(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    color: colors.accent,
    letterSpacing: -2,
  );

  TextStyle get subtitle => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: colors.textSecondary,
    letterSpacing: 3,
  );

  TextStyle get timer => GoogleFonts.outfit(
    fontSize: 30,
    fontWeight: FontWeight.w900,
    color: colors.accent,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  TextStyle get score => GoogleFonts.outfit(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: colors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// Text styles matching the React implementation
class AppTextStyles {
  static TextStyle get title => GoogleFonts.outfit(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: -2,
  );

  static TextStyle get titleAccent => GoogleFonts.outfit(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    color: GameColors.emerald400,
    letterSpacing: -2,
  );

  static TextStyle get subtitle => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: GameColors.slate400,
    letterSpacing: 3,
  );

  static TextStyle get labelSmall => GoogleFonts.outfit(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: GameColors.slate500,
    letterSpacing: 1.5,
  );

  static TextStyle get labelMedium => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: GameColors.slate400,
    letterSpacing: 2,
  );

  static TextStyle get headingLarge => GoogleFonts.outfit(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static TextStyle get headingMedium => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: Colors.white,
  );

  static TextStyle get timer => GoogleFonts.outfit(
    fontSize: 30,
    fontWeight: FontWeight.w900,
    color: GameColors.emerald400,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle get timerWarning => GoogleFonts.outfit(
    fontSize: 30,
    fontWeight: FontWeight.w900,
    color: GameColors.rose500,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle get score => GoogleFonts.outfit(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle get buttonPrimary => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: GameColors.slate900,
  );

  static TextStyle get buttonSecondary => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: GameColors.slate300,
    letterSpacing: 1.5,
  );

  static TextStyle get body => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: GameColors.slate500,
  );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: GameColors.slate400,
  );
}
