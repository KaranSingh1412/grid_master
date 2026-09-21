import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks for a store rating exactly once, after the player has spent some time
/// with the game. Uses the native App Store / Play Store review dialog.
class ReviewService {
  ReviewService._();

  /// Finished rounds before the rating request may show
  static const int minRoundsPlayed = 5;

  /// Time since the first finished round before the rating request may show
  static const Duration minTimeSinceFirstRound = Duration(days: 1);

  static const String _roundsKey = 'reviewRoundsPlayed';
  static const String _firstRoundKey = 'reviewFirstRoundAt';
  static const String _requestedKey = 'reviewRequested';

  // The request only follows a round of this session, never a cold start
  static bool _roundFinishedThisSession = false;

  /// Count a finished round
  static Future<void> recordRoundFinished({DateTime? now}) async {
    _roundFinishedThisSession = true;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_requestedKey) ?? false) return;

    await prefs.setInt(_roundsKey, (prefs.getInt(_roundsKey) ?? 0) + 1);
    if (!prefs.containsKey(_firstRoundKey)) {
      await prefs.setInt(
        _firstRoundKey,
        (now ?? DateTime.now()).millisecondsSinceEpoch,
      );
    }
  }

  /// Whether the player has played enough and was never asked before
  static Future<bool> isDue({DateTime? now}) async {
    if (!_roundFinishedThisSession) return false;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_requestedKey) ?? false) return false;
    if ((prefs.getInt(_roundsKey) ?? 0) < minRoundsPlayed) return false;

    final firstRoundAt = prefs.getInt(_firstRoundKey);
    if (firstRoundAt == null) return false;
    final elapsed = (now ?? DateTime.now()).difference(
      DateTime.fromMillisecondsSinceEpoch(firstRoundAt),
    );
    return elapsed >= minTimeSinceFirstRound;
  }

  /// Show the native rating dialog if it is due. Never shows a second time.
  static Future<void> maybeRequestReview() async {
    try {
      if (!await isDue()) return;
      final inAppReview = InAppReview.instance;
      if (!await inAppReview.isAvailable()) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_requestedKey, true);
      await inAppReview.requestReview();
    } catch (e) {
      debugPrint('Review request failed: $e');
    }
  }

  @visibleForTesting
  static void resetSession() => _roundFinishedThisSession = false;
}
