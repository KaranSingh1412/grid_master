import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';
import '../constants/game_constants.dart';
import 'audio_provider.dart';

/// Main game state provider with complete game logic
class GameProvider extends ChangeNotifier {
  GameState _gameState = GameState.start;
  GameState _lastActiveState = GameState.preview;
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
  // Ticks every 100 ms; kept apart from notifyListeners so only timer
  // widgets rebuild while the clock runs.
  final ValueNotifier<double> _timerNotifier = ValueNotifier<double>(0);
  final Random _random = Random();
  AudioProvider? _audioProvider;

  static const Duration solutionDuration = Duration(seconds: 2);

  /// Length of the lose animation on the board
  static const Duration collapseDuration = Duration(milliseconds: 1000);

  // Getters
  GameState get gameState => _gameState;
  GameState get lastActiveState => _lastActiveState;
  int get currentLevelIdx => _currentLevelIdx;
  LevelConfig get currentLevel => levels[_currentLevelIdx];
  ScoreState get score => _score;
  List<GridCell> get targetPattern => _targetPattern;
  List<GridCell> get userPattern => _userPattern;
  ColorType get selectedColor => _selectedColor;
  double get timer => _timer;

  /// Remaining time, updated on every tick without notifying the provider
  ValueListenable<double> get timerListenable => _timerNotifier;
  double get maxTimer => _maxTimer;
  int get hints => _hints;
  double get timerProgress => _maxTimer > 0 ? _timer / _maxTimer : 0;

  int get rebuildTimeLimit => currentLevel.gridSize > 3 ? 12 : 7;
  bool get hasDoubleBonus => _hasDoubleBonus;

  bool get isPreview => _gameState == GameState.preview;
  bool get isRebuild => _gameState == GameState.rebuild;
  bool get isPaused => _gameState == GameState.paused;
  bool get isGameOver => _gameState == GameState.gameOver;
  bool get isStart => _gameState == GameState.start;
  bool get isLevelUp => _gameState == GameState.levelUp;
  bool get isShowSolution => _gameState == GameState.showSolution;
  bool get isCollapse => _gameState == GameState.collapse;
  bool get hasUsedContinueThisRound => _hasUsedContinueThisRound;

  GameProvider() {
    _loadHighScore();
  }

  /// Set the audio provider for playing sounds
  void setAudioProvider(AudioProvider audioProvider) {
    _audioProvider = audioProvider;
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    final highScore = prefs.getInt('highScore') ?? 0;
    _score = _score.copyWith(highScore: highScore);
    notifyListeners();
  }

  Future<void> _saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', score);
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
    _setTimer(currentLevel.previewSeconds);
    _maxTimer = currentLevel.previewSeconds;
    _gameState = GameState.preview;
    _selectedColor = colorOptions[0];
    _startTimer();
    notifyListeners();
  }

  /// Start the game from the start screen
  void startGame() {
    _currentLevelIdx = 0;
    _score = ScoreState(highScore: _score.highScore);
    _hints = 3;
    _hasUsedContinueThisRound = false;
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

  void _setTimer(double value) {
    _timer = value;
    _timerNotifier.value = value;
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _setTimer((_timer - 0.1).clamp(0, double.infinity));

      if (_timer <= 0) {
        timer.cancel();
        _onTimerEnd();
      }
    });
  }

  void _onTimerEnd() {
    if (_gameState == GameState.preview) {
      // Switch to rebuild mode
      _gameState = GameState.rebuild;
      _setTimer(rebuildTimeLimit.toDouble());
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
    _audioProvider?.playLoseSound();
    notifyListeners();

    // Show solution for 2 seconds, let the board fall apart, then game over
    Future.delayed(solutionDuration, () {
      if (_gameState != GameState.showSolution) return;
      _gameState = GameState.collapse;
      notifyListeners();

      Future.delayed(collapseDuration, () {
        if (_gameState != GameState.collapse) return;
        _gameState = GameState.gameOver;
        notifyListeners();
      });
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
      );

      _gameState = GameState.levelUp;
      _audioProvider?.playWinSound();
      notifyListeners();

      // Auto-proceed to next level
      // 1200 ms leave room for the level-up celebration
      Future.delayed(const Duration(milliseconds: 1200), () {
        _handleNextLevel();
      });
    } else {
      // Wrong pattern - show solution first
      _showSolutionBeforeGameOver();
    }
  }

  void _handleNextLevel() {
    _currentLevelIdx = min(_currentLevelIdx + 1, levels.length - 1);
    startLevel();
  }

  /// Skip the preview phase
  void skipPreview() {
    if (_gameState == GameState.preview) {
      _gameTimer?.cancel();
      _setTimer(0);
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
    _score = ScoreState(highScore: _score.highScore);
    _hints = 3;
    _targetPattern = [];
    _gameState = GameState.start;
    notifyListeners();
  }

  /// Restart the game immediately
  void restart() {
    _gameTimer?.cancel();
    _currentLevelIdx = 0;
    _score = ScoreState(highScore: _score.highScore);
    _hints = 3;
    _hasUsedContinueThisRound = false;
    _targetPattern = [];
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
      _setTimer(currentLevel.previewSeconds);
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

  @override
  void dispose() {
    _gameTimer?.cancel();
    _timerNotifier.dispose();
    super.dispose();
  }
}
