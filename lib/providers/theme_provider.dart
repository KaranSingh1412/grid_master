import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../models/game_models.dart';

/// Zentraler Provider für das Theme-Management
/// Verwaltet das aktuelle Theme und stellt Farben für alle Widgets bereit
class ThemeProvider extends ChangeNotifier {
  CosmeticThemeType _currentThemeType = CosmeticThemeType.defaultTheme;
  CosmeticThemeColors _currentThemeColors = CosmeticThemeColors.defaultTheme;

  /// Das aktuelle Theme-Typ
  CosmeticThemeType get currentThemeType => _currentThemeType;

  /// Die aktuellen Theme-Farben
  CosmeticThemeColors get colors => _currentThemeColors;

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
  Color getGameColor(ColorType type) {
    if (type == ColorType.none) {
      return _currentThemeColors.surface.withValues(alpha: 0.2);
    }

    // Prüfen ob das Theme custom gameColors hat
    if (_currentThemeColors.gameColors.isNotEmpty) {
      final colorIndex = type.index;
      if (colorIndex < _currentThemeColors.gameColors.length) {
        return _currentThemeColors.gameColors[colorIndex];
      }
    }

    // Fallback zu Standard-Farben
    return GameColors.getColor(type);
  }

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

  /// Holt die Slate-Farben (UI-Farben, Theme-unabhängig für bestimmte UI-Elemente)
  static Color get slate50 => GameColors.slate50;
  static Color get slate100 => GameColors.slate100;
  static Color get slate200 => GameColors.slate200;
  static Color get slate300 => GameColors.slate300;
  static Color get slate400 => GameColors.slate400;
  static Color get slate500 => GameColors.slate500;
  static Color get slate600 => GameColors.slate600;
  static Color get slate700 => GameColors.slate700;
  static Color get slate800 => GameColors.slate800;
  static Color get slate900 => GameColors.slate900;
}
