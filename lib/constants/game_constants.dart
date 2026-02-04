import 'package:flutter/material.dart';
import '../models/game_models.dart';

/// Color mappings matching the React implementation's Tailwind classes
class GameColors {
  // Primary game colors
  static const Color red = Color(0xFFF43F5E); // rose-500
  static const Color blue = Color(0xFF0EA5E9); // sky-500
  static const Color green = Color(0xFF10B981); // emerald-500
  static const Color yellow = Color(0xFFFBBF24); // amber-400
  static const Color purple = Color(0xFF8B5CF6); // violet-500
  static const Color orange = Color(0xFFF97316); // orange-500
  static const Color pink = Color(0xFFD946EF); // fuchsia-500
  static const Color none = Color(0xFFE2E8F0); // slate-200

  // UI colors matching slate palette
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // Accent colors
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald800 = Color(0xFF065F46);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber700 = Color(0xFFB45309);
  static const Color rose400 = Color(0xFFFB7185);
  static const Color rose500 = Color(0xFFF43F5E);
  static const Color indigo500 = Color(0xFF6366F1);
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color orange500 = Color(0xFFF97316);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue900 = Color(0xFF1E3A8A);
  static const Color violet500 = Color(0xFF8B5CF6);
  static const Color violet700 = Color(0xFF6D28D9);

  /// Get color for a ColorType
  static Color getColor(ColorType type) {
    switch (type) {
      case ColorType.red:
        return red;
      case ColorType.blue:
        return blue;
      case ColorType.green:
        return green;
      case ColorType.yellow:
        return yellow;
      case ColorType.purple:
        return purple;
      case ColorType.orange:
        return orange;
      case ColorType.pink:
        return pink;
      case ColorType.none:
        return slate600;
    }
  }
}

/// Cosmetic theme color palettes
class CosmeticThemeColors {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final List<Color> gameColors; // Override for game cell colors

  const CosmeticThemeColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    this.gameColors = const [],
  });

  static const defaultTheme = CosmeticThemeColors(
    primary: GameColors.emerald500,
    secondary: GameColors.amber400,
    background: GameColors.slate900,
    surface: GameColors.slate800,
    accent: GameColors.emerald400,
    textPrimary: GameColors.slate50,
    textSecondary: GameColors.slate400,
  );

  static const zenCalm = CosmeticThemeColors(
    primary: Color(0xFF7DD3C0), // Soft teal
    secondary: Color(0xFFB8D4E3), // Pale blue
    background: Color(0xFF1A2F38), // Deep ocean
    surface: Color(0xFF243B48), // Muted ocean surface
    accent: Color(0xFF9FD5D1), // Light aqua
    textPrimary: Color(0xFFE8F4F8),
    textSecondary: Color(0xFF8BA9B5),
    gameColors: [
      Color(0xFFE57373), // Soft coral red
      Color(0xFF64B5F6), // Sky blue
      Color(0xFF81C784), // Sage green
      Color(0xFFFFD54F), // Warm yellow
      Color(0xFFBA68C8), // Soft purple
      Color(0xFFFFB74D), // Soft orange
      Color(0xFF4DD0E1), // Turquoise
    ],
  );

  static const neonGlow = CosmeticThemeColors(
    primary: Color(0xFF00FFFF), // Cyan
    secondary: Color(0xFFFF00FF), // Magenta
    background: Color(0xFF0D0221), // Deep purple-black
    surface: Color(0xFF1A0A2E), // Dark purple
    accent: Color(0xFF00FF88), // Neon green
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB388FF),
    gameColors: [
      Color(0xFFFF0080), // Hot pink
      Color(0xFF00FFFF), // Cyan
      Color(0xFF00FF88), // Neon green
      Color(0xFFFFFF00), // Yellow
      Color(0xFFFF00FF), // Magenta
      Color(0xFFFF6B00), // Orange
      Color(0xFF8B00FF), // Purple
    ],
  );

  static const midnight = CosmeticThemeColors(
    primary: Color(0xFF6366F1), // Indigo
    secondary: Color(0xFF818CF8), // Light indigo
    background: Color(0xFF030712), // Near black
    surface: Color(0xFF111827), // Dark gray
    accent: Color(0xFFA5B4FC), // Pale indigo
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFF6B7280),
  );

  static const forest = CosmeticThemeColors(
    primary: Color(0xFF22C55E), // Green
    secondary: Color(0xFF84CC16), // Lime
    background: Color(0xFF052E16), // Dark forest
    surface: Color(0xFF14532D), // Forest green
    accent: Color(0xFF4ADE80), // Light green
    textPrimary: Color(0xFFF0FDF4),
    textSecondary: Color(0xFF86EFAC),
    gameColors: [
      Color(0xFFDC2626), // Red berries
      Color(0xFF2563EB), // Blue sky
      Color(0xFF22C55E), // Green leaves
      Color(0xFFFACC15), // Yellow sun
      Color(0xFF7C3AED), // Purple flowers
      Color(0xFFF97316), // Orange autumn
      Color(0xFFEC4899), // Pink blossoms
    ],
  );

  static const sunset = CosmeticThemeColors(
    primary: Color(0xFFF97316), // Orange
    secondary: Color(0xFFFB923C), // Light orange
    background: Color(0xFF1C1917), // Warm black
    surface: Color(0xFF292524), // Warm dark gray
    accent: Color(0xFFFBBF24), // Amber
    textPrimary: Color(0xFFFFFBEB),
    textSecondary: Color(0xFFFED7AA),
    gameColors: [
      Color(0xFFEF4444), // Red
      Color(0xFFF97316), // Orange
      Color(0xFFFBBF24), // Amber
      Color(0xFFEAB308), // Yellow
      Color(0xFFEC4899), // Pink
      Color(0xFF8B5CF6), // Purple
      Color(0xFF14B8A6), // Teal contrast
    ],
  );

  static const ocean = CosmeticThemeColors(
    primary: Color(0xFF0EA5E9), // Sky blue
    secondary: Color(0xFF06B6D4), // Cyan
    background: Color(0xFF0C1929), // Deep ocean
    surface: Color(0xFF0F2942), // Ocean blue
    accent: Color(0xFF38BDF8), // Light blue
    textPrimary: Color(0xFFF0F9FF),
    textSecondary: Color(0xFF7DD3FC),
  );

  static const lavender = CosmeticThemeColors(
    primary: Color(0xFFA855F7), // Purple
    secondary: Color(0xFFC084FC), // Light purple
    background: Color(0xFF1E1B29), // Dark purple
    surface: Color(0xFF2D2640), // Muted purple
    accent: Color(0xFFE879F9), // Fuchsia
    textPrimary: Color(0xFFFAF5FF),
    textSecondary: Color(0xFFD8B4FE),
  );

  static CosmeticThemeColors getTheme(CosmeticThemeType type) {
    switch (type) {
      case CosmeticThemeType.defaultTheme:
        return defaultTheme;
      case CosmeticThemeType.zenCalm:
        return zenCalm;
      case CosmeticThemeType.neonGlow:
        return neonGlow;
      case CosmeticThemeType.midnight:
        return midnight;
      case CosmeticThemeType.forest:
        return forest;
      case CosmeticThemeType.sunset:
        return sunset;
      case CosmeticThemeType.ocean:
        return ocean;
      case CosmeticThemeType.lavender:
        return lavender;
    }
  }
}

/// All available cosmetic items
const List<CosmeticItem> allCosmetics = [
  // Themes - unlockable through Color Zen progression
  CosmeticItem(
    id: 'default_theme',
    nameKey: 'cosmetic_default_theme',
    category: CosmeticCategory.theme,
    themeType: CosmeticThemeType.defaultTheme,
  ),
  CosmeticItem(
    id: 'zen_calm_theme',
    nameKey: 'cosmetic_zen_calm',
    category: CosmeticCategory.theme,
    themeType: CosmeticThemeType.zenCalm,
    cosmeticCost: 50,
  ),
  CosmeticItem(
    id: 'midnight_theme',
    nameKey: 'cosmetic_midnight',
    category: CosmeticCategory.theme,
    themeType: CosmeticThemeType.midnight,
    cosmeticCost: 75,
  ),
  CosmeticItem(
    id: 'forest_theme',
    nameKey: 'cosmetic_forest',
    category: CosmeticCategory.theme,
    themeType: CosmeticThemeType.forest,
    cosmeticCost: 100,
  ),
  CosmeticItem(
    id: 'ocean_theme',
    nameKey: 'cosmetic_ocean',
    category: CosmeticCategory.theme,
    themeType: CosmeticThemeType.ocean,
    cosmeticCost: 125,
  ),
  CosmeticItem(
    id: 'sunset_theme',
    nameKey: 'cosmetic_sunset',
    category: CosmeticCategory.theme,
    themeType: CosmeticThemeType.sunset,
    cosmeticCost: 175,
  ),
  CosmeticItem(
    id: 'lavender_theme',
    nameKey: 'cosmetic_lavender',
    category: CosmeticCategory.theme,
    themeType: CosmeticThemeType.lavender,
    cosmeticCost: 225,
  ),
  CosmeticItem(
    id: 'neon_glow_theme',
    nameKey: 'cosmetic_neon_glow',
    category: CosmeticCategory.theme,
    themeType: CosmeticThemeType.neonGlow,
    cosmeticCost: 300,
  ),

  // Grid styles - purchasable with cosmetic credits
  CosmeticItem(
    id: 'default_grid',
    nameKey: 'cosmetic_default_grid',
    category: CosmeticCategory.gridStyle,
  ),
  CosmeticItem(
    id: 'rounded_grid',
    nameKey: 'cosmetic_rounded_grid',
    category: CosmeticCategory.gridStyle,
    cosmeticCost: 50,
  ),
  CosmeticItem(
    id: 'glow_grid',
    nameKey: 'cosmetic_glow_grid',
    category: CosmeticCategory.gridStyle,
    cosmeticCost: 100,
  ),
  CosmeticItem(
    id: 'neon_border_grid',
    nameKey: 'cosmetic_neon_border',
    category: CosmeticCategory.gridStyle,
    cosmeticCost: 150,
  ),
  CosmeticItem(
    id: 'sharp_grid',
    nameKey: 'cosmetic_sharp_grid',
    category: CosmeticCategory.gridStyle,
    cosmeticCost: 75,
  ),

  // Cell animations
  CosmeticItem(
    id: 'default_animation',
    nameKey: 'cosmetic_default_animation',
    category: CosmeticCategory.cellAnimation,
  ),
  CosmeticItem(
    id: 'pulse_animation',
    nameKey: 'cosmetic_pulse',
    category: CosmeticCategory.cellAnimation,
    cosmeticCost: 75,
  ),
  CosmeticItem(
    id: 'bounce_animation',
    nameKey: 'cosmetic_bounce',
    category: CosmeticCategory.cellAnimation,
    cosmeticCost: 100,
  ),
  CosmeticItem(
    id: 'sparkle_animation',
    nameKey: 'cosmetic_sparkle',
    category: CosmeticCategory.cellAnimation,
    cosmeticCost: 150,
  ),

  // Sound packs
  CosmeticItem(
    id: 'default_sound',
    nameKey: 'cosmetic_default_sound',
    category: CosmeticCategory.soundPack,
  ),
  CosmeticItem(
    id: 'zen_sound',
    nameKey: 'cosmetic_zen_sound',
    category: CosmeticCategory.soundPack,
    cosmeticCost: 80,
  ),
  CosmeticItem(
    id: 'retro_sound',
    nameKey: 'cosmetic_retro_sound',
    category: CosmeticCategory.soundPack,
    cosmeticCost: 100,
  ),
  CosmeticItem(
    id: 'fart_sound',
    nameKey: 'cosmetic_fart_sound',
    category: CosmeticCategory.soundPack,
    cosmeticCost: 120,
  ),
];

/// Available color options for the game
const List<ColorType> colorOptions = [
  ColorType.red,
  ColorType.blue,
  ColorType.green,
  ColorType.yellow,
  ColorType.purple,
  ColorType.orange,
  ColorType.pink,
];

/// Generate all levels with increasing difficulty
List<LevelConfig> generateLevels() {
  final List<LevelConfig> levels = [];
  int currentPatternSize = 4;
  int currentGridSize = 3;

  for (int i = 1; i <= 200; i++) {
    // Determine grid size based on pattern size - Maximum 5x5
    if (currentPatternSize > 16) {
      currentGridSize = 5;
    } else if (currentPatternSize > 9) {
      currentGridSize = 4;
    } else {
      currentGridSize = 3;
    }

    // Determine difficulty label
    String difficulty = 'difficulty_beginner';
    if (currentGridSize == 4) {
      difficulty = 'difficulty_medium';
    } else if (currentGridSize == 5) {
      difficulty = 'difficulty_advanced';
    }

    if (i > 30) {
      difficulty = 'difficulty_pro';
    }
    if (i > 50) {
      difficulty = 'difficulty_legend';
    }

    // Mehr Preview-Zeit: Start bei 5.5s, langsamer abnehmend, Minimum 2.5s
    final previewSeconds = (5.5 - (i * 0.03)).clamp(2.5, 5.5);

    // Pattern-Größe auf 5x5 Grid begrenzen (max 25 Zellen)
    final clampedPatternSize = currentPatternSize.clamp(4, 25);

    levels.add(
      LevelConfig(
        id: i,
        gridSize: currentGridSize,
        // Maximal 5 Farben
        colorCount: (3 + (i / 12).floor()).clamp(3, 5),
        patternSize: clampedPatternSize,
        previewSeconds: double.parse(previewSeconds.toStringAsFixed(1)),
        difficulty: difficulty,
      ),
    );

    // Langsamere Pattern-Steigerung: nur alle 2 Level ab Level 3
    // Stoppt bei 25 (5x5 Grid voll)
    if (i >= 3 && i % 2 == 0 && currentPatternSize < 25) {
      currentPatternSize++;
    }
  }

  return levels;
}

/// Pre-generated levels list
final List<LevelConfig> levels = generateLevels();

/// Get levels for a specific game mode
List<LevelConfig> getLevelsForMode(GameMode mode) {
  return levels;
  // switch (mode) {
  //   case GameMode.classic:
  //     return levels;
  //   default:
  //     return levels;
  // }
}
