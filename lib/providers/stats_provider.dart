import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';
import '../models/progress_models.dart';

/// Lifetime statistics of the player, plus the store rating request that
/// depends on them
class StatsProvider extends ChangeNotifier {
  static const _statsKey = 'player_stats';

  PlayerStats _stats = const PlayerStats();
  DateTime? _runStartedAt;
  bool _isLoaded = false;

  /// Clock, replaceable in tests
  DateTime Function() now = DateTime.now;

  PlayerStats get stats => _stats;
  bool get isLoaded => _isLoaded;

  StatsProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_statsKey);
      if (json != null) {
        _stats = PlayerStats.fromJson(jsonDecode(json) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Failed to load stats: $e');
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_statsKey, jsonEncode(_stats.toJson()));
    } catch (e) {
      debugPrint('Failed to save stats: $e');
    }
  }

  void _update(PlayerStats stats) {
    _stats = stats;
    _save();
    notifyListeners();
  }

  void recordRunStarted() {
    final t = now();
    _runStartedAt = t;
    _update(
      _stats.copyWith(
        gamesPlayed: _stats.gamesPlayed + 1,
        firstPlayed: _stats.firstPlayed ?? t,
      ),
    );
  }

  void recordLevelSolved(int gained, ScoreState score) {
    _update(
      _stats.copyWith(
        levelsSolved: _stats.levelsSolved + 1,
        // score.level already points at the next level
        highestLevel: max(_stats.highestLevel, score.level - 1),
        bestCombo: max(_stats.bestCombo, score.bestCombo),
        bestScore: max(_stats.bestScore, score.points),
        totalBlockPoints: _stats.totalBlockPoints + gained,
      ),
    );
  }

  void recordRunLost(ScoreState score) {
    final started = _runStartedAt;
    _runStartedAt = null;
    _update(
      _stats.copyWith(
        bestScore: max(_stats.bestScore, score.points),
        playSeconds: started == null
            ? _stats.playSeconds
            : _stats.playSeconds + now().difference(started).inSeconds,
      ),
    );
  }

  void recordHintUsed() {
    _update(_stats.copyWith(hintsUsed: _stats.hintsUsed + 1));
  }

  void recordLootboxOpened() {
    _update(_stats.copyWith(lootboxesOpened: _stats.lootboxesOpened + 1));
  }

  void recordMultiplayerMatch() {
    _update(
      _stats.copyWith(
        multiplayerMatches: _stats.multiplayerMatches + 1,
        firstPlayed: _stats.firstPlayed ?? now(),
      ),
    );
  }

  /// Asks for a store rating once the player has used the app for a while.
  /// The stores decide themselves whether the dialog really shows.
  Future<void> maybeRequestReview() async {
    final t = now();
    if (!_stats.shouldRequestReview(t)) return;
    _update(_stats.copyWith(lastReviewRequest: t));
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (e) {
      debugPrint('Review request failed: $e');
    }
  }
}
