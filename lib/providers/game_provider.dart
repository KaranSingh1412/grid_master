import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';
import '../constants/game_constants.dart';
import 'audio_provider.dart';
import 'settings_provider.dart';
import 'credit_provider.dart';

/// Main game state provider with complete game logic
class GameProvider extends ChangeNotifier {
  GameState _gameState = GameState.start;
  GameState _lastActiveState = GameState.preview;
  GameMode _currentMode = GameMode.classic;
  int _currentLevelIdx = 0;
  ScoreState _score = const ScoreState();
  List<GridCell> _targetPattern = [];
  List<GridCell> _userPattern = [];
  ColorType _selectedColor = ColorType.red;
  double _timer = 0;
  double _maxTimer = 1;
  int _hints = 3;
  bool _hasUsedContinueThisRound = false;
  bool _hasDoubleBonus = false;
  Timer? _gameTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();
  AudioProvider? _audioProvider;
  SettingsProvider? _settingsProvider;
  CreditProvider? _creditProvider;

  // Getters
  GameState get gameState => _gameState;
  GameState get lastActiveState => _lastActiveState;
  GameMode get currentMode => _currentMode;
  int get currentLevelIdx => _currentLevelIdx;

  /// Get levels for current mode
  List<LevelConfig> get currentLevels => getLevelsForMode(_currentMode);
  LevelConfig get currentLevel => currentLevels[_currentLevelIdx];

  ScoreState get score => _score;
  List<GridCell> get targetPattern => _targetPattern;
  List<GridCell> get userPattern => _userPattern;
  ColorType get selectedColor => _selectedColor;
  double get timer => _timer;
  double get maxTimer => _maxTimer;
  int get hints => _hints;
  double get timerProgress => _maxTimer > 0 ? _timer / _maxTimer : 0;

  /// Rebuild time limit - Color Zen mode gives more time
  int get rebuildTimeLimit {
    if (_currentMode == GameMode.colorZen) {
      return currentLevel.gridSize > 4 ? 18 : 12; // More time for zen mode
    }
    return currentLevel.gridSize > 3 ? 12 : 7;
  }

  bool get hasDoubleBonus => _hasDoubleBonus;
  bool get isColorZenMode => _currentMode == GameMode.colorZen;

  bool get isPreview => _gameState == GameState.preview;
  bool get isRebuild => _gameState == GameState.rebuild;
  bool get isPaused => _gameState == GameState.paused;
  bool get isGameOver => _gameState == GameState.gameOver;
  bool get isStart => _gameState == GameState.start;
  bool get isLevelUp => _gameState == GameState.levelUp;
  bool get isShowSolution => _gameState == GameState.showSolution;
  bool get hasUsedContinueThisRound => _hasUsedContinueThisRound;

  GameProvider() {
    _loadHighScore();
  }

  /// Set the audio provider for playing sounds
  void setAudioProvider(AudioProvider audioProvider) {
    _audioProvider = audioProvider;
  }

  /// Set the settings provider for progress tracking
  void setSettingsProvider(SettingsProvider settingsProvider) {
    _settingsProvider = settingsProvider;
  }

  /// Set the credit provider for cosmetic rewards
  void setCreditProvider(CreditProvider creditProvider) {
    _creditProvider = creditProvider;
  }

  /// Set the current game mode
  void setGameMode(GameMode mode) {
    _currentMode = mode;
    _loadHighScore();
    notifyListeners();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    // Load mode-specific high score
    final key = _currentMode == GameMode.colorZen
        ? 'colorZenHighScore'
        : 'highScore';
    final highScore = prefs.getInt(key) ?? 0;
    _score = _score.copyWith(highScore: highScore, gameMode: _currentMode);
    notifyListeners();
  }

  Future<void> _saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _currentMode == GameMode.colorZen
        ? 'colorZenHighScore'
        : 'highScore';
    await prefs.setInt(key, score);

    // Also update settings provider progress
    _settingsProvider?.updateModeProgress(_currentMode, highScore: score);
  }

  /// Generate a random pattern for the current level
  void _generatePattern() {
    final totalCells = currentLevel.gridSize * currentLevel.gridSize;
    _targetPattern = List.generate(
      totalCells,
      (i) => GridCell(id: i, color: ColorType.none),
    );

    // Get random indices to fill
    final indices = List.generate(totalCells, (i) => i);
    indices.shuffle(_random);
    final selectedIndices = indices.take(currentLevel.patternSize).toList();

    // Get available colors for this level
    final availableColors = colorOptions.take(currentLevel.colorCount).toList();

    // Fill selected cells with random colors
    for (final idx in selectedIndices) {
      _targetPattern[idx] = GridCell(
        id: idx,
        color: availableColors[_random.nextInt(availableColors.length)],
      );
    }

    // Initialize empty user pattern
    _userPattern = List.generate(
      totalCells,
      (i) => GridCell(id: i, color: ColorType.none),
    );
  }

  /// Start a new level
  void startLevel() {
    _generatePattern();
    _timer = currentLevel.previewSeconds;
    _maxTimer = currentLevel.previewSeconds;
    _gameState = GameState.preview;
    _selectedColor = colorOptions[0];
    _startTimer();
    notifyListeners();
  }

  /// Start the game from the start screen
  void startGame() {
    _currentLevelIdx = 0;
    _score = ScoreState(highScore: _score.highScore, gameMode: _currentMode);
    _hints = _currentMode == GameMode.colorZen
        ? 5
        : 3; // More hints in Zen mode
    _hasUsedContinueThisRound = false;

    // Update games played count
    _settingsProvider?.updateModeProgress(
      _currentMode,
      incrementGamesPlayed: true,
    );

    startLevel();
  }

  /// Activate double bonus for the current game session
  void activateDoubleBonus() {
    _hasDoubleBonus = true;
    notifyListeners();
  }

  /// Deactivate double bonus (called internally after game over)
  void _deactivateDoubleBonus() {
    _hasDoubleBonus = false;
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _timer = (_timer - 0.1).clamp(0, double.infinity);

      if (_timer <= 0) {
        timer.cancel();
        _onTimerEnd();
      }

      notifyListeners();
    });
  }

  void _onTimerEnd() {
    if (_gameState == GameState.preview) {
      // Switch to rebuild mode
      _gameState = GameState.rebuild;
      _timer = rebuildTimeLimit.toDouble();
      _maxTimer = rebuildTimeLimit.toDouble();
      _startTimer();
    } else if (_gameState == GameState.rebuild) {
      // Time ran out - show solution first, then game over
      _showSolutionBeforeGameOver();
    }
    notifyListeners();
  }

  void _showSolutionBeforeGameOver() {
    _gameState = GameState.showSolution;
    _deactivateDoubleBonus();
    _playFailSound();
    notifyListeners();

    // Show solution for 2 seconds, then show game over
    Future.delayed(const Duration(seconds: 2), () {
      _gameState = GameState.gameOver;
      notifyListeners();
    });
  }

  /// Handle cell tap in rebuild mode
  void onCellTap(int idx) {
    if (_gameState != GameState.rebuild) return;

    final prevColor = _userPattern[idx].color;
    _userPattern[idx] = GridCell(
      id: idx,
      color: prevColor == _selectedColor ? ColorType.none : _selectedColor,
    );

    notifyListeners();

    // Auto-check if pattern matches
    if (_isPerfectMatch()) {
      _validatePattern();
    }
  }

  bool _isPerfectMatch() {
    for (int i = 0; i < _targetPattern.length; i++) {
      if (_targetPattern[i].color != _userPattern[i].color) {
        return false;
      }
    }
    return true;
  }

  /// Validate the user's pattern
  void validatePattern() {
    _validatePattern();
  }

  void _validatePattern() {
    _gameTimer?.cancel();

    if (_isPerfectMatch()) {
      // Calculate points
      final difficultyMultiplier =
          (currentLevel.gridSize * currentLevel.colorCount) / 10;
      final speedBonus = (_timer * 20).round();
      int pointsGain =
          ((currentLevel.patternSize * 20 + 100 + speedBonus) *
                  difficultyMultiplier)
              .round();

      // Apply double bonus if active
      if (_hasDoubleBonus) {
        pointsGain *= 2;
      }

      int newPoints = _score.points + pointsGain;
      int newCombo = _score.combo + 1;
      int newBestCombo = max(_score.bestCombo, newCombo);
      int newHighScore = max(_score.highScore, newPoints);

      if (newHighScore > _score.highScore) {
        _saveHighScore(newHighScore);
      }

      _score = ScoreState(
        points: newPoints,
        combo: newCombo,
        bestCombo: newBestCombo,
        level: currentLevel.id + 1,
        highScore: newHighScore,
        gameMode: _currentMode,
      );

      _gameState = GameState.levelUp;
      _audioProvider?.playWinSound();

      // Award credits (replaces cosmetic credits - now uses regular coins)
      _creditProvider?.checkAndAwardCredits(newPoints);

      // Update highest level in progress
      _settingsProvider?.updateModeProgress(
        _currentMode,
        highestLevel: currentLevel.id + 1,
        incrementPerfectLevels: true,
      );

      notifyListeners();

      // Auto-proceed to next level
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNextLevel();
      });
    } else {
      // Wrong pattern - show solution first
      _showSolutionBeforeGameOver();
    }
  }

  void _handleNextLevel() {
    _currentLevelIdx = min(_currentLevelIdx + 1, currentLevels.length - 1);
    startLevel();
  }

  /// Skip the preview phase
  void skipPreview() {
    if (_gameState == GameState.preview) {
      _gameTimer?.cancel();
      _timer = 0;
      _onTimerEnd();
    }
  }

  /// Toggle pause state
  void togglePause() {
    if (_gameState == GameState.preview || _gameState == GameState.rebuild) {
      _lastActiveState = _gameState;
      _gameState = GameState.paused;
      _gameTimer?.cancel();
    } else if (_gameState == GameState.paused) {
      _gameState = _lastActiveState;
      _startTimer();
    }
    notifyListeners();
  }

  /// Resume from pause
  void resume() {
    if (_gameState == GameState.paused) {
      _gameState = _lastActiveState;
      _startTimer();
      notifyListeners();
    }
  }

  /// Use a hint
  void useHint() {
    if (_hints <= 0 || _gameState != GameState.rebuild) return;

    // First, remove any incorrectly placed cells
    for (int i = 0; i < _targetPattern.length; i++) {
      // If user placed a color where there should be none, remove it
      if (_targetPattern[i].color == ColorType.none &&
          _userPattern[i].color != ColorType.none) {
        _userPattern[i] = GridCell(id: i, color: ColorType.none);
      }
      // If user placed wrong color where a different color should be, remove it
      else if (_targetPattern[i].color != ColorType.none &&
          _userPattern[i].color != ColorType.none &&
          _targetPattern[i].color != _userPattern[i].color) {
        _userPattern[i] = GridCell(id: i, color: ColorType.none);
      }
    }

    // Then, find cells that need to be filled
    final wrongIndices = <int>[];
    for (int i = 0; i < _targetPattern.length; i++) {
      if (_targetPattern[i].color != _userPattern[i].color &&
          _targetPattern[i].color != ColorType.none) {
        wrongIndices.add(i);
      }
    }

    if (wrongIndices.isNotEmpty) {
      final randomIdx = wrongIndices[_random.nextInt(wrongIndices.length)];
      _userPattern[randomIdx] = GridCell(
        id: randomIdx,
        color: _targetPattern[randomIdx].color,
      );
    }

    _hints--;
    notifyListeners();

    // Check if pattern is now complete
    if (_isPerfectMatch()) {
      _validatePattern();
    }
  }

  /// Use a paid hint (costs 5 coins)
  /// Returns true if hint was used, false if not enough credits or no hints available
  bool usePaidHint(dynamic creditProvider) {
    if (_gameState != GameState.rebuild) return false;

    // First, remove any incorrectly placed cells
    for (int i = 0; i < _targetPattern.length; i++) {
      // If user placed a color where there should be none, remove it
      if (_targetPattern[i].color == ColorType.none &&
          _userPattern[i].color != ColorType.none) {
        _userPattern[i] = GridCell(id: i, color: ColorType.none);
      }
      // If user placed wrong color where a different color should be, remove it
      else if (_targetPattern[i].color != ColorType.none &&
          _userPattern[i].color != ColorType.none &&
          _targetPattern[i].color != _userPattern[i].color) {
        _userPattern[i] = GridCell(id: i, color: ColorType.none);
      }
    }

    // Find cells that need to be filled
    final wrongIndices = <int>[];
    for (int i = 0; i < _targetPattern.length; i++) {
      if (_targetPattern[i].color != _userPattern[i].color &&
          _targetPattern[i].color != ColorType.none) {
        wrongIndices.add(i);
      }
    }

    if (wrongIndices.isEmpty) return false;

    // Try to spend 5 credits (with daily limit check)
    if (!creditProvider.spendCreditsForHint(5)) return false;

    // Apply the hint
    final randomIdx = wrongIndices[_random.nextInt(wrongIndices.length)];
    _userPattern[randomIdx] = GridCell(
      id: randomIdx,
      color: _targetPattern[randomIdx].color,
    );
    notifyListeners();

    // Check if pattern is now complete
    if (_isPerfectMatch()) {
      _validatePattern();
    }

    return true;
  }

  /// Select a color from the palette
  void selectColor(ColorType color) {
    _selectedColor = color;
    notifyListeners();
  }

  /// Go back to home/start screen
  void goToHome() {
    _gameTimer?.cancel();
    _currentLevelIdx = 0;
    _score = ScoreState(highScore: _score.highScore, gameMode: _currentMode);
    _hints = _currentMode == GameMode.colorZen ? 5 : 3;
    _targetPattern = [];
    _gameState = GameState.start;
    notifyListeners();
  }

  /// Restart the game immediately
  void restart() {
    _gameTimer?.cancel();
    _currentLevelIdx = 0;
    _score = ScoreState(highScore: _score.highScore, gameMode: _currentMode);
    _hints = _currentMode == GameMode.colorZen ? 5 : 3;
    _hasUsedContinueThisRound = false;
    _targetPattern = [];

    // Update games played count
    _settingsProvider?.updateModeProgress(
      _currentMode,
      incrementGamesPlayed: true,
    );

    startLevel();
  }

  /// Continue playing after watching a rewarded ad
  void continueAfterAd() {
    if (_gameState == GameState.gameOver) {
      // Mark that continue was used this round
      _hasUsedContinueThisRound = true;

      // Reset user pattern
      final totalCells = currentLevel.gridSize * currentLevel.gridSize;
      _userPattern = List.generate(
        totalCells,
        (i) => GridCell(id: i, color: ColorType.none),
      );

      // Show pattern again in preview mode first
      _timer = currentLevel.previewSeconds;
      _maxTimer = currentLevel.previewSeconds;
      _gameState = GameState.preview;
      _startTimer();
      notifyListeners();
    }
  }

  /// Get paused grid cells (empty cells for display during pause)
  List<GridCell> get pausedCells {
    final totalCells = currentLevel.gridSize * currentLevel.gridSize;
    return List.generate(
      totalCells,
      (i) => GridCell(id: -i - 1, color: ColorType.none),
    );
  }

  Future<void> _playFailSound() async {
    // Don't play sound if audio provider is not set or sound volume is 0
    if (_audioProvider == null) return;

    try {
      // Only play if sound is enabled (volume > 0)
      if (!_audioProvider!.isSoundEnabled) return;

      await _audioPlayer.setVolume(0.15);
      await _audioPlayer.play(AssetSource('audio/glass.mp3'));
    } catch (e) {
      // Ignore audio errors
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
