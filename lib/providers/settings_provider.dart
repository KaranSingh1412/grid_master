import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';

/// Settings provider for brightness, audio, and mode progression
class SettingsProvider extends ChangeNotifier {
  GameSettings _settings = const GameSettings();
  ModeProgress _classicProgress = const ModeProgress();
  bool _isLoaded = false;

  GameSettings get settings => _settings;
  int get brightness => _settings.brightness;
  bool get musicEnabled => _settings.musicEnabled;
  bool get soundEnabled => _settings.soundEnabled;
  double get musicVolume => _settings.musicVolume;
  double get soundVolume => _settings.soundVolume;
  bool get isLoaded => _isLoaded;

  ModeProgress get classicProgress => _classicProgress;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load game settings
      final jsonString = prefs.getString('gameSettings');
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _settings = GameSettings.fromJson(json);
      }

      // Load classic mode progress
      final classicString = prefs.getString('classicProgress');
      if (classicString != null) {
        final json = jsonDecode(classicString) as Map<String, dynamic>;
        _classicProgress = ModeProgress.fromJson(json);
      }
    } catch (e) {
      // Use defaults on error
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gameSettings', jsonEncode(_settings.toJson()));
    } catch (e) {
      // Ignore save errors
    }
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'classicProgress',
        jsonEncode(_classicProgress.toJson()),
      );
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Update progress for a specific game mode
  void updateModeProgress(
    GameMode mode, {
    int? highScore,
    int? highestLevel,
    bool incrementGamesPlayed = false,
    bool incrementPerfectLevels = false,
  }) {
    ModeProgress current = _classicProgress;

    final updated = ModeProgress(
      highScore: highScore != null && highScore > current.highScore
          ? highScore
          : current.highScore,
      highestLevel: highestLevel != null && highestLevel > current.highestLevel
          ? highestLevel
          : current.highestLevel,
      totalGamesPlayed: incrementGamesPlayed
          ? current.totalGamesPlayed + 1
          : current.totalGamesPlayed,
      perfectLevels: incrementPerfectLevels
          ? current.perfectLevels + 1
          : current.perfectLevels,
    );
    _classicProgress = updated;

    _saveProgress();
    notifyListeners();
  }

  /// Get progress for a specific mode
  ModeProgress getProgress(GameMode mode) {
    return _classicProgress;
  }

  void setBrightness(int value) {
    _settings = _settings.copyWith(brightness: value.clamp(30, 150));
    _saveSettings();
    notifyListeners();
  }

  void setMusicEnabled(bool value) {
    _settings = _settings.copyWith(musicEnabled: value);
    _saveSettings();
    notifyListeners();
  }

  void setSoundEnabled(bool value) {
    _settings = _settings.copyWith(soundEnabled: value);
    _saveSettings();
    notifyListeners();
  }

  void setMusicVolume(double value) {
    _settings = _settings.copyWith(musicVolume: value.clamp(0.0, 1.0));
    _saveSettings();
    notifyListeners();
  }

  void setSoundVolume(double value) {
    _settings = _settings.copyWith(soundVolume: value.clamp(0.0, 1.0));
    _saveSettings();
    notifyListeners();
  }
}
