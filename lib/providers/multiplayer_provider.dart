import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../constants/game_constants.dart';
import '../models/game_models.dart';

/// Phases of a two player round
enum MultiplayerPhase { idle, preview, rebuild, roundResult, matchOver }

/// Two players on one device share a 4x4 board. The top two rows belong to
/// player 0 (sitting opposite), the bottom two rows to player 1. Both memorize
/// their half, then race to rebuild it; the first correct half wins the round.
class MultiplayerProvider extends ChangeNotifier {
  MultiplayerProvider({Random? random}) : _random = random ?? Random();

  static const int gridSize = 4;
  static const int cellsPerHalf = gridSize * gridSize ~/ 2;
  static const int winningScore = 5;
  static const double rebuildSeconds = 10;
  static const Duration resultDuration = Duration(milliseconds: 2200);

  final Random _random;
  MultiplayerPhase _phase = MultiplayerPhase.idle;
  List<ColorType> _target = List.filled(gridSize * gridSize, ColorType.none);
  List<ColorType> _user = List.filled(gridSize * gridSize, ColorType.none);
  final List<ColorType> _selected = [colorOptions[0], colorOptions[0]];
  final List<int> _scores = [0, 0];
  int _round = 0;
  int? _roundWinner;
  double _timer = 0;
  double _maxTimer = 1;
  Timer? _tick;
  Timer? _next;
  final ValueNotifier<double> _timerNotifier = ValueNotifier<double>(0);

  /// Called once when a match has a winner
  VoidCallback? onMatchFinished;

  MultiplayerPhase get phase => _phase;
  List<ColorType> get target => _target;
  List<ColorType> get user => _user;
  List<int> get scores => List.unmodifiable(_scores);
  int get round => _round;

  /// Winner of the round just played, null while playing or on a timeout
  int? get roundWinner => _roundWinner;

  /// Winner of the match once it is over
  int? get matchWinner {
    if (_phase != MultiplayerPhase.matchOver) return null;
    return _scores[0] >= winningScore ? 0 : 1;
  }

  ValueListenable<double> get timerListenable => _timerNotifier;
  double get maxTimer => _maxTimer;

  ColorType selectedColor(int player) => _selected[player];

  /// Owner of a board cell: 0 for the top half, 1 for the bottom half
  static int ownerOf(int index) => index < cellsPerHalf ? 0 : 1;

  /// Pattern cells per half; grows every second round
  int get filledPerHalf => min(3 + (_round - 1) ~/ 2, 7);

  /// Colors in play; one more every third round
  int get colorCount => min(3 + (_round - 1) ~/ 3, 5);

  List<ColorType> get availableColors => colorOptions.take(colorCount).toList();

  double get previewSeconds => max(2.5, 4.5 - 0.25 * (_round - 1));

  /// Whether a player's half matches the target
  bool isHalfSolved(int player) {
    final start = player * cellsPerHalf;
    for (int i = start; i < start + cellsPerHalf; i++) {
      if (_target[i] != _user[i]) return false;
    }
    return true;
  }

  void startMatch() {
    _scores[0] = 0;
    _scores[1] = 0;
    _round = 0;
    _startRound();
  }

  void _startRound() {
    _next?.cancel();
    _round++;
    _roundWinner = null;
    _target = List.filled(gridSize * gridSize, ColorType.none);
    _user = List.filled(gridSize * gridSize, ColorType.none);
    final colors = availableColors;
    for (int player = 0; player < 2; player++) {
      final cells = List.generate(
        cellsPerHalf,
        (i) => player * cellsPerHalf + i,
      )..shuffle(_random);
      for (final idx in cells.take(filledPerHalf)) {
        _target[idx] = colors[_random.nextInt(colors.length)];
      }
      _selected[player] = colors.first;
    }
    _phase = MultiplayerPhase.preview;
    _runTimer(previewSeconds);
    notifyListeners();
  }

  void _runTimer(double seconds) {
    _tick?.cancel();
    _maxTimer = seconds;
    _setTimer(seconds);
    _tick = Timer.periodic(const Duration(milliseconds: 100), (t) {
      _setTimer(max(0, _timer - 0.1));
      if (_timer <= 0) {
        t.cancel();
        _onTimerEnd();
      }
    });
  }

  void _setTimer(double value) {
    _timer = value;
    _timerNotifier.value = value;
  }

  void _onTimerEnd() {
    if (_phase == MultiplayerPhase.preview) {
      _phase = MultiplayerPhase.rebuild;
      _runTimer(rebuildSeconds);
      notifyListeners();
    } else if (_phase == MultiplayerPhase.rebuild) {
      _endRound();
    }
  }

  void selectColor(int player, ColorType color) {
    _selected[player] = color;
    notifyListeners();
  }

  /// A tap of [player] on board cell [index]; cells of the other half and
  /// taps outside the rebuild phase are ignored
  void onCellTap(int player, int index) {
    if (_phase != MultiplayerPhase.rebuild) return;
    if (ownerOf(index) != player) return;
    final color = _selected[player];
    _user[index] = _user[index] == color ? ColorType.none : color;
    if (isHalfSolved(player)) {
      _roundWinner = player;
      _scores[player]++;
      _endRound();
      return;
    }
    notifyListeners();
  }

  void _endRound() {
    _tick?.cancel();
    _setTimer(0);
    if (_scores.any((s) => s >= winningScore)) {
      _phase = MultiplayerPhase.matchOver;
      onMatchFinished?.call();
      notifyListeners();
      return;
    }
    _phase = MultiplayerPhase.roundResult;
    notifyListeners();
    _next = Timer(resultDuration, _startRound);
  }

  /// Stop everything, e.g. when leaving the screen
  void leave() {
    _tick?.cancel();
    _next?.cancel();
    _phase = MultiplayerPhase.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _next?.cancel();
    _timerNotifier.dispose();
    super.dispose();
  }
}
