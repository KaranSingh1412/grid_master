import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../models/game_models.dart';
import '../theme/tactile_palette.dart';
import '../theme/tactile_tokens.dart';

/// Zentraler Provider für das Theme-Management
/// Verwaltet das aktuelle Theme und stellt Farben für alle Widgets bereit
class ThemeProvider extends ChangeNotifier {
  CosmeticThemeType _currentThemeType = CosmeticThemeType.defaultTheme;
  CosmeticThemeColors _currentThemeColors = CosmeticThemeColors.defaultTheme;
  TactilePalette _palette = TactilePalette.standard;

  /// Das aktuelle Theme-Typ
  CosmeticThemeType get currentThemeType => _currentThemeType;

  /// Die aktuellen Theme-Farben
  CosmeticThemeColors get colors => _currentThemeColors;

  /// Tactile-Tokens (Flächen + Lips) für das aktuelle Theme
  TactilePalette get palette => _palette;

  /// Fläche und Lip für einen ColorType
  TactileTone getGameTone(ColorType type) => _palette.toneOf(type);

  /// Hintergrundfarbe
  Color get backgroundColor => _currentThemeColors.background;

  /// Primärfarbe
  Color get primaryColor => _currentThemeColors.primary;

  /// Sekundärfarbe
  Color get secondaryColor => _currentThemeColors.secondary;

  /// Akzentfarbe
  Color get accentColor => _currentThemeColors.accent;

  /// Oberflächenfarbe
  Color get surfaceColor => _currentThemeColors.surface;

  /// Primäre Textfarbe
  Color get textPrimaryColor => _currentThemeColors.textPrimary;

  /// Sekundäre Textfarbe
  Color get textSecondaryColor => _currentThemeColors.textSecondary;

  /// Holt die Farbe für einen bestimmten ColorType
  /// Verwendet Theme-Farben wenn vorhanden, sonst Standard-Farben
  Color getGameColor(ColorType type) => _palette.toneOf(type).face;

  /// Holt alle verfügbaren Spielfarben für das aktuelle Theme
  List<Color> getGameColors(int count) {
    final List<Color> colors = [];
    for (int i = 0; i < count && i < colorOptions.length; i++) {
      colors.add(getGameColor(colorOptions[i]));
    }
    return colors;
  }

  /// Setzt das aktuelle Theme
  void setTheme(CosmeticThemeType themeType) {
    if (_currentThemeType != themeType) {
      _currentThemeType = themeType;
      _currentThemeColors = CosmeticThemeColors.getTheme(themeType);
      _palette = TactilePalette.fromTheme(themeType, _currentThemeColors);
      notifyListeners();
    }
  }

  /// Aktualisiert das Theme basierend auf der Theme-ID aus CosmeticState
  void updateFromThemeId(String themeId) {
    final cosmetic = allCosmetics.firstWhere(
      (c) => c.id == themeId,
      orElse: () => allCosmetics.first,
    );
    final themeType = cosmetic.themeType ?? CosmeticThemeType.defaultTheme;
    setTheme(themeType);
  }
}
